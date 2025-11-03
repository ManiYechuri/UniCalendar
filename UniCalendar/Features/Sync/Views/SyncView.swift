import SwiftUI

struct SyncView: View {
    // Connected accounts from Core Data
    @State private var accounts: [SyncAccount] = []

    // Overlays
    @State private var showAddSheet = false
    @State private var showDisconnect = false
    @State private var accountPendingDisconnect: SyncAccount?

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
            listContent
            addAccountOverlay
            disconnectOverlay
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            loadAccounts()
            SyncManager.shared.refreshAllAccounts()
        }
        .onReceive(NotificationCenter.default
            .publisher(for: .accountsDidChange)
            .receive(on: RunLoop.main)
        ) { _ in
            loadAccounts()
            SyncManager.shared.refreshAllAccounts()
        }
    }
}

// MARK: - UI Layers

private extension SyncView {
    var backgroundLayer: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    var listContent: some View {
        List {
            Section {
                if accounts.isEmpty {
                    emptyStateRow
                } else {
                    ForEach(accounts) { account in
                        AccountRowCell(account: account)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                // ✅ Only Disconnect
                                Button(role: .destructive) {
                                    accountPendingDisconnect = account
                                    showDisconnect = true
                                } label: {
                                    Label("Disconnect", systemImage: "link.badge.minus")
                                }
                            }
                    }
                }
            } header: {
                Text("CONNECTED ACCOUNTS")
                    .textCase(.uppercase)
                    .font(Typography.f14SemiBold)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            // Keep pull-to-refresh for a full resync of all accounts
            SyncManager.shared.refreshAllAccounts()
        }
    }

    var emptyStateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No accounts connected").font(.headline)
            Text("Tap + to connect Google or Outlook and start syncing your calendars.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // Centered title + trailing plus
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Sync")
                .font(Typography.f18Bold)
                .foregroundStyle(.primary)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Add account")
        }
    }

    // MARK: Add Account Overlay (no setup screens)
    var addAccountOverlay: some View {
        Group {
            if showAddSheet {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { showAddSheet = false }
                    .transition(.opacity)

                VStack {
                    Spacer()
                    AddAccountPopupView(
                        onClose: { showAddSheet = false },
                        onConnectGoogle: {
                            showAddSheet = false
                            startGoogleConnect()
                        },
                        onConnectOutlook: {
                            showAddSheet = false
                            startOutlookConnect()
                        }
                    )
                    .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showAddSheet)
    }

    // MARK: Disconnect Overlay
    var disconnectOverlay: some View {
        Group {
            if showDisconnect {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { dismissDisconnect() }

                CenterAlertView(
                    title: "Disconnect Account?",
                    message: "Are you sure you want to disconnect this account? All associated calendar events will be removed from UniCal.",
                    cancelTitle: "Cancel",
                    destructiveTitle: "Disconnect",
                    onCancel: { dismissDisconnect() },
                    onDestructive: { confirmDisconnect() }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDisconnect)
    }
}

// MARK: - Actions / Data

private extension SyncView {
    func loadAccounts() {
        let entities = AccountStorage.shared.connectedAccounts()
        accounts = entities.map(SyncAccount.init(entity:))
    }

    func startGoogleConnect() {
        guard let presenter = UIApplication.shared.topViewController else {
            print("No presenter for Google sign-in"); return
        }
        Task {
            do {
                let user = try await GoogleAuthAdapter().signIn(presenting: presenter)
                AccountStorage.shared.upsertAccount(
                    email: user.email,
                    provider: "google",
                    displayName: user.email
                )
                NotificationCenter.default.post(name: .accountsDidChange, object: nil)
                SyncManager.shared.refreshAllAccounts()
            } catch {
                print("Google connect failed:", error.localizedDescription)
            }
        }
    }

    func startOutlookConnect() {
        // TODO: implement Outlook flow (token + upsert + refreshAllAccounts)
        print("Outlook OAuth…")
    }

    func dismissDisconnect() {
        showDisconnect = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            accountPendingDisconnect = nil
        }
    }

    func confirmDisconnect() {
        guard let toRemove = accountPendingDisconnect else { return }

        AccountStorage.shared.markDisconnected(email: toRemove.email)
        EventStorage.shared.deleteAll(forAccountEmail: toRemove.email)
        GoogleAccountStore.shared.removeSyncToken(for: toRemove.email)

        loadAccounts()
        dismissDisconnect()

        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)

        // Optional: refresh remaining accounts to reconcile UI
        SyncManager.shared.refreshAllAccounts()
    }
}

// MARK: - Row

private struct AccountRowCell: View {
    let account: SyncAccount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.provider == .google ? "g.circle.fill" : "o.circle.fill")
                .font(.title2)
                .foregroundStyle(account.provider == .google ? .red : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.email)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(account.provider == .google ? "Google" : "Outlook")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(statusText)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
    }

    private var statusText: String {
        switch account.status {
        case .connected: return "Connected"
        case .syncing:   return "Syncing"
        case .error:     return "Error"
        }
    }

    private var statusColor: Color {
        switch account.status {
        case .connected: return .green
        case .syncing:   return .orange
        case .error:     return .red
        }
    }
}

// MARK: - Mapping helper

extension SyncAccount {
    init(entity e: AccountEntity) {
        let provider: CalendarProvider = {
            switch (e.provider ?? "").lowercased() {
            case "outlook": return .outlook
            case "google":  return .google
            default:        return .google
            }
        }()

        let status: SyncStatus = {
            let s = (e.status ?? "").lowercased()
            if s == "error"     { return .error }
            if s == "syncing"   { return .syncing }
            if s == "connected" { return .connected }
            return (e.isConnected == true) ? .connected : .error
        }()

        self.init(
            email: (e.email ?? "").lowercased(),
            provider: provider,
            status: status
        )
    }
}


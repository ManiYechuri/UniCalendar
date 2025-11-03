import SwiftUI

struct SyncView: View {
    @State private var accounts: [SyncAccount] = []

    @State private var showAddSheet = false
    @State private var showDisconnect = false
    @State private var accountPendingDisconnect: SyncAccount?

    @State private var showLimitAlert = false

    private let MAX_ACCOUNTS = 4

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
        .alert("Limit reached", isPresented: $showLimitAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text("You cannot connect more than 4 accounts.")
        })
    }
}

// MARK: - UI Layers

private extension SyncView {
    var backgroundLayer: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    var listContent: some View {
        List {
            if accounts.isEmpty {
                Section {
                    emptyStateRow
                }
            } else {
                Section {
                    ForEach(accounts) { account in
                        AccountRowCell(account: account)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    accountPendingDisconnect = account
                                    showDisconnect = true
                                } label: {
                                    Label("Disconnect", systemImage: "link.badge.minus")
                                }
                            }
                    }
                } header: {
                    Text(headerTitle(for: accounts.count))
                        .textCase(.none)
                        .font(Typography.f14SemiBold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            SyncManager.shared.refreshAllAccounts()
        }
    }

    func headerTitle(for count: Int) -> String {
        if count <= 0 { return "" }
        if count == 1 { return "Connected account" }
        return "Connected Accounts"
    }

    var emptyStateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No accounts connected").font(Typography.h1)
            Text("Please click on the + button at the top to connect your Google account.")
                .font(Typography.subheadline)
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
                if accounts.count >= MAX_ACCOUNTS {
                    // Show limit message instead of opening the add popup
                    showLimitAlert = true
                } else {
                    showAddSheet = true
                }
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

    // MARK: Disconnect Overlay (shows email)
    var disconnectOverlay: some View {
        Group {
            if showDisconnect {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { dismissDisconnect() }

                CenterAlertView(
                    title: "Disconnect Account?",
                    message: disconnectMessage(), // includes the email
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

    func disconnectMessage() -> String {
        let email = accountPendingDisconnect?.email ?? "this account"
        return """
        You are about to disconnect \(email).
        All associated calendar events and sync data for this account will be removed from UniCal.
        """
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

                // Prevent over-limit just in case (race with alert)
                guard accounts.count < MAX_ACCOUNTS else {
                    showLimitAlert = true
                    return
                }

                AccountStorage.shared.upsertAccount(
                    email: user.email,
                    provider: "google",
                    displayName: user.email
                )
                NotificationCenter.default.post(name: .accountsDidChange, object: nil)

                // Kick a full sync pass (backfill or delta based on token)
                SyncManager.shared.refreshAllAccounts()
            } catch {
                print("Google connect failed:", error.localizedDescription)
            }
        }
    }

    func startOutlookConnect() {
        // Optional: implement Outlook later
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

        // Remove account and all its data
        AccountStorage.shared.markDisconnected(email: toRemove.email)
        EventStorage.shared.deleteAll(forAccountEmail: toRemove.email)
        GoogleAccountStore.shared.removeSyncToken(for: toRemove.email)

        // Refresh UI state
        loadAccounts()
        dismissDisconnect()

        // Broadcast changes so other screens update
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)

        // Optional: refresh remaining accounts so Calendar view reconciles
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
                    .font(Typography.f14SemiBold)
                    .foregroundColor(.primary)

                Text(account.provider == .google ? "Google" : "Outlook")
                    .font(Typography.f12Regular)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(statusText)
                .font(Typography.footer)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .frame(height: 50)
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


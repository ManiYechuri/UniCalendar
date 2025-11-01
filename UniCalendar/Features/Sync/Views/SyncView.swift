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
            scrollContent
            addAccountOverlay
            disconnectOverlay
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }

        // Keep the list live
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

private extension SyncView {
    // MARK: UI Layers

    var backgroundLayer: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader
                if accounts.isEmpty { emptyStateCard } else { accountsCard }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable { SyncManager.shared.refreshAllAccounts() }
    }

    var sectionHeader: some View {
        Text("CONNECTED ACCOUNTS")
            .font(Typography.f14SemiBold)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
    }

    var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No accounts connected").font(.headline)
            Text("Tap + to connect Google or Outlook and start syncing your calendars.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    var accountsCard: some View {
        VStack(spacing: 0) {
            ForEach(accounts) { account in
                AccountRowView(account: account)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .onRightSwipe {
                        accountPendingDisconnect = account
                        showDisconnect = true
                    }

                Divider().padding(.leading, 72)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    // Centered title + trailing plus
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Sync")
                .font(Typography.f14SemiBold) // your custom font
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

                VStack { Spacer()
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

    // MARK: Actions / Data

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
                // Sign in (can be 1st or additional Google account)
                let user = try await GoogleAuthAdapter().signIn(presenting: presenter)

                // Store/Update account row (separate row per email)
                AccountStorage.shared.upsertAccount(email: user.email, provider: "google", displayName: user.email)
                NotificationCenter.default.post(name: .accountsDidChange, object: nil)

                // Kick a full sync pass (backfill or delta based on token)
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

        // Optional: refresh remaining accounts so Calendar view reconciles
        SyncManager.shared.refreshAllAccounts()
    }
}

extension SyncAccount {
    init(entity e: AccountEntity) {
        // provider
        let provider: CalendarProvider = {
            switch (e.provider ?? "").lowercased() {
            case "outlook": return .outlook
            case "google":  return .google
            default:        return .google
            }
        }()

        // status (prefer explicit status, fall back to isConnected)
        let status: SyncStatus = {
            let s = (e.status ?? "").lowercased()
            if s == "error"    { return .error }
            if s == "syncing"  { return .syncing }
            if s == "connected"{ return .connected }
            return (e.isConnected == true) ? .connected : .error
        }()

        self.init(
            email: (e.email ?? "").lowercased(),
            provider: provider,
            status: status
        )
    }
}



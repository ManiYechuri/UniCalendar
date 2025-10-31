import SwiftUI

struct SyncView: View {
    // MARK: - State
    @State private var accounts: [SyncAccount] = []

    var onAddAccount: (() -> Void)? = nil
    @State private var showAddSheet = false
    @State private var showGoogleSetup = false
    @State private var showOutlookSetup = false
    @State private var showDisconnect = false
    @State private var accountPendingDisconnect: SyncAccount?

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
            scrollContent
            addAccountOverlay
            disconnectOverlay
        }
        .navigationTitle("Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingPlus }

        .sheet(isPresented: $showGoogleSetup) {
            ConnectGoogleSetupView(
                onContinue: {
                    showGoogleSetup = false
                    startGoogleConnect()
                },
                onCancel: { showGoogleSetup = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOutlookSetup) {
            ConnectOutlookSetupView(
                onContinue: {
                    showOutlookSetup = false
                    startOutlookConnect()
                },
                onCancel: { showOutlookSetup = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }

        .animation(.easeInOut(duration: 0.2), value: showAddSheet)
        .animation(.easeInOut(duration: 0.2), value: showDisconnect)

        // Load & auto-refresh from storage
        .onAppear(perform: loadAccounts)
        .onReceive(NotificationCenter.default.publisher(for: .accountsDidChange)) { _ in
            loadAccounts()
        }
    }
}

// MARK: - Layers
private extension SyncView {
    var backgroundLayer: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader

                if accounts.isEmpty {
                    // Empty state card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No accounts connected")
                            .font(.headline)
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
                } else {
                    accountsCard
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    var sectionHeader: some View {
        Text("CONNECTED ACCOUNTS")
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
    }

    var accountsCard: some View {
        VStack(spacing: 0) {
            ForEach(accounts) { account in
                AccountRowView(account: account)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    // RIGHT-SWIPE -> show popup
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
                            showGoogleSetup = true
                        },
                        onConnectOutlook: {
                            showAddSheet = false
                            showOutlookSetup = true
                        }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

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
    }

    var trailingPlus: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showAddSheet = true
                onAddAccount?()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Add account")
        }
    }
}

// MARK: - Actions / Data
private extension SyncView {
    func startGoogleConnect() { print("Google OAuth…") }
    func startOutlookConnect() { print("Outlook OAuth…") }

    func loadAccounts() {
        let entities = AccountStorage.shared.connectedAccounts()
        self.accounts = entities.map(SyncAccount.init(entity:))
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
        GoogleAccountStore.shared.clearSyncToken(for: toRemove.email)

        loadAccounts()
        dismissDisconnect()

        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
    }

}

extension SyncAccount {
    init(entity e: AccountEntity) {
        // Provider mapping from Core Data string
        let provider: CalendarProvider = {
            switch (e.provider ?? "").lowercased() {
            case "outlook": return .outlook
            case "google":  return .google
            default:        return .google
            }
        }()

        // Status mapping: prefer explicit status, fall back to isConnected
        let status: SyncStatus = {
            let s = (e.status ?? "").lowercased()
            if s == "error" { return .error }
            if s == "syncing" { return .syncing }
            if s == "connected" || e.isConnected == true { return .connected }
            return .connected // safe default so row shows as connected if data is partial
        }()

        self.init(
            email: (e.email ?? "").lowercased(),
            provider: provider,
            status: status
        )
    }
}

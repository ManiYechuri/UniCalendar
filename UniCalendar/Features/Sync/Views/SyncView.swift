import SwiftUI

struct SyncView: View {
    // MARK: - State
    @State private var accounts: [SyncAccount] = [
        .init(email: "alex.morgan@gmail.com",     provider: .google,  status: .error),
        .init(email: "a.morgan@outlook.com",      provider: .outlook, status: .connected),
        .init(email: "alex.work@unical.dev",      provider: .google,  status: .connected),
        .init(email: "personal.stuff@hotmail.com",provider: .outlook, status: .connected),
    ]

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
                    startGoogleConnect()      // kick off ASWebAuthenticationSession / SDK
                },
                onCancel: {
                    showGoogleSetup = false
                }
            )
            .presentationDetents([.medium])    // tweak: .large if you prefer
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOutlookSetup) {
            ConnectOutlookSetupView(
                onContinue: {
                    showOutlookSetup = false
                    startOutlookConnect()   // kick off MS OAuth (ASWebAuthenticationSession / MSAL)
                },
                onCancel: {
                    showOutlookSetup = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }

        .animation(.easeInOut(duration: 0.2), value: showAddSheet)
        .animation(.easeInOut(duration: 0.2), value: showDisconnect)
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
                accountsCard
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
                            showGoogleSetup = true       // <-- open setup screen
                        },
                        onConnectOutlook: {
                            showAddSheet = false
                            showOutlookSetup = true   // open the Outlook setup card
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

// MARK: - Actions
private extension SyncView {
    func startGoogleConnect() { print("Google OAuth…") }
    func startOutlookConnect() { print("Outlook OAuth…") }

    func dismissDisconnect() {
        showDisconnect = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            accountPendingDisconnect = nil
        }
    }

    func confirmDisconnect() {
        guard let toRemove = accountPendingDisconnect else { return }
        accounts.removeAll { $0.id == toRemove.id }
        dismissDisconnect()
        // TODO: revoke tokens / clear cached events
    }
}


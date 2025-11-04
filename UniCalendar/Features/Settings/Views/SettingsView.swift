import SwiftUI

struct SettingsView: View {
    @State private var notificationsOn: Bool = NotificationPrefs.isEnabled
    @State private var timing: ReminderTime = .min15

    var onRefreshCalendar: (() -> Void)?
    var onClearCache: (() -> Void)?
    var onHelp: (() -> Void)?
    var onAbout: (() -> Void)?
    var onLogout: (() -> Void)?

    @State private var showLogoutConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(Typography.h2)

                    SectionHeader("ACCOUNT MANAGEMENT")
                    SettingCard {
                        NavigationLink {
                            SyncView()
                        } label: {
                            SettingRowContent(
                                icon: .init(systemName: "person.2.circle"),
                                iconTint: .gray,
                                title: "Manage Connected Accounts",
                                subtitle: nil,
                                trailingText: nil,
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    SectionHeader("NOTIFICATIONS")
                    SettingCard {
                        ToggleRow(
                            icon: .init(systemName: "bell.circle.fill"),
                            iconTint: .red,
                            title: "Event Notifications",
                            isOn: $notificationsOn
                        )
                        .onChange(of: notificationsOn) { newValue in
                            NotificationPrefs.setEnabled(newValue)
                            if newValue {
                                NotificationScheduler.shared.rescheduleAllUpcoming()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }

                        Divider().padding(.leading, 56)

                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            SettingRowContent(
                                icon: .init(systemName: "clock.arrow.circlepath"),
                                iconTint: .green,
                                title: "Notification",
                                subtitle: "Timing",
                                trailingText: timing.label,
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(role: .destructive, action: { showLogoutConfirm = true }) {
                        Text("Log Out")
                            .font(Typography.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .confirmationDialog(
                        "Are you sure you want to log out?",
                        isPresented: $showLogoutConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Log Out") {
                            performLogoutAndPurge()
                            onLogout?()
                        }
                        .font(Typography.f14SemiBold)
//                        Button("Cancel") {
//                            
//                        }
//                        .font(Typography.f14SemiBold)
                    } message: {
                        Text("This will sign you out and remove all calendars, events, and sync data stored on this device.")
                            .font(Typography.f12Regular)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .onAppear {
            notificationsOn = NotificationPrefs.isEnabled
        }
    }

    private func performLogoutAndPurge() {
        NotificationPrefs.setEnabled(false)

        EventStorage.shared.nukeAll()
        AccountStorage.shared.nukeAll()

        GoogleAccountStore.shared.removeAllSyncTokens()
        GoogleAuthService.shared.signOut()                
        NotificationCenter.default.post(name: .accountsDidChange, object: nil)
        NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)
    }
}


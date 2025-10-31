import SwiftUI

struct SettingsView: View {
    // State
    @State private var notificationsOn: Bool = true
    @State private var timing: ReminderTime = .min15   // reuse the enum from NotificationSettingsView

    // Callbacks (optional)
    var onManageAccounts: (() -> Void)?
    var onRefreshCalendar: (() -> Void)?
    var onClearCache: (() -> Void)?
    var onHelp: (() -> Void)?
    var onAbout: (() -> Void)?
    var onLogout: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.system(size: 34, weight: .heavy))

                    // ACCOUNT MANAGEMENT
                    SectionHeader("ACCOUNT MANAGEMENT")
                    SettingCard {
                        SettingRow(
                            icon: .init(systemName: "person.2.circle"),
                            iconTint: .gray,
                            title: "Manage Connected Accounts",
                            accessory: .chevron
                        ) { onManageAccounts?() }
                    }

                    // NOTIFICATIONS
                    SectionHeader("NOTIFICATIONS")
                    SettingCard {
                        ToggleRow(
                            icon: .init(systemName: "bell.circle.fill"),
                            iconTint: .red,
                            title: "Event Notifications",
                            isOn: $notificationsOn
                        )

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

                    // DATA MANAGEMENT
                    SectionHeader("DATA MANAGEMENT")
                    SettingCard {
                        SettingRow(
                            icon: .init(systemName: "arrow.clockwise.circle"),
                            iconTint: .blue,
                            title: "Refresh Calendar Data",
                            accessory: .chevron
                        ) { onRefreshCalendar?() }

                        Divider().padding(.leading, 56)

                        SettingRow(
                            icon: .init(systemName: "trash.circle"),
                            iconTint: .yellow,
                            title: "Clear Cache",
                            accessory: .chevron
                        ) { onClearCache?() }
                    }

                    // GENERAL
                    SectionHeader("GENERAL")
                    SettingCard {
                        SettingRow(
                            icon: .init(systemName: "questionmark.circle"),
                            iconTint: .blue,
                            title: "Help & Support",
                            accessory: .chevron
                        ) { onHelp?() }

                        Divider().padding(.leading, 56)

                        SettingRow(
                            icon: .init(systemName: "info.circle"),
                            iconTint: .gray,
                            title: "About UniCal",
                            accessory: .chevron
                        ) { onAbout?() }
                    }

                    // LOG OUT
                    Button(action: { onLogout?() }) {
                        Text("Log Out")
                            .font(.headline)
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
    }
}


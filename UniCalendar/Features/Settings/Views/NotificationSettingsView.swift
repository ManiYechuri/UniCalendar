import SwiftUI

struct NotificationSettingsView: View {
    @State private var enableAll: Bool = NotificationPrefs.isEnabled
    @State private var selectedReminder: ReminderTime =
        ReminderTime.fromStored(minutes: NotificationPrefs.leadMinutes)
    @State private var soundEnabled: Bool = true
    @State private var vibrateEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Enable All Notifications toggle
                SettingCard {
                    HStack {
                        Label("Enable All Notifications", systemImage: "bell.fill")
                            .labelStyle(.titleAndIcon)
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $enableAll).labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)

                // Remind Me section
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("REMIND ME")
                    SettingCard {
                        ForEach(ReminderTime.allCases, id: \.self) { time in
                            Button {
                                selectedReminder = time
                            } label: {
                                HStack {
                                    Text(time.label).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: selectedReminder == time ? "circle.inset.filled" : "circle")
                                        .foregroundColor(selectedReminder == time ? .blue : .secondary)
                                        .imageScale(.large)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if time != ReminderTime.allCases.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Alert preferences
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("ALERT PREFERENCES")
                    SettingCard {
                        ToggleRow(
                            icon: Image(systemName: "speaker.wave.2.fill"),
                            iconTint: .blue,
                            title: "Sound",
                            isOn: $soundEnabled
                        )

                        Divider().padding(.leading, 56)

                        ToggleRow(
                            icon: Image(systemName: "iphone.radiowaves.left.and.right"),
                            iconTint: .blue,
                            title: "Vibrate",
                            isOn: $vibrateEnabled
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        // Write prefs + reschedule notifications when settings change
        .onChange(of: enableAll) { newValue in
            NotificationPrefs.isEnabled = newValue
            NotificationScheduler.shared.rescheduleAllUpcoming()
        }
        .onChange(of: selectedReminder) { newValue in
            if let mins = newValue.minutesBefore {
                NotificationPrefs.leadMinutes = mins
                NotificationScheduler.shared.rescheduleAllUpcoming()
            }
        }
    }
}


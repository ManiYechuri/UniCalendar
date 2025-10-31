import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var enableAll: Bool = true
    @State private var selectedReminder: ReminderTime = .min15
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

                // Remind Me
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

                // Alert Preferences
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

                        SettingRow(
                            icon: Image(systemName: "music.note.list"),
                            iconTint: .blue,
                            title: "Notification Tone",
                            subtitle: nil,
                            trailingText: "Default",
                            accessory: .chevron,
                            action: { /* present tone picker later */ }
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
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button { dismiss() } label: {
//                    Image(systemName: "chevron.left").font(.title3)
//                }
//            }
//        }
    }
}

// MARK: - Reminder options
enum ReminderTime: CaseIterable {
    case atEvent, min5, min15, min30, hour1, custom

    var label: String {
        switch self {
        case .atEvent: return "At time of event"
        case .min5:    return "5 minutes before"
        case .min15:   return "15 minutes before"
        case .min30:   return "30 minutes before"
        case .hour1:   return "1 hour before"
        case .custom:  return "Custom..."
        }
    }
}


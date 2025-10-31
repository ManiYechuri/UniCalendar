import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent

    var attendees: [String] = []
    var reminderMinutes: Int? = 15
    var notes: String? = nil
    var agenda: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.title)
                        .font(.system(size: 34, weight: .heavy))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        SourceTag(source: event.source, color: event.color.swiftUIColor)
                        Circle()
                            .fill(event.color.swiftUIColor)
                            .frame(width: 8, height: 8)
                    }
                }

                SettingCard {
                    InfoRow(
                        icon: "clock",
                        title: dayHeaderFormatter.string(from: event.start),
                        subtitle: timeRange(event)
                    )

                    if let loc = event.location, !loc.isEmpty {
                        Divider().padding(.leading, 56)
                        InfoRow(
                            icon: "mappin.and.ellipse",
                            title: loc,
                            subtitle: nil
                        )
                    }

                    Divider().padding(.leading, 56)
                    InfoRow(
                        icon: "network",
                        title: sourceText(event.source),
                        subtitle: nil
                    )

                    if !attendees.isEmpty {
                        Divider().padding(.leading, 56)
                        InfoRow(
                            icon: "person.2",
                            title: "Attendees (\(attendees.count))",
                            subtitle: nil,
                            trailing: AnyView(AvatarStack(names: attendees))
                        )
                    }

                    if let mins = reminderMinutes {
                        Divider().padding(.leading, 56)
                        InfoRow(
                            icon: "bell",
                            title: "\(mins) minutes before",
                            subtitle: nil
                        )
                    }
                }

                if notes != nil || !agenda.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        if let notes {
                            Text("Notes").font(.headline)
                            Text(notes).foregroundColor(.secondary)
                        }
                        if !agenda.isEmpty {
                            Text("Agenda").font(.headline)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(agenda, id: \.self) { item in
                                    Text("• \(item)").foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceText(_ s: CalendarEvent.Source) -> String {
        switch s { case .google: return "Google"; case .outlook: return "Outlook" }
    }

    private func timeRange(_ ev: CalendarEvent) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: ev.start)) – \(f.string(from: ev.end))"
    }
    
    private let dayHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()
}

private struct InfoRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(.systemGray6))
                Image(systemName: icon).foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)
            if let trailing { trailing }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

}


private struct SourceTag: View {
    let source: CalendarEvent.Source
    let color: Color
    var body: some View {
        Text(source == .google ? "Google" : "Outlook")
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill(color.opacity(0.12)))
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
            .foregroundColor(color)
    }
}

private struct AvatarStack: View {
    let names: [String]
    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.prefix(1) ?? ""
        let l = parts.dropFirst().first?.prefix(1) ?? ""
        return String(f + l)
    }
    var body: some View {
        HStack(spacing: -10) {
            ForEach(Array(names.prefix(4).enumerated()), id: \.offset) { _, n in
                Text(initials(n))
                    .font(.caption2.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.systemGray5)))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            if names.count > 4 {
                Text("+\(names.count - 4)")
                    .font(.caption2.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(.systemGray5)))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }
}

// MARK: - Little helpers

private extension CalendarEvent.EventColor {
    var swiftUIColor: Color {
        switch self { case .blue: return .blue; case .red: return .red }
    }
}


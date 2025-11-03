import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent

    private var attendeeNames: [String] {
        (event.attendees ?? []).map { attendee in
            if let n = attendee.name, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return n
            }
            if let e = attendee.email, let namePart = e.split(separator: "@").first {
                return String(namePart)
            }
            return "Unknown"
        }
    }
    
    private var attendeeEmails: [String] {
        (event.attendees ?? []).map { a in
            if let e = a.email, !e.isEmpty { return e }
            if let n = a.name, !n.isEmpty { return n }        // fallback if email missing
            return "unknown@local"
        }
    }

    private var attendeeCount: Int { attendeeNames.count }

    private var agendaPlainText: String? {
        guard let raw = event.agenda?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return raw.htmlStripped()
    }

    private var agendaBullets: [String] {
        guard let text = agendaPlainText else { return [] }
        return text
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                line
                    .replacingOccurrences(of: #"^\s*[-•*]\s*"#, with: "", options: .regularExpression)
            }
    }

    private var reminderMinutes: Int? { 15 } // keep if you add reminders later

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title + source chip
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.title)
                        .font(Typography.f35)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        SourceTag(source: event.source, color: event.color.swiftUIColor)
                        Circle()
                            .fill(event.color.swiftUIColor)
                            .frame(width: 8, height: 8)
                    }
                }

                // Info card
                SettingCard {
                    InfoRow(
                        icon: "clock",
                        title: dayHeaderFormatter.string(from: event.start),
                        subtitle: timeRange(event)
                    )

                    if let loc = event.location, !loc.isEmpty {
                        Divider().padding(.leading, 56)
                        InfoRow(icon: "mappin.and.ellipse", title: loc, subtitle: nil)
                    }

                    Divider().padding(.leading, 56)
                    InfoRow(icon: "network", title: sourceText(event.source), subtitle: nil)

                    if attendeeCount > 0 {
                        Divider().padding(.leading, 56)
                        InfoRow(
                            icon: "person.2",
                            title: "Attendees (\(attendeeCount))",
                            subtitle: nil,
                            trailing: AnyView(AvatarStack(names: attendeeNames))
                        )
                    }

                    if let mins = reminderMinutes {
                        Divider().padding(.leading, 56)
                        InfoRow(icon: "bell", title: "\(mins) minutes before", subtitle: nil)
                    }

                    if let link = event.htmlLink, let url = URL(string: link) {
                        Divider().padding(.leading, 56)
                        Link(destination: url) {
                            InfoRow(icon: "link", title: "Open in Google Calendar", subtitle: nil)
                        }
                    }
                }

                // Notes / Agenda block
                if agendaPlainText != nil || !agendaBullets.isEmpty || attendeeCount > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        if !agendaBullets.isEmpty {
                            Text("Agenda").font(.headline)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(agendaBullets, id: \.self) { item in
                                    Text("• \(item)").foregroundColor(.secondary)
                                }
                            }
                        } else if let agendaText = agendaPlainText {
                            Text("Notes").font(.headline)
                            Text(agendaText).foregroundColor(.secondary)
                        }

                        if attendeeCount > 0 {
                            Divider().padding(.vertical, 4)
                            Text("Attendees").font(.headline)
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(attendeeEmails, id: \.self) { n in
                                    Text("• \(n)").foregroundColor(.secondary)
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

// MARK: - Helpers used by the view

private extension String {
    func htmlStripped() -> String {
        // Simple & robust HTML → plain text converter
        guard let data = self.data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            return attributed.string
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self
    }
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
                    .font(Typography.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.subheadline)
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
            .font(Typography.f14SemiBold)
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

private extension CalendarEvent.EventColor {
    var swiftUIColor: Color {
        switch self { case .blue: return .blue; case .red: return .red }
    }
}


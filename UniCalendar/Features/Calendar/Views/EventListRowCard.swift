import SwiftUI

struct EventListRowCard: View {
    let event: CalendarEvent

    private var fill: Color { event.color == .blue ? Color.blue.opacity(0.12) : Color.red.opacity(0.12) }
    private var accent: Color { event.color == .blue ? .blue : .red }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)

            // left spine
            HStack(spacing: 0) {
                Rectangle().fill(accent).frame(width: 8)
                Spacer(minLength: 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                Text(timeRange(event))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func timeRange(_ ev: CalendarEvent) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: ev.start)) - \(f.string(from: ev.end))"
    }
}


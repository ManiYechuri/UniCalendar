import SwiftUI

struct EventCardView: View {
    let event: CalendarEvent

    private var fill: Color { event.color == .blue ? Color.blue.opacity(0.18) : Color.red.opacity(0.18) }
    private var accent: Color { event.color == .blue ? .blue : .red }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18).fill(fill)
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent, lineWidth: 6)
                .mask(Rectangle().frame(width: 10).offset(x: -6))
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.headline.weight(.semibold))
                if let loc = event.location { Text(loc).font(.subheadline).foregroundColor(.secondary) }
            }
            .padding(12)
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.08)))
    }
}


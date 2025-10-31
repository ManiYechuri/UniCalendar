import SwiftUI

struct EventBubbleView: View {
    let event: CalendarEvent
    let hourHeight: CGFloat

    private var fill: Color {
        switch event.color {
        case .blue: return Color.blue.opacity(0.18)
        case .red:  return Color.red.opacity(0.18)
        }
    }
    private var border: Color {
        switch event.color {
        case .blue: return .blue
        case .red:  return .red
        }
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(Typography.footer)
                if let loc = event.location {
                    Text(loc)
                        .font(Typography.footer)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Left colored spine
            HStack(spacing: 0) {
                Rectangle()
                    .fill(border)
                    .frame(width: 8) // spine width
                Spacer(minLength: 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        // Optional subtle border (full outline). Remove if you only want the spine.
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
    }
}


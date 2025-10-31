import SwiftUI

struct MoreEventsPopupView: View {
    let title: String
    let events: [CalendarEvent]
    var onClose: () -> Void

    private let maxPopupHeight: CGFloat = 420

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Button("Done", action: onClose)
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()
            contentView
                .padding(16)
                .animation(.default, value: events.count)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .fixedSize(horizontal: false, vertical: true) // <-- grow to fit content
    }


    @ViewBuilder
    private var contentView: some View {
        let stack = VStack(spacing: 14) {
            ForEach(events) { ev in
                EventListRowCard(event: ev)
            }
        }

        if estimatedHeight <= maxPopupHeight {
            stack
        } else {
            ScrollView {
                stack
            }
            .frame(maxHeight: maxPopupHeight)
        }
    }

    private var estimatedHeight: CGFloat {
        let perRow: CGFloat = 90
        let rows = CGFloat(max(events.count, 1))
        let stackSpacing = max(0, rows - 1) * 14
        let headerAndInsets: CGFloat = 18 + 12 + 1 + 32 
        return rows * perRow + stackSpacing + headerAndInsets
    }
}


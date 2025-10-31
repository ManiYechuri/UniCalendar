import SwiftUI

struct TimelineGridView: View {
    let hours: ClosedRange<Int>
    let hourHeight: CGFloat

    private func label(for hour: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return "\(h12) \(period)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(hours), id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(label(for: hour))
                        .font(Typography.footer)
                        .foregroundColor(.secondary)
                        .frame(width: 52, alignment: .trailing)
                        .padding(.trailing, 8)

                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }
}


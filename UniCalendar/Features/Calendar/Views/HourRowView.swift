import SwiftUI

struct HourRowView: View {
    let hour: Int
    let events: [CalendarEvent]
    var onMoreTapped: (_ hour: Int, _ events: [CalendarEvent]) -> Void
    var onEventTapped: (CalendarEvent) -> Void

    private func label(for hour: Int) -> String {
        let p = hour < 12 ? "AM" : "PM"
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h) \(p)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(label(for: hour))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
                Rectangle().fill(Color(.systemGray5)).frame(height: 1)
            }
            .frame(width: 60)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let maxVisible = 2
                    let visible = Array(events.prefix(maxVisible))
                    ForEach(visible) { ev in
                        Button {
                            onEventTapped(ev)
                        } label: {
                            MeetingChipView(
                                title: ev.title,
                                color: ev.color == .blue ? .blue : .red
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    let remaining = max(0, events.count - maxVisible)
                    if remaining > 0 {
                        Button {
                            onMoreTapped(hour, events)
                        } label: {
                            Text("+\(remaining) more")
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.systemGray5)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)       
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 8)
        .id(hour)
    }
}


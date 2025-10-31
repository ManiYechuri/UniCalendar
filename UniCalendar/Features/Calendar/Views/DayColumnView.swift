import SwiftUI

struct DayColumnView: View {
    let dayEvents: [CalendarEvent]
    let hourHeight: CGFloat
    let dayStartHour = 0          

    var body: some View {
        GeometryReader { geo in
            let laid = layoutOverlapping(dayEvents)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(.systemGray6)).cornerRadius(12).opacity(0.45)
                    .overlay(Rectangle().fill(Color(.systemGray4)).frame(width: 1), alignment: .trailing)

                ForEach(laid) { l in
                    let top = yOffset(for: l.event.start)
                    let height = heightForEvent(l.event)
                    let width = (geo.size.width - 8) / CGFloat(max(l.columnsInCluster,1))
                    let x = CGFloat(l.column) * width + 4

                    EventCardView(event: l.event)
                        .frame(width: width - 6, height: height)
                        .position(x: x + (width - 6)/2, y: top + height/2)
                }
            }
        }
    }

    private func yOffset(for date: Date) -> CGFloat {
        let mins = (date.hour() - dayStartHour) * 60 + date.minute()
        return CGFloat(mins) / 60 * hourHeight
    }
    private func heightForEvent(_ ev: CalendarEvent) -> CGFloat {
        let mins = max(10, Int(ev.end.timeIntervalSince(ev.start)/60))
        return CGFloat(mins) / 60 * hourHeight
    }
}


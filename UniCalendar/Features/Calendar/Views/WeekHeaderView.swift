import SwiftUI

struct WeekHeaderView: View {
    let monthTitle: String
    let days: [Date]
    let selectedDate: Date?
    let onPrev: () -> Void
    let onNext: () -> Void
    let onSelect: (Date) -> Void
    var onSettings: () -> Void = {}
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onPrev) { Image(systemName: "chevron.left").font(.title3) }
                Button(action: onAdd)  { Image(systemName: "plus").font(.title3) }
                Spacer()
                Text(monthTitle).font(Typography.f18Bold)
                Spacer()
                Button(action: onSettings) { Image(systemName: "gearshape").font(.title3) }
                Button(action: onNext) { Image(systemName: "chevron.right").font(.title3) }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 16) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    let isSelected = selectedDate?.isSameDay(as: date) == true
                    let isToday = Date().isSameDay(as: date)

                    Button { onSelect(date) } label: {
                        VStack(spacing: 6) {
                            Text(weekdayFormatter.string(from: date)).font(.caption).foregroundColor(.secondary)
                            Text(dayNumberFormatter.string(from: date))
                                .font(.headline)
                                .frame(width: 36, height: 45)
                                .background(Circle().fill(isSelected ? Color.blue : .clear))
                                .overlay(Circle().stroke(isToday && !isSelected ? Color(.systemGray4) : .clear, lineWidth: 1))
                                .foregroundColor(isSelected ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
    
    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
}


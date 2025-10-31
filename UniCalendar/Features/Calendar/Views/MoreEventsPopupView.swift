import SwiftUI

struct MoreEventsPopupView: View {
    let title: String
    let events: [CalendarEvent]
    var onClose: () -> Void
    var onSelect: (CalendarEvent) -> Void   // <-- new

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // List the hidden events as tappable rows
            VStack(spacing: 8) {
                ForEach(events) { ev in
                    Button {
                        onSelect(ev)                 // <-- fire selection
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(ev.color == .blue ? Color.blue : Color.red)
                                .frame(width: 10, height: 10)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(ev.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

                                Text(timeRange(ev))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                if let loc = ev.location, !loc.isEmpty {
                                    Text(loc)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }

    private func timeRange(_ ev: CalendarEvent) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: ev.start)) – \(f.string(from: ev.end))"
    }
}


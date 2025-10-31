import SwiftUI

struct LaidOutEvent: Identifiable {
    let id = UUID()
    let event: CalendarEvent
    let column: Int
    let columnsInCluster: Int
}

func layoutOverlapping(_ events: [CalendarEvent]) -> [LaidOutEvent] {
    let sorted = events.sorted { $0.start < $1.start }
    var clusters: [[CalendarEvent]] = []
    var current: [CalendarEvent] = []
    var currentEnd: Date?

    for ev in sorted {
        if let end = currentEnd, ev.start >= end {
            clusters.append(current)
            current = [ev]
            currentEnd = ev.end
        } else {
            current.append(ev)
            currentEnd = max(currentEnd ?? ev.end, ev.end)
        }
    }
    if !current.isEmpty { clusters.append(current) }

    // Assign columns inside each cluster
    var laid: [LaidOutEvent] = []
    for cluster in clusters {
        var columns: [[CalendarEvent]] = []
        for ev in cluster {
            var placed = false
            for (idx, col) in columns.enumerated() {
                if let last = col.last, last.end > ev.start {
                    continue // overlaps, cannot place in this column
                } else {
                    columns[idx].append(ev)
                    laid.append(LaidOutEvent(event: ev, column: idx, columnsInCluster: 0))
                    placed = true
                    break
                }
            }
            if !placed {
                columns.append([ev])
                laid.append(LaidOutEvent(event: ev, column: columns.count - 1, columnsInCluster: 0))
            }
        }
        // Update cluster width info
        let total = max(1, columns.count)
        laid = laid.map { l in
            if cluster.contains(where: { $0.id == l.event.id }) {
                return LaidOutEvent(event: l.event, column: l.column, columnsInCluster: total)
            } else { return l }
        }
    }
    return laid
}


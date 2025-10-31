import Foundation

// MARK: - Calendar helpers (safe, explicit)
extension Calendar {
    // Use a canonical calendar if you like; works with Calendar.current too.
    static let app = Calendar(identifier: .gregorian)

    // MARK: Year/month boundaries

    /// Jan 1 of the year containing `date`
    func startOfYear(for date: Date = Date()) -> Date {
        let comps = self.dateComponents([.year], from: date)
        return self.date(from: DateComponents(year: comps.year, month: 1, day: 1))!
    }

    /// Jan 1 of the next year after `date`
    func startOfNextYear(after date: Date = Date()) -> Date {
        let y0 = startOfYear(for: date)
        return self.date(byAdding: .year, value: 1, to: y0)!
    }

    /// First day of the month containing `date`
    func startOfMonth(for date: Date = Date()) -> Date {
        let comps = self.dateComponents([.year, .month], from: date)
        return self.date(from: DateComponents(year: comps.year, month: comps.month, day: 1))!
    }

    /// Start of the month that is N months before `date`
    func startOfMonth(monthsAgo n: Int, from date: Date = Date()) -> Date {
        let shifted = self.date(byAdding: .month, value: -n, to: date)!
        return startOfMonth(for: shifted)
    }

    // MARK: Day boundaries

    /// Start of tomorrow relative to `date` (00:00)
    func startOfTomorrow(_ date: Date = Date()) -> Date {
        let todayStart = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: todayStart)!
    }

    // MARK: Convenience windows

    /// Start of the month 3 months ago (overload matches your call: `threeMonthsAgoStart(now)`)
    func threeMonthsAgoStart(_ date: Date = Date()) -> Date {
        startOfMonth(monthsAgo: 3, from: date)
    }

    /// Property form (if some files use `Calendar.app.threeMonthsAgoStart`)
    var threeMonthsAgoStart: Date {
        startOfMonth(monthsAgo: 3, from: Date())
    }

    /// Start of next year (works as an "end of current year" exclusive boundary)
    func endOfYear(for date: Date = Date()) -> Date {
        startOfNextYear(after: date)
    }
}

// Optional: handy hour/minute accessors on Date (keeps older code compiling)
extension Date {
    var hourComponent: Int { Calendar.current.component(.hour, from: self) }
    var minuteComponent: Int { Calendar.current.component(.minute, from: self) }
    func hour() -> Int { hourComponent }
    func minute() -> Int { minuteComponent }
}

// Optional: ISO8601 with fractional seconds for Google API
extension ISO8601DateFormatter {
    static let api: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Date helpers (keeps your old API + gives new ones)

extension Date {
    /// Start of day using the app's calendar.
    var startOfDayApp: Date { Calendar.app.startOfDay(for: self) }

    /// Same-day check using the app's calendar.
    func isSameDay(as other: Date) -> Bool {
        Calendar.app.isDate(self, inSameDayAs: other)
    }

    /// 0...23 hour component (modern property).
    //var hourComponent: Int { Calendar.app.component(.hour, from: self) }

    /// 0...59 minute component (modern property).
   // var minuteComponent: Int { Calendar.app.component(.minute, from: self) }

    // ---- Backwards-compatible methods (so your older code compiles) ----

    /// Old-style method used in your existing views.
    //func hour() -> Int { Calendar.app.component(.hour, from: self) }

    /// Old-style method used in your existing views.
    //func minute() -> Int { Calendar.app.component(.minute, from: self) }
}

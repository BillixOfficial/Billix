import Foundation

extension Date {
    /// Format date as relative time (e.g., "2 hours ago", "3 days ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format date as short date string (e.g., "Nov 19, 2025")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format date as month and year (e.g., "November 2025")
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Check if date is within last N days
    func isWithinLast(days: Int) -> Bool {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return false
        }
        return self > startDate
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is within this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

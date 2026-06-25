import Foundation

extension Date {
    var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: self)
    }

    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }

    var timeAgoString: String {
        let days = daysSince
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }
}

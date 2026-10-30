import Foundation

public struct Clock: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var pinned: Bool

    public init(id: String, label: String = "", pinned: Bool = false) {
        self.id = id
        self.label = label
        self.pinned = pinned
    }

    public var zone: TimeZone { TimeZone(identifier: id) ?? .gmt }
    public var city: String { id.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? id }
    public var name: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? city : trimmed
    }

    public func time(at date: Date, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    public func dateText(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = zone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    public func dayDifference(at date: Date, relativeTo localZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        func civilDay(in zone: TimeZone) -> Date {
            var source = calendar
            source.timeZone = zone
            return calendar.date(from: source.dateComponents([.year, .month, .day], from: date))!
        }
        return calendar.dateComponents([.day], from: civilDay(in: localZone), to: civilDay(in: zone)).day ?? 0
    }

    public func offset(at date: Date) -> String {
        let minutes = zone.secondsFromGMT(for: date) / 60
        if minutes == 0 { return "UTC" }
        let remainder = abs(minutes) % 60
        return "UTC\(minutes < 0 ? "−" : "+")\(abs(minutes) / 60)" + (remainder == 0 ? "" : String(format: ":%02d", remainder))
    }

    public func isDaytime(at date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return (7..<19).contains(calendar.component(.hour, from: date))
    }

    public static func menuBarTitle(clocks: [Clock], at date: Date, use24Hour: Bool) -> String {
        let pinned = clocks.filter(\.pinned)
        let title = pinned.prefix(2).map {
            "\(String($0.name.prefix(14))) \($0.time(at: date, use24Hour: use24Hour))"
        }.joined(separator: "  ·  ")
        return title + (pinned.count > 2 ? "  +\(pinned.count - 2)" : "")
    }

    public static func search(_ query: String) -> [String] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifiers = Array(Set(TimeZone.knownTimeZoneIdentifiers + ["UTC"])).sorted()
        return identifiers.filter {
            query.isEmpty || $0.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(query)
        }
    }
}

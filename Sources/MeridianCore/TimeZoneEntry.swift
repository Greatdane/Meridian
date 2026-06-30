import Foundation

public struct TimeZoneEntry: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var timeZoneIdentifier: String
    public var displayName: String
    public var emoji: String
    public var showInMenuBar: Bool

    public init(
        id: UUID = UUID(),
        timeZoneIdentifier: String,
        displayName: String,
        emoji: String,
        showInMenuBar: Bool = false
    ) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.displayName = displayName
        self.emoji = emoji
        self.showInMenuBar = showInMenuBar
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    public func resolvedName(using catalog: [TimeZoneCatalogItem]) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }

        if let item = catalog.first(where: { $0.identifier == timeZoneIdentifier }) {
            return item.title
        }

        return Self.cityName(from: timeZoneIdentifier)
    }

    public static func cityName(from identifier: String) -> String {
        let city = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return city.replacingOccurrences(of: "_", with: " ")
    }
}

public enum DefaultZones {
    public static let entries: [TimeZoneEntry] = [
        TimeZoneEntry(
            timeZoneIdentifier: "Europe/London",
            displayName: "London",
            emoji: TimeZoneCatalog.flagEmoji(for: "GB"),
            showInMenuBar: true
        ),
        TimeZoneEntry(
            timeZoneIdentifier: "Asia/Kolkata",
            displayName: "Kolkata",
            emoji: TimeZoneCatalog.flagEmoji(for: "IN")
        ),
        TimeZoneEntry(
            timeZoneIdentifier: "Europe/Berlin",
            displayName: "Berlin",
            emoji: TimeZoneCatalog.flagEmoji(for: "DE")
        ),
        TimeZoneEntry(
            timeZoneIdentifier: "Australia/Sydney",
            displayName: "Sydney",
            emoji: TimeZoneCatalog.flagEmoji(for: "AU")
        ),
        TimeZoneEntry(
            timeZoneIdentifier: "America/New_York",
            displayName: "New York",
            emoji: TimeZoneCatalog.flagEmoji(for: "US")
        ),
        TimeZoneEntry(
            timeZoneIdentifier: "Europe/Amsterdam",
            displayName: "Amsterdam",
            emoji: TimeZoneCatalog.flagEmoji(for: "NL")
        )
    ]
}

import Foundation

public enum MenuBarMode: String, CaseIterable, Codable, Sendable {
    case iconOnly
    case zoneTime = "firstZoneTime"
    case localTime

    public var title: String {
        switch self {
        case .iconOnly:
            return "Icon"
        case .zoneTime:
            return "Zone"
        case .localTime:
            return "Local"
        }
    }

    public static var allCases: [MenuBarMode] {
        [.iconOnly, .zoneTime]
    }
}

public enum MenuBarIcon: String, CaseIterable, Codable, Sendable {
    case globe
    case clock
    case map

    public var title: String {
        switch self {
        case .globe:
            return "Globe"
        case .clock:
            return "Clock"
        case .map:
            return "Map"
        }
    }

    public var systemSymbolName: String {
        switch self {
        case .globe:
            return "globe"
        case .clock:
            return "clock.fill"
        case .map:
            return "map"
        }
    }
}

public enum AppAppearance: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    public var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

public enum ClockTimeFormat: String, CaseIterable, Codable, Sendable {
    case twentyFourHour
    case twelveHour

    public var title: String {
        switch self {
        case .twentyFourHour:
            return "24-hour"
        case .twelveHour:
            return "AM/PM"
        }
    }

    public var dateFormat: String {
        switch self {
        case .twentyFourHour:
            return "HH:mm"
        case .twelveHour:
            return "h:mm a"
        }
    }
}

public struct ZonePreferencesPayload: Codable, Equatable, Sendable {
    public var entries: [TimeZoneEntry]
    public var menuBarMode: MenuBarMode
    public var menuBarIcon: MenuBarIcon
    public var showMenuBarZoneFlag: Bool
    public var showMenuBarZoneName: Bool
    public var appearance: AppAppearance
    public var timeFormat: ClockTimeFormat
    public var showLocalTime: Bool
    public var localTimeZoneIdentifier: String?
    public var showUTCOffset: Bool

    public init(
        entries: [TimeZoneEntry] = DefaultZones.entries,
        menuBarMode: MenuBarMode = .iconOnly,
        menuBarIcon: MenuBarIcon = .globe,
        showMenuBarZoneFlag: Bool = false,
        showMenuBarZoneName: Bool = false,
        appearance: AppAppearance = .system,
        timeFormat: ClockTimeFormat = .twentyFourHour,
        showLocalTime: Bool = true,
        localTimeZoneIdentifier: String? = nil,
        showUTCOffset: Bool = true
    ) {
        self.entries = entries
        self.menuBarMode = menuBarMode == .localTime ? .iconOnly : menuBarMode
        self.menuBarIcon = menuBarIcon
        self.showMenuBarZoneFlag = showMenuBarZoneFlag
        self.showMenuBarZoneName = showMenuBarZoneName
        self.appearance = appearance
        self.timeFormat = timeFormat
        self.showLocalTime = showLocalTime
        self.localTimeZoneIdentifier = localTimeZoneIdentifier
        self.showUTCOffset = showUTCOffset
    }

    private enum CodingKeys: String, CodingKey {
        case entries
        case menuBarMode
        case menuBarIcon
        case showMenuBarZoneFlag
        case showMenuBarZoneName
        case appearance
        case timeFormat
        case showLocalTime
        case localTimeZoneIdentifier
        case showUTCOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entries = try container.decodeIfPresent([TimeZoneEntry].self, forKey: .entries) ?? DefaultZones.entries
        let decodedMenuBarMode = (try? container.decodeIfPresent(MenuBarMode.self, forKey: .menuBarMode)) ?? .iconOnly
        self.menuBarMode = decodedMenuBarMode == .localTime ? .iconOnly : decodedMenuBarMode
        self.menuBarIcon = try container.decodeIfPresent(MenuBarIcon.self, forKey: .menuBarIcon) ?? .globe
        self.showMenuBarZoneFlag = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarZoneFlag) ?? false
        self.showMenuBarZoneName = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarZoneName) ?? false
        self.appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        self.timeFormat = try container.decodeIfPresent(ClockTimeFormat.self, forKey: .timeFormat) ?? .twentyFourHour
        self.showLocalTime = try container.decodeIfPresent(Bool.self, forKey: .showLocalTime) ?? true
        self.localTimeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .localTimeZoneIdentifier)
        self.showUTCOffset = try container.decodeIfPresent(Bool.self, forKey: .showUTCOffset) ?? true
    }
}

public enum ZonePreferencesCoding {
    public static func encode(_ payload: ZonePreferencesPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    public static func decode(_ data: Data) throws -> ZonePreferencesPayload {
        try JSONDecoder().decode(ZonePreferencesPayload.self, from: data)
    }
}

import Foundation
import MeridianCore

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func expect<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: T, _ message: String) throws {
    let value = actual()
    guard value == expected else {
        throw CheckFailure(description: "\(message): expected \(expected), got \(value)")
    }
}

func require<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw CheckFailure(description: message)
    }
    return value
}

func isoDate(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
}

func checkZoneTabParsing() throws {
    let fixture = """
    # comments are ignored
    JP\t+353916+1394441\tAsia/Tokyo
    US\t+404251-0740023\tAmerica/New_York\tEastern
    GB\t+513030-0000731\tEurope/London
    """

    let items = TimeZoneCatalog.parseZoneTab(fixture, locale: Locale(identifier: "en_US"))
    try expect(items.count, 3, "zone1970 rows should parse")

    let tokyo = try require(items.first { $0.identifier == "Asia/Tokyo" }, "Tokyo should exist")
    try expect(tokyo.title, "Tokyo", "Tokyo title")
    try expect(tokyo.countryNames, ["Japan"], "Tokyo country")
    try expect(tokyo.flagEmoji, TimeZoneCatalog.flagEmoji(for: "JP"), "Tokyo flag")

        let newYork = try require(items.first { $0.identifier == "America/New_York" }, "New York should exist")
        try expect(newYork.title, "New York", "New York city title")
        try expect(newYork.detail, "United States - Eastern", "New York detail")
}

func checkSearch() throws {
    let fixture = """
    JP\t+353916+1394441\tAsia/Tokyo
    US\t+404251-0740023\tAmerica/New_York\tEastern
    """

    let items = TimeZoneCatalog.parseZoneTab(fixture, locale: Locale(identifier: "en_US"))

    try expect(
        TimeZoneCatalog.filteredItems(from: items, query: "Japan").map(\.identifier),
        ["Asia/Tokyo"],
        "country search"
    )
    try expect(
        TimeZoneCatalog.filteredItems(from: items, query: "new").map(\.identifier),
        ["America/New_York"],
        "city search"
    )
    try expect(
        TimeZoneCatalog.filteredItems(from: items, query: "America/New").map(\.identifier),
        ["America/New_York"],
        "identifier search"
    )
}

func checkSystemCatalogFlagFallbacks() throws {
    let items = TimeZoneCatalog.load(locale: Locale(identifier: "en_US"))
    let tokyo = try require(TimeZoneCatalog.item(for: "Asia/Tokyo", in: items), "Tokyo should exist in system catalog")
    try expect(tokyo.flagEmoji, TimeZoneCatalog.flagEmoji(for: "JP"), "Tokyo should resolve Japan flag")
    let utc = try require(TimeZoneCatalog.item(for: "UTC", in: items), "UTC should exist in system catalog")
    try expect(utc.title, "UTC", "UTC title")
    let losAngeles = try require(TimeZoneCatalog.item(for: "America/Los_Angeles", in: items), "Los Angeles should exist in system catalog")
    try expect(losAngeles.title, "Los Angeles", "Los Angeles city title")
}

func checkFormattingAndPreferences() throws {
    let baseDate = try require(isoDate("2026-06-30T00:30:00Z"), "fixture date should parse")
    let tokyo = try require(TimeZone(identifier: "Asia/Tokyo"), "Tokyo time zone should exist")

    let display = TimeZoneDisplay.zoneDisplay(
        for: tokyo,
        baseDate: baseDate,
        sliderMinutes: 90,
        locale: Locale(identifier: "en_US_POSIX")
    )
    try expect(display.time, "11:00", "slider-adjusted Tokyo time")
    try expect(display.gmtOffset, "GMT+09:00", "Tokyo GMT offset")
    try expect(TimeZoneDisplay.utcOffsetShort(for: tokyo, at: baseDate), "UTC+9", "Tokyo short UTC offset")

    let twelveHourDisplay = TimeZoneDisplay.zoneDisplay(
        for: tokyo,
        baseDate: baseDate,
        sliderMinutes: 90,
        locale: Locale(identifier: "en_US_POSIX"),
        timeFormat: .twelveHour
    )
    try expect(twelveHourDisplay.time, "11:00 AM", "12-hour Tokyo time")
    try expect(
        TimeZoneDisplay.sliderLabel(
            baseDate: baseDate,
            sliderMinutes: 90,
            timeZone: tokyo,
            referenceTimeZone: tokyo,
            locale: Locale(identifier: "en_US_POSIX"),
            timeFormat: .twelveHour
        ),
        "11:00 AM Today",
        "12-hour slider label"
    )

    let scrubBaseDate = try require(isoDate("2026-06-30T04:33:00Z"), "scrubber fixture date should parse")
    try expect(
        TimeZoneDisplay.snappedSliderMinutes(
            baseDate: scrubBaseDate,
            proposedSliderMinutes: 5,
            timeZone: tokyo
        ),
        7,
        "scrubber forward snap to next five-minute clock time"
    )
    try expect(
        TimeZoneDisplay.snappedSliderMinutes(
            baseDate: scrubBaseDate,
            proposedSliderMinutes: -5,
            timeZone: tokyo
        ),
        -3,
        "scrubber backward snap to previous five-minute clock time"
    )
    try expect(
        TimeZoneDisplay.snappedSliderMinutes(
            baseDate: scrubBaseDate,
            proposedSliderMinutes: 0,
            timeZone: tokyo
        ),
        0,
        "scrubber keeps now centered"
    )

    try expect(TimeZoneDisplay.dayLabel(for: -1), "Yesterday", "yesterday label")
    try expect(TimeZoneDisplay.dayLabel(for: 0), "Today", "today label")
    try expect(TimeZoneDisplay.dayLabel(for: 1), "Tomorrow", "tomorrow label")
    try expect(TimeZoneDisplay.dayLabel(for: -2), "2 days ago", "multi-day past label")
    try expect(TimeZoneDisplay.dayLabel(for: 3), "+3 days", "multi-day future label")
    try expect(TimeZoneDisplay.inlineDaySuffix(for: -1), "(-1 day)", "inline previous-day label")
    try expect(TimeZoneDisplay.inlineDaySuffix(for: 0), "", "inline same-day label")
    try expect(TimeZoneDisplay.inlineDaySuffix(for: 1), "(+1 day)", "inline next-day label")
    try expect(TimeZoneNameAbbreviator.abbreviation(for: "New York"), "N.Y.", "New York abbreviation")
    try expect(TimeZoneNameAbbreviator.abbreviation(for: "Los Angeles"), "L.A.", "Los Angeles abbreviation")
    try expect(TimeZoneNameAbbreviator.abbreviation(for: "London"), "LON", "London abbreviation")

        let payload = ZonePreferencesPayload(
            entries: [
                TimeZoneEntry(
                    id: UUID(uuidString: "8DF9746D-143D-41C9-BF8B-8D093F3F0026")!,
                timeZoneIdentifier: "Europe/London",
                displayName: "Team",
                emoji: TimeZoneCatalog.flagEmoji(for: "GB"),
                showInMenuBar: true
            )
            ],
            menuBarMode: .zoneTime,
            menuBarIcon: .clock,
            showMenuBarZoneFlag: true,
            showMenuBarZoneName: true,
            appearance: .light,
            timeFormat: .twelveHour,
            showLocalTime: true,
            localTimeZoneIdentifier: "Asia/Tokyo",
            showUTCOffset: false
        )

    let data = try ZonePreferencesCoding.encode(payload)
    let decoded = try ZonePreferencesCoding.decode(data)
    try expect(decoded, payload, "preferences round trip")

    let oldPayload = try ZonePreferencesCoding.decode(#"{"entries":[],"menuBarMode":"firstZoneTime"}"#.data(using: .utf8)!)
    try expect(oldPayload.menuBarMode, .zoneTime, "old zone mode raw value")
    try expect(oldPayload.menuBarIcon, .globe, "old payload icon default")
    try expect(oldPayload.showMenuBarZoneName, false, "old payload menu bar name default")
    try expect(oldPayload.appearance, .system, "old payload appearance default")
    try expect(oldPayload.timeFormat, .twentyFourHour, "old payload time format default")
    try expect(oldPayload.showUTCOffset, true, "old payload UTC offset default")
    try expect(MenuBarMode.allCases, [.iconOnly, .zoneTime], "menu bar display choices")
    try expect(MenuBarIcon.clock.systemSymbolName, "clock.fill", "clock icon should use filled symbol")

    let oldLocalPayload = try ZonePreferencesCoding.decode(#"{"entries":[],"menuBarMode":"localTime"}"#.data(using: .utf8)!)
    try expect(oldLocalPayload.menuBarMode, .iconOnly, "old local menu bar mode is hidden")

    let freshPayload = ZonePreferencesPayload()
    try expect(freshPayload.menuBarMode, .iconOnly, "fresh install menu bar mode")
    try expect(freshPayload.menuBarIcon, .globe, "fresh install menu bar icon")
}

let checks: [(String, () throws -> Void)] = [
    ("zone tab parsing", checkZoneTabParsing),
    ("search", checkSearch),
    ("system catalog flags", checkSystemCatalogFlagFallbacks),
    ("formatting and preferences", checkFormattingAndPreferences)
]

do {
    for (name, check) in checks {
        try check()
        print("ok - \(name)")
    }
    print("All checks passed.")
} catch {
    fputs("Check failed: \(error)\n", stderr)
    exit(1)
}

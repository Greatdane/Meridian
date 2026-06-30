import Combine
import Foundation
import ServiceManagement
import SwiftUI
import MeridianCore

@MainActor
final class ZoneViewModel: ObservableObject {
    @Published var entries: [TimeZoneEntry] {
        didSet {
            save()
        }
    }

    @Published var tags: [ZoneTag] {
        didSet {
            save()
        }
    }

    @Published var sliderMinutes: Double = 0

    @Published var menuBarMode: MenuBarMode {
        didSet {
            save()
        }
    }

    @Published var menuBarIcon: MenuBarIcon {
        didSet {
            save()
        }
    }

    @Published var showMenuBarZoneFlag: Bool {
        didSet {
            save()
        }
    }

    @Published var showMenuBarZoneName: Bool {
        didSet {
            save()
        }
    }

    @Published var appearance: AppAppearance {
        didSet {
            save()
        }
    }

    @Published var displaySize: DisplaySize {
        didSet {
            save()
        }
    }

    @Published var timeFormat: ClockTimeFormat {
        didSet {
            save()
        }
    }

    @Published var showLocalTime: Bool {
        didSet {
            save()
        }
    }

    @Published var showUTCOffset: Bool {
        didSet {
            save()
        }
    }

    @Published var localTimeZoneIdentifier: String {
        didSet {
            if TimeZone(identifier: localTimeZoneIdentifier) == nil {
                localTimeZoneIdentifier = TimeZone.autoupdatingCurrent.identifier
                return
            }
            save()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else {
                return
            }
            setLaunchAtLogin(launchAtLogin)
        }
    }

    @Published private(set) var launchAtLoginError: String?

    @Published private(set) var now: Date
    @Published private(set) var timeSortOrder: TimeSortOrder?

    let catalog: [TimeZoneCatalogItem]

    private let defaults: UserDefaults
    private let preferencesKey = "meridian.preferences.v1"

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        self.now = now
        self.catalog = TimeZoneCatalog.load()

        if
            let data = defaults.data(forKey: preferencesKey),
            let payload = try? ZonePreferencesCoding.decode(data)
        {
            self.entries = payload.entries
            self.tags = payload.tags
            self.menuBarMode = payload.menuBarMode
            self.menuBarIcon = payload.menuBarIcon
            self.showMenuBarZoneFlag = payload.showMenuBarZoneFlag
            self.showMenuBarZoneName = payload.showMenuBarZoneName
            self.appearance = payload.appearance
            self.displaySize = payload.displaySize
            self.timeFormat = payload.timeFormat
            self.showLocalTime = payload.showLocalTime
            self.localTimeZoneIdentifier = payload.localTimeZoneIdentifier ?? TimeZone.autoupdatingCurrent.identifier
            self.showUTCOffset = payload.showUTCOffset
        } else {
            self.entries = DefaultZones.entries
            self.tags = []
            self.menuBarMode = .iconOnly
            self.menuBarIcon = .globe
            self.showMenuBarZoneFlag = false
            self.showMenuBarZoneName = false
            self.appearance = .system
            self.displaySize = .standard
            self.timeFormat = .twentyFourHour
            self.showLocalTime = true
            self.localTimeZoneIdentifier = TimeZone.autoupdatingCurrent.identifier
            self.showUTCOffset = true
        }
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.timeSortOrder = nil
    }

    var sliderMinutesInt: Int {
        Int(sliderMinutes.rounded())
    }

    var statusTitle: String {
        switch menuBarMode {
        case .iconOnly:
            return ""
        case .zoneTime:
            let entry = selectedMenuBarEntry
            guard let entry else {
                return ""
            }
            let display = display(for: entry)
            var parts: [String] = []
            if showMenuBarZoneFlag {
                parts.append(entryEmoji(entry))
            }
            if showMenuBarZoneName {
                parts.append(TimeZoneNameAbbreviator.abbreviation(for: entryName(entry)))
            }
            parts.append(display.compactTime)
            return " \(parts.filter { !$0.isEmpty }.joined(separator: " "))"
        case .localTime:
            return ""
        }
    }

    var statusImageSymbolName: String? {
        switch menuBarMode {
        case .iconOnly:
            return menuBarIcon.systemSymbolName
        case .zoneTime, .localTime:
            return nil
        }
    }

    var sliderLabel: String {
        TimeZoneDisplay.sliderLabel(
            baseDate: now,
            sliderMinutes: sliderMinutesInt,
            timeZone: configuredLocalTimeZone,
            referenceTimeZone: configuredLocalTimeZone,
            timeFormat: timeFormat
        )
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var localTimeZoneName: String {
        TimeZoneCatalog.item(for: localTimeZoneIdentifier, in: catalog)?.title
            ?? TimeZoneEntry.cityName(from: localTimeZoneIdentifier)
    }

    var localTimeZoneEmoji: String {
        defaultEmoji(for: localTimeZoneIdentifier)
    }

    var visibleEntries: [TimeZoneEntry] {
        guard showLocalTime else {
            return entries
        }
        return entries.filter { $0.timeZoneIdentifier != localTimeZoneIdentifier }
    }

    var selectedMenuBarEntry: TimeZoneEntry? {
        visibleEntries.first(where: \.showInMenuBar) ?? visibleEntries.first
    }

    var visiblePopoverRowCount: Int {
        visibleEntries.count + (showLocalTime ? 1 : 0)
    }

    var popoverWidth: CGFloat {
        420
    }

    var popoverHeight: CGFloat {
        let scale = CGFloat(displaySize.scale)
        let rowHeight = CGFloat(max(visiblePopoverRowCount, 1)) * 79 * scale
        let taggedRowHeight = CGFloat(visibleEntries.filter { !$0.tagIDs.isEmpty }.count) * 22 * scale
        return min(max(rowHeight + taggedRowHeight + 145, 316), 700)
    }

    var timeSortTitle: String {
        switch timeSortOrder {
        case .earliestFirst:
            return "Time ↑"
        case .latestFirst:
            return "Time ↓"
        case nil:
            return "Sort by Time"
        }
    }

    func tick() {
        now = Date()
    }

    func setSliderMinutesFromScrub(_ minutes: Double) {
        sliderMinutes = Double(TimeZoneDisplay.snappedSliderMinutes(
            baseDate: now,
            proposedSliderMinutes: minutes,
            timeZone: configuredLocalTimeZone
        ))
    }

    func adjustSlider(by minutes: Double) {
        setSliderMinutesFromScrub(sliderMinutes + minutes)
    }

    func display(for entry: TimeZoneEntry) -> ZoneDisplay {
        TimeZoneDisplay.zoneDisplay(
            for: entry.timeZone,
            baseDate: now,
            sliderMinutes: sliderMinutesInt,
            referenceTimeZone: configuredLocalTimeZone,
            timeFormat: timeFormat
        )
    }

    func tags(for entry: TimeZoneEntry) -> [ZoneTag] {
        entry.tagIDs.compactMap { tagID in
            tags.first { $0.id == tagID }
        }
    }

    func isTag(_ tag: ZoneTag, assignedTo entry: TimeZoneEntry) -> Bool {
        entry.tagIDs.contains(tag.id)
    }

    func addTag(name: String, colorHex: String) -> ZoneTag? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return nil
        }

        let tag = ZoneTag(name: uniqueTagName(trimmedName), colorHex: colorHex)
        tags.append(tag)
        return tag
    }

    func updateTag(_ tag: ZoneTag, name: String, colorHex: String) {
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            tags[index].name = uniqueTagName(trimmedName, excluding: tag.id)
        }
        tags[index].colorHex = colorHex
    }

    func removeTag(_ tag: ZoneTag) {
        tags.removeAll { $0.id == tag.id }
        for index in entries.indices {
            entries[index].tagIDs.removeAll { $0 == tag.id }
        }
    }

    func toggleTag(_ tag: ZoneTag, for entry: TimeZoneEntry) {
        guard let entryIndex = entries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }

        if entries[entryIndex].tagIDs.contains(tag.id) {
            entries[entryIndex].tagIDs.removeAll { $0 == tag.id }
        } else {
            entries[entryIndex].tagIDs.append(tag.id)
        }
    }

    private func uniqueTagName(_ name: String, excluding excludedID: UUID? = nil) -> String {
        let existingNames = Set(tags
            .filter { $0.id != excludedID }
            .map { $0.name.lowercased() })
        guard existingNames.contains(name.lowercased()) else {
            return name
        }

        var counter = 2
        while existingNames.contains("\(name) \(counter)".lowercased()) {
            counter += 1
        }
        return "\(name) \(counter)"
    }

    func entryName(_ entry: TimeZoneEntry) -> String {
        entry.resolvedName(using: catalog)
    }

    func entryEmoji(_ entry: TimeZoneEntry) -> String {
        let trimmed = entry.emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == TimeZoneCatalog.defaultGlobeEmoji {
            return defaultEmoji(for: entry.timeZoneIdentifier)
        }
        return trimmed
    }

    func defaultEmoji(for timeZoneIdentifier: String) -> String {
        TimeZoneCatalog.item(for: timeZoneIdentifier, in: catalog)?.flagEmoji ?? TimeZoneCatalog.defaultGlobeEmoji
    }

    func isLocal(_ entry: TimeZoneEntry) -> Bool {
        showLocalTime && entry.timeZoneIdentifier == localTimeZoneIdentifier
    }

    func localDisplay() -> ZoneDisplay {
        return TimeZoneDisplay.zoneDisplay(
            for: configuredLocalTimeZone,
            baseDate: now,
            sliderMinutes: sliderMinutesInt,
            referenceTimeZone: configuredLocalTimeZone,
            timeFormat: timeFormat
        )
    }

    func utcOffset(for entry: TimeZoneEntry) -> String {
        TimeZoneDisplay.utcOffsetShort(for: entry.timeZone, at: TimeZoneDisplay.displayDate(baseDate: now, sliderMinutes: sliderMinutesInt))
    }

    func localUTCOffset() -> String {
        return TimeZoneDisplay.utcOffsetShort(for: configuredLocalTimeZone, at: TimeZoneDisplay.displayDate(baseDate: now, sliderMinutes: sliderMinutesInt))
    }

    private var configuredLocalTimeZone: TimeZone {
        TimeZone(identifier: localTimeZoneIdentifier) ?? .autoupdatingCurrent
    }

    func contains(_ item: TimeZoneCatalogItem) -> Bool {
        entries.contains { $0.timeZoneIdentifier == item.identifier }
    }

    func filteredCatalog(query: String) -> [TimeZoneCatalogItem] {
        TimeZoneCatalog.filteredItems(from: catalog, query: query)
    }

    func add(_ item: TimeZoneCatalogItem) {
        guard !contains(item) else {
            return
        }

        let shouldShowInMenuBar = entries.isEmpty
        entries.append(TimeZoneEntry(
            timeZoneIdentifier: item.identifier,
            displayName: item.title,
            emoji: item.flagEmoji,
            showInMenuBar: shouldShowInMenuBar
        ))
        applyTimeSortIfNeeded()
    }

    func remove(_ entry: TimeZoneEntry) {
        entries.removeAll { $0.id == entry.id }

        if !entries.contains(where: \.showInMenuBar), !entries.isEmpty {
            entries[0].showInMenuBar = true
        }
    }

    func update(_ entry: TimeZoneEntry, displayName: String, emoji: String, showInMenuBar: Bool) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }

        if showInMenuBar {
            for existingIndex in entries.indices {
                entries[existingIndex].showInMenuBar = false
            }
        }

        entries[index].displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[index].emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultEmoji(for: entries[index].timeZoneIdentifier)
            : emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[index].showInMenuBar = showInMenuBar
        applyTimeSortIfNeeded()
    }

    func move(_ entry: TimeZoneEntry, direction: MoveDirection) {
        timeSortOrder = nil
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }

        let destination: Int
        switch direction {
        case .up:
            destination = max(entries.startIndex, index - 1)
        case .down:
            destination = min(entries.index(before: entries.endIndex), index + 1)
        }

        guard destination != index else {
            return
        }

        entries.swapAt(index, destination)
    }

    func moveEntry(from source: Int, to destination: Int) {
        timeSortOrder = nil
        guard entries.indices.contains(source), source != destination else {
            return
        }

        let moving = entries.remove(at: source)
        let insertionIndex = min(max(destination, entries.startIndex), entries.endIndex)
        entries.insert(moving, at: insertionIndex)
    }

    func moveEntry(draggedID: UUID, before targetID: UUID) {
        timeSortOrder = nil
        guard
            draggedID != targetID,
            let sourceIndex = entries.firstIndex(where: { $0.id == draggedID }),
            let target = entries.first(where: { $0.id == targetID })
        else {
            return
        }

        let moving = entries.remove(at: sourceIndex)
        guard let targetIndex = entries.firstIndex(where: { $0.id == target.id }) else {
            entries.insert(moving, at: sourceIndex)
            return
        }
        entries.insert(moving, at: targetIndex)
    }

    func setMenuBarEntry(_ entry: TimeZoneEntry) {
        for index in entries.indices {
            entries[index].showInMenuBar = entries[index].id == entry.id
        }
    }

    func sortEntriesByDisplayedTime() {
        switch timeSortOrder {
        case .earliestFirst:
            timeSortOrder = .latestFirst
        case .latestFirst, nil:
            timeSortOrder = .earliestFirst
        }
        applyTimeSortIfNeeded()
    }

    private func applyTimeSortIfNeeded() {
        guard let timeSortOrder else {
            return
        }

        let displayDate = TimeZoneDisplay.displayDate(baseDate: now, sliderMinutes: sliderMinutesInt)
        entries.sort { lhs, rhs in
            let lhsKey = timeSortKey(for: lhs.timeZone, at: displayDate)
            let rhsKey = timeSortKey(for: rhs.timeZone, at: displayDate)
            if lhsKey != rhsKey {
                switch timeSortOrder {
                case .earliestFirst:
                    return lhsKey < rhsKey
                case .latestFirst:
                    return lhsKey > rhsKey
                }
            }
            return entryName(lhs).localizedCaseInsensitiveCompare(entryName(rhs)) == .orderedAscending
        }
    }

    private func timeSortKey(for timeZone: TimeZone, at date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let dayOffset = TimeZoneDisplay.calendarDayOffset(
            referenceDate: now,
            displayDate: date,
            referenceTimeZone: configuredLocalTimeZone,
            timeZone: timeZone
        )
        return dayOffset * 1_440 + (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func save() {
        let payload = ZonePreferencesPayload(
            entries: entries,
            tags: tags,
            menuBarMode: menuBarMode,
            menuBarIcon: menuBarIcon,
            showMenuBarZoneFlag: showMenuBarZoneFlag,
            showMenuBarZoneName: showMenuBarZoneName,
            appearance: appearance,
            displaySize: displaySize,
            timeFormat: timeFormat,
            showLocalTime: showLocalTime,
            localTimeZoneIdentifier: localTimeZoneIdentifier,
            showUTCOffset: showUTCOffset
        )
        guard let data = try? ZonePreferencesCoding.encode(payload) else {
            return
        }
        defaults.set(data, forKey: preferencesKey)
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

enum MoveDirection {
    case up
    case down
}

enum TimeSortOrder {
    case earliestFirst
    case latestFirst
}

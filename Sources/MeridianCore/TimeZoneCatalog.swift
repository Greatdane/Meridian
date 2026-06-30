import Foundation

public struct TimeZoneCatalogItem: Hashable, Identifiable, Sendable {
    public var id: String { identifier }

    public let identifier: String
    public let countryCodes: [String]
    public let countryNames: [String]
    public let title: String
    public let detail: String
    public let flagEmoji: String

    public init(
        identifier: String,
        countryCodes: [String],
        countryNames: [String],
        title: String,
        detail: String,
        flagEmoji: String
    ) {
        self.identifier = identifier
        self.countryCodes = countryCodes
        self.countryNames = countryNames
        self.title = title
        self.detail = detail
        self.flagEmoji = flagEmoji
    }
}

public enum TimeZoneCatalog {
    public static let systemZoneTabURL = URL(fileURLWithPath: "/usr/share/zoneinfo/zone1970.tab")
    public static let legacySystemZoneTabURL = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")

    public static func load(
        zoneTabURL: URL = systemZoneTabURL,
        locale: Locale = .autoupdatingCurrent
    ) -> [TimeZoneCatalogItem] {
        var contents = ""
        if let zone1970 = try? String(contentsOf: zoneTabURL, encoding: .utf8) {
            contents.append(zone1970)
        }
        if let legacyZoneTab = try? String(contentsOf: legacySystemZoneTabURL, encoding: .utf8) {
            contents.append("\n")
            contents.append(legacyZoneTab)
        }

        if !contents.isEmpty {
            let parsed = withBuiltInItems(deduplicated(parseZoneTab(contents, locale: locale)))
            if !parsed.isEmpty {
                return parsed
            }
        }

        return withBuiltInItems(fallback(locale: locale))
    }

    public static func parseZoneTab(
        _ contents: String,
        locale: Locale = .autoupdatingCurrent
    ) -> [TimeZoneCatalogItem] {
        contents
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine in
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty, !line.hasPrefix("#") else {
                    return nil
                }

                let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard fields.count >= 3 else {
                    return nil
                }

                let codes = fields[0]
                    .split(separator: ",")
                    .map { String($0).uppercased() }
                    .filter { $0.count == 2 }
                let identifier = String(fields[2])
                guard TimeZone(identifier: identifier) != nil else {
                    return nil
                }

                let comment = fields.count >= 4 ? String(fields[3]) : ""
                let countryNames = codes.compactMap { localizedCountryName(for: $0, locale: locale) }
                let city = TimeZoneEntry.cityName(from: identifier)
                let title = city
                let detail = detailText(countryNames: countryNames, comment: comment, identifier: identifier)

                return TimeZoneCatalogItem(
                    identifier: identifier,
                    countryCodes: codes,
                    countryNames: countryNames,
                    title: title,
                    detail: detail,
                    flagEmoji: flagEmoji(for: codes.first)
                )
            }
            .sorted { lhs, rhs in
                let lhsCountry = lhs.countryNames.first ?? lhs.identifier
                let rhsCountry = rhs.countryNames.first ?? rhs.identifier
                if lhsCountry.localizedCaseInsensitiveCompare(rhsCountry) == .orderedSame {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhsCountry.localizedCaseInsensitiveCompare(rhsCountry) == .orderedAscending
            }
    }

    public static func fallback(locale: Locale = .autoupdatingCurrent) -> [TimeZoneCatalogItem] {
        TimeZone.knownTimeZoneIdentifiers.map { identifier in
            TimeZoneCatalogItem(
                identifier: identifier,
                countryCodes: [],
                countryNames: [],
                title: TimeZoneEntry.cityName(from: identifier),
                detail: identifier.replacingOccurrences(of: "_", with: " "),
                flagEmoji: defaultGlobeEmoji
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public static func filteredItems(
        from items: [TimeZoneCatalogItem],
        query: String,
        limit: Int = 80
    ) -> [TimeZoneCatalogItem] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return Array(items.prefix(limit))
        }

        let ranked = items.compactMap { item -> (TimeZoneCatalogItem, Int)? in
            let haystacks = [
                item.title,
                item.identifier,
                item.detail,
                item.countryCodes.joined(separator: " "),
                item.countryNames.joined(separator: " ")
            ].map(normalize)

            guard haystacks.contains(where: { $0.contains(normalizedQuery) }) else {
                return nil
            }

            if normalize(item.title).hasPrefix(normalizedQuery) {
                return (item, 0)
            }
            if item.countryNames.map(normalize).contains(where: { $0.hasPrefix(normalizedQuery) }) {
                return (item, 1)
            }
            if normalize(item.identifier).contains("/\(normalizedQuery)") {
                return (item, 2)
            }
            return (item, 3)
        }

        return Array(ranked
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 < rhs.1
                }
                return lhs.0.title.localizedCaseInsensitiveCompare(rhs.0.title) == .orderedAscending
            }
            .map(\.0)
            .prefix(limit))
    }

    public static func item(for identifier: String, in items: [TimeZoneCatalogItem]) -> TimeZoneCatalogItem? {
        items.first { $0.identifier == identifier }
    }

    public static func flagEmoji(for regionCode: String?) -> String {
        guard let regionCode else {
            return defaultGlobeEmoji
        }

        let uppercased = regionCode.uppercased()
        guard uppercased.count == 2 else {
            return defaultGlobeEmoji
        }

        let scalars = uppercased.unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            guard scalar.value >= 65, scalar.value <= 90 else {
                return nil
            }
            return UnicodeScalar(127397 + scalar.value)
        }

        guard scalars.count == 2 else {
            return defaultGlobeEmoji
        }

        return String(String.UnicodeScalarView(scalars))
    }

    public static let defaultGlobeEmoji = String(UnicodeScalar(0x1F310)!)

    private static func detailText(
        countryNames: [String],
        comment: String,
        identifier: String
    ) -> String {
        var parts = countryNames
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty, !parts.contains(trimmedComment) {
            parts.append(trimmedComment)
        }

        if parts.isEmpty {
            parts.append(identifier.replacingOccurrences(of: "_", with: " "))
        }

        return parts.joined(separator: " - ")
    }

    private static func localizedCountryName(for code: String, locale: Locale) -> String? {
        locale.localizedString(forRegionCode: code)
    }

    private static func deduplicated(_ items: [TimeZoneCatalogItem]) -> [TimeZoneCatalogItem] {
        var seen: Set<String> = []
        return items.filter { item in
            seen.insert(item.identifier).inserted
        }
    }

    private static func withBuiltInItems(_ items: [TimeZoneCatalogItem]) -> [TimeZoneCatalogItem] {
        var result = items
        if !result.contains(where: { $0.identifier == "UTC" }) {
            result.insert(
                TimeZoneCatalogItem(
                    identifier: "UTC",
                    countryCodes: [],
                    countryNames: [],
                    title: "UTC",
                    detail: "Coordinated Universal Time",
                    flagEmoji: defaultGlobeEmoji
                ),
                at: 0
            )
        }
        return result
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

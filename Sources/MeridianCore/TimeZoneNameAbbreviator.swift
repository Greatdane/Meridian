import Foundation

public enum TimeZoneNameAbbreviator {
    private static let overrides: [String: String] = [
        "amsterdam": "AMS",
        "berlin": "BER",
        "kolkata": "KOL",
        "london": "LON",
        "los angeles": "L.A.",
        "new york": "N.Y.",
        "san francisco": "S.F.",
        "sydney": "SYD",
        "tokyo": "TYO",
        "utc": "UTC",
        "washington dc": "D.C.",
        "washington d.c.": "D.C."
    ]

    public static func abbreviation(for name: String) -> String {
        let cleaned = normalized(name)
        guard !cleaned.isEmpty else {
            return ""
        }

        if let override = overrides[cleaned] {
            return override
        }

        let words = cleaned.split(separator: " ").map(String.init)
        if words.count > 1 {
            return words.prefix(2)
                .compactMap(\.first)
                .map { "\($0).".uppercased() }
                .joined()
        }

        let letters = cleaned.filter { $0.isLetter || $0.isNumber }
        if letters.count <= 3 {
            return letters.uppercased()
        }

        return String(letters.prefix(3)).uppercased()
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ". ")).inverted)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .lowercased()
    }
}

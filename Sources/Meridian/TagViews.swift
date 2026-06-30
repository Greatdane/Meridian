import SwiftUI
import MeridianCore

enum TagPalette {
    static let colors = [
        "#0A84FF",
        "#30D158",
        "#FF9F0A",
        "#FF453A",
        "#BF5AF2",
        "#64D2FF",
        "#FFD60A",
        "#8E8E93"
    ]
}

struct TagChipView: View {
    let tag: ZoneTag
    var compact = false

    var body: some View {
        Text(tag.name)
            .font(.system(size: compact ? 9.5 : 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(Color(hex: tag.colorHex).accessibleTextColor)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2.5 : 4)
            .background {
                Capsule()
                    .fill(Color(hex: tag.colorHex))
            }
    }
}

struct TagColorSwatches: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 7) {
            ForEach(TagPalette.colors, id: \.self) { colorHex in
                Button {
                    selection = colorHex
                } label: {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .stroke(selection == colorHex ? Color.primary : Color.clear, lineWidth: 2)
                        }
                        .padding(2)
                }
                .buttonStyle(.plain)
                .help(colorHex)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleaned.count {
        case 6:
            red = (value >> 16) & 0xff
            green = (value >> 8) & 0xff
            blue = value & 0xff
        default:
            red = 0x0a
            green = 0x84
            blue = 0xff
        }

        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }

    fileprivate var accessibleTextColor: Color {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else {
            return .white
        }
        let luminance = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
        return luminance > 0.62 ? .black.opacity(0.78) : .white
        #else
        return .white
        #endif
    }
}

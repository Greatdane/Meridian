import SwiftUI
import MeridianCore

struct ZoneRowView: View {
    @ObservedObject var model: ZoneViewModel
    let entry: TimeZoneEntry
    let isCopied: Bool
    let onEdit: () -> Void
    let onCopy: () -> Void

    var body: some View {
        let display = model.display(for: entry)
        let tags = model.tags(for: entry)
        let scale = model.displaySize.scale

        HStack(alignment: .center, spacing: 11 * scale) {
            VStack(alignment: .leading, spacing: 5 * scale) {
                HStack(spacing: 7 * scale) {
                    Text(model.entryEmoji(entry))
                        .font(.system(size: 17 * scale))
                        .frame(width: 23 * scale, alignment: .center)

                    Text(isCopied ? "Copied" : label(for: display))
                        .font(.system(size: 19 * scale, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(isCopied ? .green : .primary)
                }

                HStack(spacing: 7 * scale) {
                    Text(display.dayLabel)
                    if model.showUTCOffset {
                        Text(model.utcOffset(for: entry))
                    }
                }
                .font(.system(size: 11.5 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

                if !tags.isEmpty {
                    HStack(spacing: 5 * scale) {
                        ForEach(tags.prefix(3)) { tag in
                            TagChipView(tag: tag, compact: true, scale: scale)
                        }

                        if tags.count > 3 {
                            Text("+\(tags.count - 3)")
                                .font(.system(size: 10.75 * scale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            Text(display.time)
                .font(.system(size: 26.5 * scale, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 9 * scale)
        .padding(.horizontal, 11 * scale)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.045))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture(perform: onCopy)
        .contextMenu {
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Show in Menu Bar", systemImage: "menubar.rectangle") {
                model.setMenuBarEntry(entry)
            }
            Button("Move Up", systemImage: "arrow.up") {
                model.move(entry, direction: .up)
            }
            Button("Move Down", systemImage: "arrow.down") {
                model.move(entry, direction: .down)
            }
            Divider()
            Button("Remove", systemImage: "trash", role: .destructive) {
                model.remove(entry)
            }
        }
    }

    private func label(for display: ZoneDisplay) -> String {
        let suffix = TimeZoneDisplay.inlineDaySuffix(for: display.dayOffset)
        var parts = [model.entryName(entry)]
        if !suffix.isEmpty {
            parts.append(suffix)
        }
        return parts.joined(separator: " ")
    }
}

struct LocalZoneRowView: View {
    @ObservedObject var model: ZoneViewModel
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        let display = model.localDisplay()

        let scale = model.displaySize.scale

        HStack(alignment: .center, spacing: 11 * scale) {
            VStack(alignment: .leading, spacing: 5 * scale) {
                HStack(spacing: 7 * scale) {
                    Text(model.localTimeZoneEmoji)
                        .font(.system(size: 17 * scale))
                        .frame(width: 23 * scale, alignment: .center)

                    Text(isCopied ? "Copied" : model.localTimeZoneName)
                        .font(.system(size: 19 * scale, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(isCopied ? .green : .primary)

                    if !isCopied {
                        LocalTagView(scale: scale)
                    }
                }

                HStack(spacing: 7 * scale) {
                    Text(display.dayLabel)
                    if model.showUTCOffset {
                        Text(model.localUTCOffset())
                    }
                }
                .font(.system(size: 11.5 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(display.time)
                .font(.system(size: 26.5 * scale, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 9 * scale)
        .padding(.horizontal, 11 * scale)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.045))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture(perform: onCopy)
    }
}

struct LocalTagView: View {
    var scale = 1.0

    var body: some View {
        Text("local")
            .font(.system(size: 9.5 * scale, weight: .bold, design: .rounded))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5.5 * scale)
            .padding(.vertical, 2.5 * scale)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(0.10))
            }
    }
}

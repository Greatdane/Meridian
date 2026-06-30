import SwiftUI
import MeridianCore

struct TimeZonePickerView: View {
    @ObservedObject var model: ZoneViewModel
    let selectedIdentifier: String?
    let onSelect: ((TimeZoneCatalogItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    init(
        model: ZoneViewModel,
        selectedIdentifier: String? = nil,
        onSelect: ((TimeZoneCatalogItem) -> Void)? = nil
    ) {
        self.model = model
        self.selectedIdentifier = selectedIdentifier
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)

            Divider()
                .opacity(0.4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.filteredCatalog(query: query)) { item in
                        let isSelecting = onSelect != nil
                        let isSelected = selectedIdentifier == item.identifier
                        TimeZonePickerRow(
                            item: item,
                            isDisabled: !isSelecting && model.contains(item),
                            isSelected: isSelected || (!isSelecting && model.contains(item)),
                            date: model.now
                        ) {
                            if let onSelect {
                                onSelect(item)
                            } else {
                                model.add(item)
                            }
                            dismiss()
                        }

                        Divider()
                            .opacity(0.25)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .frame(width: 410, height: 520)
        .background(.regularMaterial)
        .preferredColorScheme(model.preferredColorScheme)
    }

    private var header: some View {
        HStack(spacing: 12) {
            TextField("Search city or country", text: $query)
                .textFieldStyle(.roundedBorder)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
    }
}

private struct TimeZonePickerRow: View {
    let item: TimeZoneCatalogItem
    let isDisabled: Bool
    let isSelected: Bool
    let date: Date
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                Text(item.flagEmoji)
                    .font(.system(size: 16))
                    .frame(width: 24, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(item.detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(offset)
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(isSelected ? .secondary : .primary)
            }
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var offset: String {
        guard let timeZone = TimeZone(identifier: item.identifier) else {
            return ""
        }
        return TimeZoneDisplay.gmtOffset(for: timeZone, at: date)
    }
}

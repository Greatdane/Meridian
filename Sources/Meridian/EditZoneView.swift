import SwiftUI
import MeridianCore

struct EditZoneView: View {
    @ObservedObject var model: ZoneViewModel
    @Environment(\.dismiss) private var dismiss
    let entry: TimeZoneEntry

    @State private var displayName: String
    @State private var emoji: String
    @State private var showInMenuBar: Bool

    init(model: ZoneViewModel, entry: TimeZoneEntry) {
        self.model = model
        self.entry = entry
        _displayName = State(initialValue: entry.displayName)
        _emoji = State(initialValue: model.entryEmoji(entry))
        _showInMenuBar = State(initialValue: entry.showInMenuBar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Edit Time Zone")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(model.entryName(entry))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    TextField("Emoji", text: $emoji)
                        .frame(width: 72)
                        .textFieldStyle(.roundedBorder)

                    TextField("Name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Show in menu bar", isOn: $showInMenuBar)
            }

            HStack {
                Button(role: .destructive) {
                    model.remove(entry)
                    dismiss()
                } label: {
                    Label("Remove", systemImage: "trash")
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    model.update(
                        entry,
                        displayName: displayName,
                        emoji: emoji,
                        showInMenuBar: showInMenuBar
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(.regularMaterial)
        .preferredColorScheme(model.preferredColorScheme)
    }
}

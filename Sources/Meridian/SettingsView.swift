import SwiftUI
import UniformTypeIdentifiers
import MeridianCore

struct SettingsView: View {
    @ObservedObject var model: ZoneViewModel
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = SettingsTab.timezones
    @State private var isShowingPicker = false
    @State private var isShowingLocalPicker = false
    @State private var editingEntry: TimeZoneEntry?
    @State private var draggedEntryID: UUID?
    @State private var newTagName = ""
    @State private var newTagColor = TagPalette.colors[0]

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Divider()
                .opacity(0.35)

            switch selectedTab {
            case .timezones:
                timezonesPane
            case .tags:
                tagsPane
            case .general:
                generalPane
            case .appearance:
                appearancePane
            }
        }
        .frame(width: 620, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(model.preferredColorScheme)
        .sheet(isPresented: $isShowingPicker) {
            TimeZonePickerView(model: model)
        }
        .sheet(isPresented: $isShowingLocalPicker) {
            TimeZonePickerView(
                model: model,
                selectedIdentifier: model.localTimeZoneIdentifier
            ) { item in
                model.localTimeZoneIdentifier = item.identifier
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditZoneView(model: model, entry: entry)
        }
    }

    private var tabBar: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 10) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    settingsTabButton(tab)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color.primary.opacity(0.035))
    }

    private func settingsTabButton(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.14)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(height: 24)

                Text(tab.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(width: 104, height: 58)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var timezonesPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text("Current Timezones")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))

                Spacer()

                Button {
                    model.sortEntriesByDisplayedTime()
                } label: {
                    Label(model.timeSortTitle, systemImage: "arrow.up.arrow.down")
                }
                .buttonStyle(.bordered)

                Button {
                    isShowingPicker = true
                } label: {
                    Label("Add Location", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: [.command])
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.entries) { entry in
                        SettingsZoneRow(
                            model: model,
                            entry: entry,
                            onEdit: { editingEntry = entry }
                        )
                        .onDrag {
                            draggedEntryID = entry.id
                            return NSItemProvider(object: entry.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: ZoneDropDelegate(
                                targetEntry: entry,
                                model: model,
                                draggedEntryID: $draggedEntryID
                            )
                        )

                        Divider()
                            .opacity(0.25)
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.045))
                }
            }
        }
        .padding(24)
    }

    private var generalPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                localTimeOptions

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rows")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Toggle("Show UTC offset", isOn: $model.showUTCOffset)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Startup")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Toggle("Start Meridian at login", isOn: $model.launchAtLogin)

                    if let launchAtLoginError = model.launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }

            }
            .padding(24)
        }
    }

    private var tagsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Manage Tags")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))

                    HStack(spacing: 12) {
                        TextField("Tag name", text: $newTagName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 190)
                            .onSubmit(addTag)

                        TagColorSwatches(selection: $newTagColor)

                        Spacer()

                        Button {
                            addTag()
                        } label: {
                            Label("Add Tag", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if model.tags.isEmpty {
                    Text("Create tags for people, teams, events, or anything else you want to see on time zone cards.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.045))
                        }
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.tags) { tag in
                            TagEditorRow(model: model, tag: tag)

                            if tag.id != model.tags.last?.id {
                                Divider()
                                    .opacity(0.25)
                            }
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.045))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Assign Tags")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    VStack(spacing: 0) {
                        ForEach(model.entries) { entry in
                            TagAssignmentRow(model: model, entry: entry)

                            if entry.id != model.entries.last?.id {
                                Divider()
                                    .opacity(0.25)
                            }
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.045))
                    }
                }
            }
            .padding(24)
        }
    }

    private var appearancePane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Appearance")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Picker("Appearance", selection: $model.appearance) {
                        ForEach(AppAppearance.allCases, id: \.self) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Format")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Picker("Format", selection: $model.timeFormat) {
                        ForEach(ClockTimeFormat.allCases, id: \.self) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Bar")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Picker("Display", selection: $model.menuBarMode) {
                        ForEach(MenuBarMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch model.menuBarMode {
                case .iconOnly:
                    iconOptions
                case .zoneTime:
                    zoneOptions
                case .localTime:
                    EmptyView()
                }
            }
            .padding(24)
        }
    }

    private var iconOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(MenuBarIcon.allCases, id: \.self) { icon in
                    Button {
                        model.menuBarIcon = icon
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icon.systemSymbolName)
                                .font(.system(size: icon == .clock ? 20 : 18, weight: .semibold))
                            Text(icon.title)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(width: 82, height: 56)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(model.menuBarIcon == icon ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.055))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var zoneOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Show selected zone flag in the menu bar", isOn: $model.showMenuBarZoneFlag)
            Toggle("Show place abbreviation in the menu bar", isOn: $model.showMenuBarZoneName)

            Text("Zone")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(model.visibleEntries) { entry in
                Button {
                    model.setMenuBarEntry(entry)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: entry.showInMenuBar ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.showInMenuBar ? .primary : .secondary)
                        Text(model.entryEmoji(entry))
                        Text(label(for: entry))
                        Spacer()
                        Text(model.display(for: entry).time)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var localTimeOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Local Time")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Toggle("Show local time at top", isOn: $model.showLocalTime)

            Button {
                isShowingLocalPicker = true
            } label: {
                HStack(spacing: 10) {
                    Text(model.localTimeZoneEmoji)
                    Text(model.localTimeZoneName)
                    LocalTagView()
                    Spacer()
                    Text(model.localDisplay().time)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.055))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func label(for entry: TimeZoneEntry) -> String {
        model.entryName(entry)
    }

    private func addTag() {
        guard model.addTag(name: newTagName, colorHex: newTagColor) != nil else {
            return
        }
        newTagName = ""
    }
}

private struct SettingsZoneRow: View {
    @ObservedObject var model: ZoneViewModel
    let entry: TimeZoneEntry
    let onEdit: () -> Void

    var body: some View {
        let display = model.display(for: entry)

        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .help("Drag to reorder")

            Text(model.entryEmoji(entry))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label(for: display))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Text(entry.timeZoneIdentifier)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !model.tags(for: entry).isEmpty {
                    HStack(spacing: 5) {
                        ForEach(model.tags(for: entry).prefix(4)) { tag in
                            TagChipView(tag: tag, compact: true)
                        }
                    }
                }
            }

            Spacer()

            Text(display.time)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .help("Edit name and emoji")

            Button(role: .destructive) {
                model.remove(entry)
            } label: {
                Image(systemName: "minus.circle")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .help("Remove")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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

private struct TagEditorRow: View {
    @ObservedObject var model: ZoneViewModel
    let tag: ZoneTag

    var body: some View {
        HStack(spacing: 12) {
            TagChipView(tag: currentTag)
                .frame(minWidth: 72, alignment: .leading)

            TextField("Name", text: nameBinding)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)

            TagColorSwatches(selection: colorBinding)

            Spacer()

            Button(role: .destructive) {
                model.removeTag(tag)
            } label: {
                Image(systemName: "minus.circle")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .help("Remove tag")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var currentTag: ZoneTag {
        model.tags.first { $0.id == tag.id } ?? tag
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { currentTag.name },
            set: { model.updateTag(tag, name: $0, colorHex: currentTag.colorHex) }
        )
    }

    private var colorBinding: Binding<String> {
        Binding(
            get: { currentTag.colorHex },
            set: { model.updateTag(tag, name: currentTag.name, colorHex: $0) }
        )
    }
}

private struct TagAssignmentRow: View {
    @ObservedObject var model: ZoneViewModel
    let entry: TimeZoneEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(model.entryEmoji(entry))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.entryName(entry))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(entry.timeZoneIdentifier)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 170, alignment: .leading)

            if model.tags.isEmpty {
                Text("Create a tag first")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(model.tags) { tag in
                            Button {
                                model.toggleTag(tag, for: entry)
                            } label: {
                                TagChipView(tag: tag, compact: true)
                                    .opacity(model.isTag(tag, assignedTo: entry) ? 1 : 0.32)
                                    .overlay {
                                        Capsule()
                                            .stroke(
                                                model.isTag(tag, assignedTo: entry) ? Color.clear : Color.primary.opacity(0.24),
                                                lineWidth: 1
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(model.isTag(tag, assignedTo: entry) ? "Remove \(tag.name)" : "Add \(tag.name)")
                        }
                    }
                    .padding(.vertical, 1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct ZoneDropDelegate: DropDelegate {
    let targetEntry: TimeZoneEntry
    @ObservedObject var model: ZoneViewModel
    @Binding var draggedEntryID: UUID?

    func dropEntered(info: DropInfo) {
        guard
            let draggedEntryID,
            draggedEntryID != targetEntry.id,
            let sourceIndex = model.entries.firstIndex(where: { $0.id == draggedEntryID }),
            let destinationIndex = model.entries.firstIndex(where: { $0.id == targetEntry.id })
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            model.moveEntry(from: sourceIndex, to: destinationIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedEntryID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private enum SettingsTab: CaseIterable {
    case timezones
    case tags
    case general
    case appearance

    var title: String {
        switch self {
        case .timezones:
            return "Timezones"
        case .tags:
            return "Tags"
        case .general:
            return "General"
        case .appearance:
            return "Appearance"
        }
    }

    var systemImage: String {
        switch self {
        case .timezones:
            return "clock"
        case .tags:
            return "tag"
        case .general:
            return "gearshape"
        case .appearance:
            return "eye"
        }
    }
}

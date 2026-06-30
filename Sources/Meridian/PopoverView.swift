import SwiftUI
import UniformTypeIdentifiers
import MeridianCore

struct PopoverView: View {
    @ObservedObject var model: ZoneViewModel
    let onShowSettings: () -> Void
    @State private var isShowingPicker = false
    @State private var editingEntry: TimeZoneEntry?
    @State private var draggedEntryID: UUID?
    @State private var copiedEntryID: UUID?
    @State private var copiedLocal = false
    @State private var hoveredAction: BottomAction?

    var body: some View {
        VStack(spacing: 0) {
            if model.showLocalTime {
                LocalZoneRowView(
                    model: model,
                    isCopied: copiedLocal,
                    onCopy: {
                        copy(model.localDisplay().time)
                        copiedLocal = true
                        clearCopiedStateLater()
                    }
                )
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 4)

                Divider()
                    .padding(.horizontal, 18)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.visibleEntries) { entry in
                        ZoneRowView(
                            model: model,
                            entry: entry,
                            isCopied: copiedEntryID == entry.id,
                            onEdit: {
                                editingEntry = entry
                            },
                            onCopy: {
                                copy(model.display(for: entry).time)
                                copiedEntryID = entry.id
                                copiedLocal = false
                                clearCopiedStateLater()
                            }
                        )
                        .onDrag {
                            draggedEntryID = entry.id
                            return NSItemProvider(object: entry.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: PopoverZoneDropDelegate(
                                targetEntry: entry,
                                model: model,
                                draggedEntryID: $draggedEntryID
                            )
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, model.showLocalTime ? 4 : 18)
                .padding(.bottom, 2)
            }
            .frame(maxHeight: .infinity)

            sliderPanel
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
                .frame(height: 140)
                .background(.regularMaterial)
        }
        .frame(width: model.popoverWidth, height: model.popoverHeight)
        .background(.regularMaterial)
        .preferredColorScheme(model.preferredColorScheme)
        .sheet(isPresented: $isShowingPicker) {
            TimeZonePickerView(model: model)
        }
        .sheet(item: $editingEntry) { entry in
            EditZoneView(model: model, entry: entry)
        }
    }

    private var sliderPanel: some View {
        VStack(spacing: 7) {
            TimeScrubberView(
                value: Binding(
                    get: { model.sliderMinutes },
                    set: { model.setSliderMinutesFromScrub($0) }
                ),
                range: -720...720,
                step: 5
            )
                .help("Slide backward or forward through the day")

            HStack(spacing: 10) {
                Button {
                    adjustSlider(by: -15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Back 15 minutes")

                Spacer()

                HStack(spacing: 10) {
                    Text(model.sliderLabel)
                        .font(.system(size: 14.25, weight: .semibold))
                        .monospacedDigit()

                    if model.sliderMinutesInt != 0 {
                        Button {
                            model.sliderMinutes = 0
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14.25, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary.opacity(0.88))
                        .help("Reset to now")
                    }
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.12))
                }

                Spacer()

                Button {
                    adjustSlider(by: 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Forward 15 minutes")
            }

            HStack(spacing: 10) {
                bottomActionButton(.add) {
                    isShowingPicker = true
                }

                Spacer()

                bottomActionButton(.settings) {
                    onShowSettings()
                }

                bottomActionButton(.closeApp) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .animation(.easeInOut(duration: 0.14), value: hoveredAction)
        }
    }

    private func bottomActionButton(_ action: BottomAction, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: hoveredAction == action ? 7 : 0) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 24, height: 24)

                if hoveredAction == action {
                    Text(action.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(.horizontal, hoveredAction == action ? 10 : 6)
            .frame(height: 32)
            .background {
                Capsule()
                    .fill(hoveredAction == action ? Color.primary.opacity(0.10) : Color.clear)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(action.title)
        .accessibilityLabel(action.title)
        .onHover { isHovering in
            hoveredAction = isHovering ? action : nil
        }
    }

    private func adjustSlider(by minutes: Double) {
        model.adjustSlider(by: minutes)
    }

    private func copy(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    private func clearCopiedStateLater() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            copiedEntryID = nil
            copiedLocal = false
        }
    }
}

private enum BottomAction: Hashable {
    case add
    case settings
    case closeApp

    var title: String {
        switch self {
        case .add:
            return "Add location"
        case .settings:
            return "Settings"
        case .closeApp:
            return "Close app"
        }
    }

    var systemImage: String {
        switch self {
        case .add:
            return "plus"
        case .settings:
            return "gearshape"
        case .closeApp:
            return "xmark"
        }
    }
}

private struct PopoverZoneDropDelegate: DropDelegate {
    let targetEntry: TimeZoneEntry
    @ObservedObject var model: ZoneViewModel
    @Binding var draggedEntryID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedEntryID else {
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            model.moveEntry(draggedID: draggedEntryID, before: targetEntry.id)
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

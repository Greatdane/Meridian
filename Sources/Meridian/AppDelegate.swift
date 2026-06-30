import AppKit
import Combine
import SwiftUI
import MeridianCore

@main
@MainActor
enum MeridianMain {
    private static let delegate = AppDelegate()

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = ZoneViewModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        bindModel()

        let refreshTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.model.tick()
            }
        }
        timer = refreshTimer
        RunLoop.main.add(refreshTimer, forMode: .common)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Meridian"
        updateStatusItem()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: model.popoverWidth, height: model.popoverHeight)
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model) { [weak self] in
            self?.showSettingsWindow()
        })
    }

    private func bindModel() {
        Publishers.MergeMany([
            model.$entries.map { _ in () }.eraseToAnyPublisher(),
            model.$menuBarMode.map { _ in () }.eraseToAnyPublisher(),
            model.$menuBarIcon.map { _ in () }.eraseToAnyPublisher(),
            model.$showMenuBarZoneFlag.map { _ in () }.eraseToAnyPublisher(),
            model.$showMenuBarZoneName.map { _ in () }.eraseToAnyPublisher(),
            model.$timeFormat.map { _ in () }.eraseToAnyPublisher(),
            model.$now.map { _ in () }.eraseToAnyPublisher()
        ])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let symbolName = model.statusImageSymbolName {
            let pointSize: CGFloat = 16
            statusItem.length = NSStatusItem.squareLength
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Meridian")
            let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
            let configuredImage = image?.withSymbolConfiguration(configuration) ?? image
            configuredImage?.size = NSSize(width: pointSize, height: pointSize)
            configuredImage?.isTemplate = true
            button.image = configuredImage
        } else {
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
        }
        button.title = model.statusTitle
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            model.tick()
            popover.contentSize = NSSize(width: model.popoverWidth, height: model.popoverHeight)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func showSettingsWindow() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 560),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Meridian Settings"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = NSHostingController(
                rootView: SettingsView(model: model) { [weak window] in
                    window?.close()
                }
            )
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

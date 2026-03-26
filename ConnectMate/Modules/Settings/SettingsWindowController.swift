import Cocoa

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let contentViewController = PreferencesViewController(settings: .shared)
        let window = NSWindow(contentViewController: contentViewController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 980, height: 700))
        window.minSize = NSSize(width: 900, height: 640)
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

import Cocoa

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    private let preferencesViewController: PreferencesViewController

    init(
        settings: AppSettings? = nil,
        updateManager: (any AppUpdateManaging)? = nil,
        dataExportService: AppDataExportService? = nil
    ) {
        let resolvedSettings = settings ?? .shared
        let contentViewController = PreferencesViewController(
            settings: resolvedSettings,
            updateManager: updateManager,
            dataExportService: dataExportService
        )
        self.preferencesViewController = contentViewController
        let window = NSWindow(contentViewController: contentViewController)
        window.title = L10n.Menu.preferences
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.toolbarStyle = .preference
        window.setContentSize(NSSize(width: 720, height: 380))
        window.minSize = NSSize(width: 680, height: 240)
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
        preferencesViewController.prepareForPresentation()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func present(section: PreferencesSection) {
        present()
        preferencesViewController.navigate(to: section)
    }

    func presentAPIKeys() {
        present()
        preferencesViewController.navigate(to: .cliAndAPI, presentAPIKeys: true)
    }

    func presentAcknowledgements() {
        present()
        preferencesViewController.navigate(to: .about, showAcknowledgements: true)
    }

    func exportCommandLogs() {
        present()
        preferencesViewController.exportCommandLogsFromMenu()
    }
}

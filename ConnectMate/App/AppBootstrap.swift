import Cocoa

final class AppBootstrap: NSObject {
    private let router = AppRouter()
    private let settings = AppSettings.shared
    private let databaseManager = DatabaseManager.shared
    private var mainWindowController: MainWindowController?

    func start() {
        NSApp.setActivationPolicy(.regular)
        _ = databaseManager
        AppThemeManager.shared.applyStoredPreference(settings: settings, application: NSApp)
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = makeMainMenu()
        }
        let controller = MainWindowController(router: router)
        mainWindowController = controller
        controller.showWindow(nil)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
        controller.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: L10n.Menu.about, action: nil, keyEquivalent: "")
        let preferencesItem = appMenu.addItem(withTitle: L10n.Menu.preferences, action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L10n.Menu.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return mainMenu
    }

    @objc
    private func openPreferences() {
        SettingsWindowController.shared.present()
    }
}

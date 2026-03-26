import Cocoa

final class AppBootstrap {
    private let router = AppRouter()
    private let settings = AppSettings.shared
    private var mainWindowController: MainWindowController?

    func start() {
        NSApp.setActivationPolicy(.regular)
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
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L10n.Menu.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return mainMenu
    }
}

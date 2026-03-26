import Cocoa

final class AppBootstrap {
    private let router = AppRouter()
    private var mainWindowController: MainWindowController?

    func start() {
        NSApp.setActivationPolicy(.regular)
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
        appMenu.addItem(withTitle: "About ConnectMate", action: nil, keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit ConnectMate", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return mainMenu
    }
}

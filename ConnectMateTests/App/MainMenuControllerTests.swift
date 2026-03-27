import AppKit
import Testing
@testable import ConnectMate

@MainActor
struct MainMenuControllerTests {
    @Test
    func buildsExpectedTopLevelMenus() {
        let controller = MainMenuController(
            settings: AppSettings(userDefaults: UserDefaults(suiteName: "ConnectMateTests.MainMenuControllerTests.topLevel")!),
            updateManager: StubUpdateManager(),
            showMainWindow: {},
            openPreferences: {},
            openAPIKeys: {},
            createApp: {},
            addVersion: {},
            exportAllData: {},
            exportCommandLogs: {},
            refreshCurrentPage: {},
            toggleSidebar: {},
            selectSection: { _ in }
        )

        let menu = controller.buildMainMenu()

        #expect(menu.items.count == 6)
        #expect(menu.items[1].title == L10n.Menu.file)
        #expect(menu.items[2].title == L10n.Menu.edit)
        #expect(menu.items[3].title == L10n.Menu.view)
        #expect(menu.items[4].title == L10n.Menu.window)
        #expect(menu.items[5].title == L10n.Menu.help)
    }

    @Test
    func includesModuleAndAppearanceCommandsInViewMenu() throws {
        let controller = MainMenuController(
            settings: AppSettings(userDefaults: UserDefaults(suiteName: "ConnectMateTests.MainMenuControllerTests.viewMenu")!),
            updateManager: StubUpdateManager(),
            showMainWindow: {},
            openPreferences: {},
            openAPIKeys: {},
            createApp: {},
            addVersion: {},
            exportAllData: {},
            exportCommandLogs: {},
            refreshCurrentPage: {},
            toggleSidebar: {},
            selectSection: { _ in }
        )

        let menu = controller.buildMainMenu()
        let viewMenu = try #require(menu.items[3].submenu)
        let itemTitles = viewMenu.items.map(\.title)

        #expect(itemTitles.contains(L10n.Menu.refreshCurrentPage))
        #expect(itemTitles.contains(L10n.Sidebar.apps))
        #expect(itemTitles.contains(L10n.Sidebar.builds))
        #expect(itemTitles.contains(L10n.Menu.themeSystem))
        #expect(itemTitles.contains(L10n.Menu.themeLight))
        #expect(itemTitles.contains(L10n.Menu.themeDark))
    }

    @Test
    func includesCreateCommandsInFileMenu() throws {
        let controller = MainMenuController(
            settings: AppSettings(userDefaults: UserDefaults(suiteName: "ConnectMateTests.MainMenuControllerTests.fileMenu")!),
            updateManager: StubUpdateManager(),
            showMainWindow: {},
            openPreferences: {},
            openAPIKeys: {},
            createApp: {},
            addVersion: {},
            exportAllData: {},
            exportCommandLogs: {},
            refreshCurrentPage: {},
            toggleSidebar: {},
            selectSection: { _ in }
        )

        let menu = controller.buildMainMenu()
        let fileMenu = try #require(menu.items[1].submenu)
        let itemTitles = fileMenu.items.map(\.title)

        #expect(itemTitles.contains(L10n.Menu.createApp))
        #expect(itemTitles.contains(L10n.Menu.addVersion))
    }

    @Test
    func createCommandsTriggerInjectedActions() throws {
        var didCreateApp = false
        var didAddVersion = false
        let controller = MainMenuController(
            settings: AppSettings(userDefaults: UserDefaults(suiteName: "ConnectMateTests.MainMenuControllerTests.createActions")!),
            updateManager: StubUpdateManager(),
            showMainWindow: {},
            openPreferences: {},
            openAPIKeys: {},
            createApp: {
                didCreateApp = true
            },
            addVersion: {
                didAddVersion = true
            },
            exportAllData: {},
            exportCommandLogs: {},
            refreshCurrentPage: {},
            toggleSidebar: {},
            selectSection: { _ in }
        )

        let menu = controller.buildMainMenu()
        let fileMenu = try #require(menu.items[1].submenu)
        let createAppItem = try #require(fileMenu.items.first(where: { $0.title == L10n.Menu.createApp }))
        let addVersionItem = try #require(fileMenu.items.first(where: { $0.title == L10n.Menu.addVersion }))

        _ = NSApp.sendAction(try #require(createAppItem.action), to: createAppItem.target, from: createAppItem)
        _ = NSApp.sendAction(try #require(addVersionItem.action), to: addVersionItem.target, from: addVersionItem)

        #expect(didCreateApp)
        #expect(didAddVersion)
    }
}

@MainActor
private final class StubUpdateManager: AppUpdateManaging {
    var canCheckForUpdates: Bool = true

    func configure() {}
    func scheduleBackgroundUpdateCheck() {}
    func checkForUpdates() {}
    func openRepository() {}
    func openIssues() {}
    func openCLIRepository() {}
}

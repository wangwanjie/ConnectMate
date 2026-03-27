import AppKit

#if DEBUG && canImport(ViewScopeServer)
import ViewScopeServer
#endif

@MainActor
final class MainMenuController: NSObject, NSMenuItemValidation {
    private enum MenuTag: Int {
        case apps = 100
        case builds
        case review
        case testFlight
        case iap
        case signing
        case logs
        case themeSystem = 200
        case themeLight
        case themeDark
    }

    private let settings: AppSettings
    private let updateManager: any AppUpdateManaging
    private let showMainWindow: () -> Void
    private let openPreferences: () -> Void
    private let openAPIKeys: () -> Void
    private let createApp: () -> Void
    private let addVersion: () -> Void
    private let exportAllData: () -> Void
    private let exportCommandLogs: () -> Void
    private let showAcknowledgements: () -> Void
    private let refreshCurrentPage: () -> Void
    private let toggleSidebar: () -> Void
    private let selectSection: (AppSection) -> Void
    private let currentSection: () -> AppSection?

    init(
        settings: AppSettings? = nil,
        updateManager: (any AppUpdateManaging)? = nil,
        showMainWindow: @escaping () -> Void,
        openPreferences: @escaping () -> Void,
        openAPIKeys: @escaping () -> Void,
        createApp: @escaping () -> Void,
        addVersion: @escaping () -> Void,
        exportAllData: @escaping () -> Void,
        exportCommandLogs: @escaping () -> Void,
        showAcknowledgements: @escaping () -> Void = {},
        refreshCurrentPage: @escaping () -> Void,
        toggleSidebar: @escaping () -> Void,
        selectSection: @escaping (AppSection) -> Void,
        currentSection: @escaping () -> AppSection? = { nil }
    ) {
        self.settings = settings ?? .shared
        self.updateManager = updateManager ?? AppUpdateManager.shared
        self.showMainWindow = showMainWindow
        self.openPreferences = openPreferences
        self.openAPIKeys = openAPIKeys
        self.createApp = createApp
        self.addVersion = addVersion
        self.exportAllData = exportAllData
        self.exportCommandLogs = exportCommandLogs
        self.showAcknowledgements = showAcknowledgements
        self.refreshCurrentPage = refreshCurrentPage
        self.toggleSidebar = toggleSidebar
        self.selectSection = selectSection
        self.currentSection = currentSection
    }

    func install() {
        NSApp.mainMenu = buildMainMenu()
    }

    func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(makeAppMenuItem())
        mainMenu.addItem(makeFileMenuItem())
        mainMenu.addItem(makeEditMenuItem())
        mainMenu.addItem(makeViewMenuItem())
        mainMenu.addItem(makeWindowMenuItem())
        mainMenu.addItem(makeHelpMenuItem())
        return mainMenu
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.tag {
        case MenuTag.apps.rawValue:
            menuItem.state = currentSection() == .apps ? .on : .off
        case MenuTag.builds.rawValue:
            menuItem.state = currentSection() == .builds ? .on : .off
        case MenuTag.review.rawValue:
            menuItem.state = currentSection() == .review ? .on : .off
        case MenuTag.testFlight.rawValue:
            menuItem.state = currentSection() == .testFlight ? .on : .off
        case MenuTag.iap.rawValue:
            menuItem.state = currentSection() == .iap ? .on : .off
        case MenuTag.logs.rawValue:
            menuItem.state = currentSection() == .logs ? .on : .off
        case MenuTag.themeSystem.rawValue:
            menuItem.state = settings.appearanceMode == .system ? .on : .off
        case MenuTag.themeLight.rawValue:
            menuItem.state = settings.appearanceMode == .light ? .on : .off
        case MenuTag.themeDark.rawValue:
            menuItem.state = settings.appearanceMode == .dark ? .on : .off
        default:
            break
        }

        if menuItem.action == #selector(checkForUpdates) {
            return updateManager.canCheckForUpdates
        }

        return true
    }

    private func makeAppMenuItem() -> NSMenuItem {
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: L10n.Menu.about, action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))

        let checkForUpdatesItem = NSMenuItem(title: L10n.Menu.checkForUpdates, action: #selector(checkForUpdates), keyEquivalent: "")
        checkForUpdatesItem.target = self
        appMenu.addItem(checkForUpdatesItem)

        appMenu.addItem(NSMenuItem.separator())

        let preferencesItem = NSMenuItem(title: L10n.Menu.preferences, action: #selector(openPreferencesWindow), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(preferencesItem)

        appMenu.addItem(NSMenuItem.separator())

        let servicesItem = NSMenuItem(title: L10n.Menu.services, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)

        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: L10n.Menu.hideApp, action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))

        let hideOthersItem = NSMenuItem(title: L10n.Menu.hideOthers, action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        appMenu.addItem(NSMenuItem(title: L10n.Menu.showAll, action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: L10n.Menu.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        appItem.submenu = appMenu
        return appItem
    }

    private func makeFileMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.Menu.file, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L10n.Menu.file)

        let createAppItem = NSMenuItem(title: L10n.Menu.createApp, action: #selector(createAppAction), keyEquivalent: "n")
        createAppItem.target = self
        menu.addItem(createAppItem)

        let addVersionItem = NSMenuItem(title: L10n.Menu.addVersion, action: #selector(addVersionAction), keyEquivalent: "N")
        addVersionItem.keyEquivalentModifierMask = [.command, .shift]
        addVersionItem.target = self
        menu.addItem(addVersionItem)

        menu.addItem(NSMenuItem.separator())

        let apiKeysItem = NSMenuItem(title: L10n.Menu.manageAPIKeys, action: #selector(openAPIKeysSheet), keyEquivalent: "k")
        apiKeysItem.keyEquivalentModifierMask = [.command, .shift]
        apiKeysItem.target = self
        menu.addItem(apiKeysItem)

        let exportDataItem = NSMenuItem(title: L10n.Menu.exportData, action: #selector(exportAllDataAction), keyEquivalent: "e")
        exportDataItem.keyEquivalentModifierMask = [.command, .shift]
        exportDataItem.target = self
        menu.addItem(exportDataItem)

        let exportLogsItem = NSMenuItem(title: L10n.Menu.exportCommandLogs, action: #selector(exportCommandLogsAction), keyEquivalent: "l")
        exportLogsItem.keyEquivalentModifierMask = [.command, .shift]
        exportLogsItem.target = self
        menu.addItem(exportLogsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.Menu.closeWindow, action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        item.submenu = menu
        return item
    }

    private func makeEditMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.Menu.edit, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L10n.Menu.edit)
        menu.addItem(NSMenuItem(title: L10n.Menu.undo, action: Selector(("undo:")), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: L10n.Menu.redo, action: Selector(("redo:")), keyEquivalent: "Z"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.Menu.cut, action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: L10n.Menu.copy, action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: L10n.Menu.paste, action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: L10n.Menu.pasteAndMatchStyle, action: #selector(NSTextView.pasteAsPlainText(_:)), keyEquivalent: "V"))
        menu.addItem(NSMenuItem(title: L10n.Menu.delete, action: #selector(NSText.delete(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.Menu.selectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        item.submenu = menu
        return item
    }

    private func makeViewMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.Menu.view, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L10n.Menu.view)

        let showMainWindowItem = NSMenuItem(title: L10n.Menu.showMainWindow, action: #selector(showMainWindowAction), keyEquivalent: "1")
        showMainWindowItem.target = self
        menu.addItem(showMainWindowItem)

        let toggleSidebarItem = NSMenuItem(title: L10n.Menu.toggleSidebar, action: #selector(toggleSidebarAction), keyEquivalent: "s")
        toggleSidebarItem.keyEquivalentModifierMask = [.command, .option]
        toggleSidebarItem.target = self
        menu.addItem(toggleSidebarItem)

        let refreshItem = NSMenuItem(title: L10n.Menu.refreshCurrentPage, action: #selector(refreshCurrentPageAction), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(sectionMenuItem(for: .apps, tag: .apps))
        menu.addItem(sectionMenuItem(for: .builds, tag: .builds))
        menu.addItem(sectionMenuItem(for: .review, tag: .review))
        menu.addItem(sectionMenuItem(for: .testFlight, tag: .testFlight))
        menu.addItem(sectionMenuItem(for: .iap, tag: .iap))
        menu.addItem(sectionMenuItem(for: .signing, tag: .signing))
        menu.addItem(sectionMenuItem(for: .logs, tag: .logs))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(themeMenuItem(title: L10n.Menu.themeSystem, mode: .system, tag: .themeSystem))
        menu.addItem(themeMenuItem(title: L10n.Menu.themeLight, mode: .light, tag: .themeLight))
        menu.addItem(themeMenuItem(title: L10n.Menu.themeDark, mode: .dark, tag: .themeDark))

        #if DEBUG && canImport(ViewScopeServer)
        menu.addItem(NSMenuItem.separator())
        let viewScopeItem = NSMenuItem(title: L10n.Menu.startViewScopeInspector, action: #selector(startViewScopeInspector), keyEquivalent: "")
        viewScopeItem.target = self
        menu.addItem(viewScopeItem)
        #endif

        item.submenu = menu
        return item
    }

    private func makeWindowMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.Menu.window, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L10n.Menu.window)
        menu.addItem(NSMenuItem(title: L10n.Menu.minimize, action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: L10n.Menu.zoom, action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.Menu.bringAllToFront, action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let showWindowItem = NSMenuItem(title: L10n.Menu.showMainWindow, action: #selector(showMainWindowAction), keyEquivalent: "0")
        showWindowItem.keyEquivalentModifierMask = [.command]
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        let preferencesItem = NSMenuItem(title: L10n.Menu.preferences, action: #selector(openPreferencesWindow), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        NSApp.windowsMenu = menu
        item.submenu = menu
        return item
    }

    private func makeHelpMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.Menu.help, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L10n.Menu.help)

        let repositoryItem = NSMenuItem(title: L10n.Menu.githubRepository, action: #selector(openRepository), keyEquivalent: "")
        repositoryItem.target = self
        menu.addItem(repositoryItem)

        let issuesItem = NSMenuItem(title: L10n.Menu.reportIssue, action: #selector(openIssues), keyEquivalent: "?")
        issuesItem.target = self
        menu.addItem(issuesItem)

        let cliRepositoryItem = NSMenuItem(title: L10n.Menu.ascCLIRepository, action: #selector(openCLIRepository), keyEquivalent: "")
        cliRepositoryItem.target = self
        menu.addItem(cliRepositoryItem)

        menu.addItem(NSMenuItem.separator())
        let acknowledgementsItem = NSMenuItem(title: L10n.Menu.acknowledgements, action: #selector(showAcknowledgementsAction), keyEquivalent: "")
        acknowledgementsItem.target = self
        menu.addItem(acknowledgementsItem)

        NSApp.helpMenu = menu
        item.submenu = menu
        return item
    }

    private func sectionMenuItem(for section: AppSection, tag: MenuTag) -> NSMenuItem {
        let item = NSMenuItem(title: section.title, action: #selector(selectAppSection(_:)), keyEquivalent: "")
        item.tag = tag.rawValue
        item.target = self
        item.representedObject = section.rawValue
        return item
    }

    private func themeMenuItem(title: String, mode: AppearanceMode, tag: MenuTag) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(selectThemeMode(_:)), keyEquivalent: "")
        item.tag = tag.rawValue
        item.target = self
        item.representedObject = mode.rawValue
        return item
    }

    @objc private func openPreferencesWindow() { openPreferences() }
    @objc private func openAPIKeysSheet() { openAPIKeys() }
    @objc private func createAppAction() { createApp() }
    @objc private func addVersionAction() { addVersion() }
    @objc private func exportAllDataAction() { exportAllData() }
    @objc private func exportCommandLogsAction() { exportCommandLogs() }
    @objc private func showMainWindowAction() { showMainWindow() }
    @objc private func toggleSidebarAction() { toggleSidebar() }
    @objc private func refreshCurrentPageAction() { refreshCurrentPage() }
    @objc private func checkForUpdates() { updateManager.checkForUpdates() }
    @objc private func openRepository() { updateManager.openRepository() }
    @objc private func openIssues() { updateManager.openIssues() }
    @objc private func openCLIRepository() { updateManager.openCLIRepository() }
    @objc private func showAcknowledgementsAction() { showAcknowledgements() }

    @objc
    private func selectAppSection(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let section = AppSection(rawValue: rawValue)
        else {
            return
        }

        selectSection(section)
    }

    @objc
    private func selectThemeMode(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let mode = AppearanceMode(rawValue: rawValue)
        else {
            return
        }

        settings.appearanceMode = mode
        AppThemeManager.shared.applyStoredPreference(settings: settings, application: NSApp)
    }

    #if DEBUG && canImport(ViewScopeServer)
    @objc
    private func startViewScopeInspector() {
        ViewScopeInspector.start()
    }
    #endif
}

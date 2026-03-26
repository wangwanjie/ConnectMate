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

        Task { @MainActor in
            let controller = MainWindowController(router: router)
            mainWindowController = controller

            let route = await resolveLaunchRoute()
            if case .onboarding(let state) = route {
                controller.window?.contentViewController = CLISetupViewController(state: state)
            }

            controller.showWindow(nil)
            controller.window?.center()
            controller.window?.makeKeyAndOrderFront(nil)
            controller.window?.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }
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

    private func resolveLaunchRoute() async -> LaunchRoute {
        let environment = ProcessInfo.processInfo.environment
        let isUITestMode = environment["CONNECTMATE_UI_TEST_MODE"] == "1"
        let overriddenCLIPath = environment["CONNECTMATE_UI_TEST_CLI_PATH"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveCLIPath = overriddenCLIPath?.isEmpty == false ? overriddenCLIPath! : settings.cliPath

        guard FileManager.default.fileExists(atPath: effectiveCLIPath),
              FileManager.default.isExecutableFile(atPath: effectiveCLIPath) else {
            return .onboarding(
                CLISetupState(
                    mode: .missingCLI,
                    cliPath: effectiveCLIPath,
                    cliVersion: nil,
                    message: L10n.Onboarding.missingCLIMessage
                )
            )
        }

        let commandConfiguration = ASCCommandConfiguration(
            settings: settings,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )
        let runner = ASCCommandRunner(configuration: commandConfiguration, logRepository: databaseManager.commandLogRepository)
        let versionResult = try? await runner.run(arguments: ["version"])
        let cliVersion = versionResult?.combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines)

        let shouldBypassCredentialOnboarding = isUITestMode && overriddenCLIPath == nil
        guard !shouldBypassCredentialOnboarding else {
            return .main
        }

        let apiKeyService = APIKeyService(runner: runner, dbWriter: databaseManager.dbQueue)
        let profiles = (try? apiKeyService.fetchProfiles()) ?? []
        guard profiles.isEmpty else {
            return .main
        }

        return .onboarding(
            CLISetupState(
                mode: .missingCredentials,
                cliPath: effectiveCLIPath,
                cliVersion: cliVersion,
                message: L10n.Onboarding.missingCredentialsMessage
            )
        )
    }
}

private enum LaunchRoute {
    case main
    case onboarding(CLISetupState)
}

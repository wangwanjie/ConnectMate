import Cocoa

final class AppBootstrap: NSObject {
    private let router = AppRouter()
    private let settings = AppSettings.shared
    private let databaseManager = DatabaseManager.shared
    private let updateManager: any AppUpdateManaging = AppUpdateManager.shared
    private let dataExportService = AppDataExportService()
    private var mainWindowController: MainWindowController?
    private var mainMenuController: MainMenuController?

    func start() {
        let environment = ProcessInfo.processInfo.environment
        let isUITestMode = environment["CONNECTMATE_UI_TEST_MODE"] == "1"
        let isRunningHostedTests = environment["XCTestConfigurationFilePath"] != nil

        guard !isRunningHostedTests || isUITestMode else {
            return
        }

        NSApp.setActivationPolicy(.regular)
        _ = databaseManager
        updateManager.configure()
        AppThemeManager.shared.applyStoredPreference(settings: settings, application: NSApp)
        installMainMenu()

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
            self.updateManager.scheduleBackgroundUpdateCheck()
        }
    }

    private func installMainMenu() {
        let controller = MainMenuController(
            settings: settings,
            updateManager: updateManager,
            showMainWindow: { [weak self] in
                self?.showMainWindow()
            },
            openPreferences: { [weak self] in
                self?.openPreferences()
            },
            openAPIKeys: { [weak self] in
                self?.openAPIKeys()
            },
            exportAllData: { [weak self] in
                self?.exportAllData()
            },
            exportCommandLogs: { [weak self] in
                self?.exportCommandLogs()
            },
            showAcknowledgements: { [weak self] in
                self?.showAcknowledgements()
            },
            refreshCurrentPage: { [weak self] in
                self?.mainWindowController?.refreshCurrentPage()
            },
            toggleSidebar: { [weak self] in
                self?.mainWindowController?.toggleSidebar()
            },
            selectSection: { [weak self] section in
                self?.showMainWindow()
                self?.mainWindowController?.select(section: section)
            },
            currentSection: { [weak self] in
                self?.mainWindowController?.currentSection
            }
        )
        controller.install()
        mainMenuController = controller
    }

    @objc
    private func openPreferences() {
        SettingsWindowController.shared.present()
    }

    private func openAPIKeys() {
        SettingsWindowController.shared.presentAPIKeys()
    }

    private func showAcknowledgements() {
        SettingsWindowController.shared.presentAcknowledgements()
    }

    private func showMainWindow() {
        guard let window = mainWindowController?.window else {
            return
        }

        mainWindowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func exportAllData() {
        do {
            let url = try dataExportService.exportAllData()
            presentInfoAlert(title: L10n.Settings.Data.exportData, message: url.path)
        } catch {
            presentInfoAlert(title: L10n.Settings.Data.exportData, message: error.localizedDescription)
        }
    }

    private func exportCommandLogs() {
        do {
            let url = try dataExportService.exportCommandLogs()
            presentInfoAlert(title: L10n.Menu.exportCommandLogs, message: url.path)
        } catch {
            presentInfoAlert(title: L10n.Menu.exportCommandLogs, message: error.localizedDescription)
        }
    }

    private func presentInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.Common.ok)
        if let window = NSApp.keyWindow ?? mainWindowController?.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
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
            cliPath: effectiveCLIPath,
            timeout: TimeInterval(settings.commandTimeout),
            retryCount: settings.apiRetryCount,
            proxyURL: settings.proxyEnabled ? settings.proxyURL : nil,
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

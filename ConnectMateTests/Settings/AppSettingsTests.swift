import Foundation
import Testing
@testable import ConnectMate

struct AppSettingsTests {
    @Test
    func persistsAppearanceAndCliPreferences() throws {
        let suiteName = "ConnectMateTests.AppSettingsTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        settings.appearanceMode = .dark
        settings.preferredLanguage = .english
        settings.cliPath = "/opt/homebrew/bin/asc"
        settings.commandTimeout = 45

        let reloaded = AppSettings(userDefaults: defaults)
        #expect(reloaded.appearanceMode == .dark)
        #expect(reloaded.preferredLanguage == .english)
        #expect(reloaded.cliPath == "/opt/homebrew/bin/asc")
        #expect(reloaded.commandTimeout == 45)
    }

    @Test
    func providesExpectedDefaults() throws {
        let suiteName = "ConnectMateTests.AppSettingsTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        #expect(settings.appearanceMode == .system)
        #expect(settings.preferredLanguage == .system)
        #expect(settings.cliPath == "/usr/local/bin/asc")
        #expect(settings.commandTimeout == 30)
    }

    @Test
    func postsChangeNotificationsForUpdatedValues() throws {
        let suiteName = "ConnectMateTests.AppSettingsTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(userDefaults: defaults)
        var notifications: [String] = []
        let token = NotificationCenter.default.addObserver(
            forName: AppSettings.didChangeNotification,
            object: settings,
            queue: nil
        ) { notification in
            if let key = notification.userInfo?[AppSettings.changedKeyUserInfoKey] as? String {
                notifications.append(key)
            }
        }
        defer { NotificationCenter.default.removeObserver(token) }

        settings.sidebarItemStyle = .iconOnly
        settings.listRowDensity = .spacious
        settings.cliPath = "/opt/homebrew/bin/asc"

        #expect(notifications == [
            SettingKey.sidebarItemStyle.rawValue,
            SettingKey.listRowDensity.rawValue,
            SettingKey.cliPath.rawValue
        ])
    }
}

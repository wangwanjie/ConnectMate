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
        settings.cliPath = "/opt/homebrew/bin/asc"
        settings.commandTimeout = 45

        let reloaded = AppSettings(userDefaults: defaults)
        #expect(reloaded.appearanceMode == .dark)
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
        #expect(settings.cliPath == "/usr/local/bin/asc")
        #expect(settings.commandTimeout == 30)
    }
}

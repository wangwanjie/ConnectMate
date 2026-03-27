import Foundation
import Testing
@testable import ConnectMate

struct LocalizationManagerTests {
    @Test
    func resolvesStringsForExplicitLanguages() throws {
        let suiteName = "ConnectMateTests.LocalizationManagerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let manager = LocalizationManager(settings: settings, mainBundle: .main)

        settings.preferredLanguage = .english
        #expect(manager.localizedString(forKey: "sidebar.apps") == "My Apps")

        settings.preferredLanguage = .simplifiedChinese
        #expect(manager.localizedString(forKey: "sidebar.apps") == "我的 App")

        settings.preferredLanguage = .traditionalChinese
        #expect(manager.localizedString(forKey: "sidebar.apps") == "我的 App")
    }
}

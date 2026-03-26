import Foundation

enum L10n {
    static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    enum App {
        static var name: String { tr("app.name") }
    }

    enum Menu {
        static var about: String { tr("menu.about") }
        static var preferences: String { tr("menu.preferences") }
        static var quit: String { tr("menu.quit") }
    }

    enum Sidebar {
        static var apps: String { tr("sidebar.apps") }
        static var builds: String { tr("sidebar.builds") }
        static var review: String { tr("sidebar.review") }
        static var testFlight: String { tr("sidebar.testflight") }
        static var iap: String { tr("sidebar.iap") }
        static var settings: String { tr("sidebar.settings") }
        static var logs: String { tr("sidebar.logs") }
    }

    enum Settings {
        enum Section {
            static var general: String { tr("settings.section.general") }
            static var appearance: String { tr("settings.section.appearance") }
            static var notifications: String { tr("settings.section.notifications") }
            static var cliAndAPI: String { tr("settings.section.cliAndAPI") }
            static var dataAndCache: String { tr("settings.section.dataAndCache") }
            static var updates: String { tr("settings.section.updates") }
            static var shortcuts: String { tr("settings.section.shortcuts") }
            static var about: String { tr("settings.section.about") }
        }

        enum General {
            static var startAtLogin: String { tr("settings.general.startAtLogin") }
            static var autoRefreshOnLaunch: String { tr("settings.general.autoRefreshOnLaunch") }
            static var defaultLaunchSection: String { tr("settings.general.defaultLaunchSection") }
            static var requiresConfirmation: String { tr("settings.general.requiresConfirmation") }
        }

        enum Appearance {
            static var themeMode: String { tr("settings.appearance.themeMode") }
            static var sidebarStyle: String { tr("settings.appearance.sidebarStyle") }
            static var listDensity: String { tr("settings.appearance.listDensity") }
        }

        enum Notifications {
            static var reviewStatus: String { tr("settings.notifications.reviewStatus") }
            static var buildProcessing: String { tr("settings.notifications.buildProcessing") }
            static var testerAcceptance: String { tr("settings.notifications.testerAcceptance") }
            static var deliveryMode: String { tr("settings.notifications.deliveryMode") }
        }

        enum CLI {
            static var cliPath: String { tr("settings.cli.cliPath") }
            static var commandTimeout: String { tr("settings.cli.commandTimeout") }
            static var retryCount: String { tr("settings.cli.retryCount") }
            static var proxyEnabled: String { tr("settings.cli.proxyEnabled") }
            static var proxyURL: String { tr("settings.cli.proxyURL") }
            static var manageAPIKeys: String { tr("settings.cli.manageAPIKeys") }
        }

        enum Data {
            static var cachePolicy: String { tr("settings.data.cachePolicy") }
            static var clearCache: String { tr("settings.data.clearCache") }
            static var cacheCleared: String { tr("settings.data.cacheCleared") }
            static var logRetention: String { tr("settings.data.logRetention") }
            static var exportData: String { tr("settings.data.exportData") }
        }

        enum Updates {
            static var autoCheck: String { tr("settings.updates.autoCheck") }
            static var frequency: String { tr("settings.updates.frequency") }
            static var channel: String { tr("settings.updates.channel") }
            static var checkNow: String { tr("settings.updates.checkNow") }
            static var sparklePending: String { tr("settings.updates.sparklePending") }
        }

        enum Shortcuts {
            static var globalShortcut: String { tr("settings.shortcuts.globalShortcut") }
            static var refreshCurrentPage: String { tr("settings.shortcuts.refreshCurrentPage") }
            static var newTask: String { tr("settings.shortcuts.newTask") }
            static var toggleAppearance: String { tr("settings.shortcuts.toggleAppearance") }
            static var conflictHint: String { tr("settings.shortcuts.conflictHint") }
            static var notConfigured: String { tr("settings.shortcuts.notConfigured") }
            static var record: String { tr("settings.shortcuts.record") }
            static var stop: String { tr("settings.shortcuts.stop") }
        }

        enum About {
            static func versionLine(_ version: String, _ build: String) -> String {
                String(format: tr("settings.about.versionLine"), version, build)
            }

            static var license: String { tr("settings.about.license") }
            static var checkUpdates: String { tr("settings.about.checkUpdates") }
            static var feedback: String { tr("settings.about.feedback") }
            static var feedbackMessage: String { tr("settings.about.feedbackMessage") }
            static var acknowledgements: String { tr("settings.about.acknowledgements") }
        }

        enum AppearanceMode {
            static var system: String { tr("settings.appearance.system") }
            static var light: String { tr("settings.appearance.light") }
            static var dark: String { tr("settings.appearance.dark") }
        }

        enum SidebarItemStyle {
            static var iconOnly: String { tr("settings.sidebarStyle.iconOnly") }
            static var iconAndText: String { tr("settings.sidebarStyle.iconAndText") }
        }

        enum ListRowDensity {
            static var compact: String { tr("settings.listDensity.compact") }
            static var standard: String { tr("settings.listDensity.standard") }
            static var spacious: String { tr("settings.listDensity.spacious") }
        }

        enum NotificationDeliveryMode {
            static var system: String { tr("settings.notificationMode.system") }
            static var toast: String { tr("settings.notificationMode.toast") }
            static var both: String { tr("settings.notificationMode.both") }
        }

        enum CachePolicy {
            static var disabled: String { tr("settings.cache.disabled") }
            static var fiveMinutes: String { tr("settings.cache.fiveMinutes") }
            static var thirtyMinutes: String { tr("settings.cache.thirtyMinutes") }
            static var oneHour: String { tr("settings.cache.oneHour") }
            static var manualRefresh: String { tr("settings.cache.manualRefresh") }
        }

        enum UpdateCheckFrequency {
            static var launch: String { tr("settings.updates.launch") }
            static var daily: String { tr("settings.updates.daily") }
            static var weekly: String { tr("settings.updates.weekly") }
        }

        enum UpdateChannel {
            static var stable: String { tr("settings.channel.stable") }
            static var beta: String { tr("settings.channel.beta") }
        }

        enum LogRetention {
            static var days7: String { tr("settings.logs.days7") }
            static var days30: String { tr("settings.logs.days30") }
            static var days90: String { tr("settings.logs.days90") }
            static var forever: String { tr("settings.logs.forever") }
        }
    }

    enum Modules {
        static var listDescription: String { tr("modules.listDescription") }
        static var detailDescription: String { tr("modules.detailDescription") }
    }

    enum Apps {
        static var title: String { tr("apps.title") }
        static var searchPlaceholder: String { tr("apps.searchPlaceholder") }
        static var refresh: String { tr("apps.refresh") }
        static var loading: String { tr("apps.loading") }
        static var emptyTitle: String { tr("apps.emptyTitle") }
        static var emptyDetail: String { tr("apps.emptyDetail") }
        static var bundleID: String { tr("apps.bundleID") }
        static var platform: String { tr("apps.platform") }
        static var state: String { tr("apps.state") }
        static var sku: String { tr("apps.sku") }
        static var appID: String { tr("apps.appID") }
        static var cachedAt: String { tr("apps.cachedAt") }
        static var noSelectionTitle: String { tr("apps.noSelectionTitle") }
        static var noSelectionDetail: String { tr("apps.noSelectionDetail") }
        static var unavailable: String { tr("apps.unavailable") }
        static var loadFailed: String { tr("apps.loadFailed") }
    }

    enum Tasking {
        static var noActiveTasks: String { tr("tasking.noActiveTasks") }
        static var activeTaskCount: String { tr("tasking.activeTaskCount") }
    }

    enum Common {
        static var browse: String { tr("common.browse") }
        static var save: String { tr("common.save") }
        static var delete: String { tr("common.delete") }
        static var validate: String { tr("common.validate") }
        static var activate: String { tr("common.activate") }
        static var close: String { tr("common.close") }
    }

    enum APIKeys {
        static var title: String { tr("apikeys.title") }
        static var profileName: String { tr("apikeys.profileName") }
        static var issuerID: String { tr("apikeys.issuerID") }
        static var keyID: String { tr("apikeys.keyID") }
        static var privateKeyPath: String { tr("apikeys.privateKeyPath") }
        static var validationSucceeded: String { tr("apikeys.validationSucceeded") }
        static var dragHint: String { tr("apikeys.dragHint") }
        static var emptyState: String { tr("apikeys.emptyState") }
        static var deleteConfirm: String { tr("apikeys.deleteConfirm") }
        static var validationFailed: String { tr("apikeys.validationFailed") }
        static var saved: String { tr("apikeys.saved") }
        static var active: String { tr("apikeys.active") }
        static var statusChecking: String { tr("apikeys.statusChecking") }
    }

    enum Onboarding {
        static var title: String { tr("onboarding.title") }
        static var missingCLIMessage: String { tr("onboarding.missingCLIMessage") }
        static var missingCredentialsMessage: String { tr("onboarding.missingCredentialsMessage") }
        static var cliPath: String { tr("onboarding.cliPath") }
        static var cliVersion: String { tr("onboarding.cliVersion") }
        static var openPreferences: String { tr("onboarding.openPreferences") }
        static var configureAPIKey: String { tr("onboarding.configureAPIKey") }
        static var noVersion: String { tr("onboarding.noVersion") }
    }
}

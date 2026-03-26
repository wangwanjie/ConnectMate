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

    enum Tasking {
        static var noActiveTasks: String { tr("tasking.noActiveTasks") }
        static var activeTaskCount: String { tr("tasking.activeTaskCount") }
    }

    enum Common {
        static var browse: String { tr("common.browse") }
    }
}

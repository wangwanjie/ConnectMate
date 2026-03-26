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
}

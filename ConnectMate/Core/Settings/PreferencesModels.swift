import Foundation

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var localizedTitle: String {
        switch self {
        case .system:
            return L10n.Settings.AppearanceMode.system
        case .light:
            return L10n.Settings.AppearanceMode.light
        case .dark:
            return L10n.Settings.AppearanceMode.dark
        }
    }
}

enum SidebarItemStyle: String, CaseIterable {
    case iconOnly
    case iconAndText

    var localizedTitle: String {
        switch self {
        case .iconOnly:
            return L10n.Settings.SidebarItemStyle.iconOnly
        case .iconAndText:
            return L10n.Settings.SidebarItemStyle.iconAndText
        }
    }
}

enum ListRowDensity: String, CaseIterable {
    case compact
    case standard
    case spacious

    var localizedTitle: String {
        switch self {
        case .compact:
            return L10n.Settings.ListRowDensity.compact
        case .standard:
            return L10n.Settings.ListRowDensity.standard
        case .spacious:
            return L10n.Settings.ListRowDensity.spacious
        }
    }
}

enum NotificationDeliveryMode: String, CaseIterable {
    case system
    case toast
    case both

    var localizedTitle: String {
        switch self {
        case .system:
            return L10n.Settings.NotificationDeliveryMode.system
        case .toast:
            return L10n.Settings.NotificationDeliveryMode.toast
        case .both:
            return L10n.Settings.NotificationDeliveryMode.both
        }
    }
}

enum CachePolicy: String, CaseIterable {
    case disabled
    case fiveMinutes
    case thirtyMinutes
    case oneHour
    case manualRefresh

    var localizedTitle: String {
        switch self {
        case .disabled:
            return L10n.Settings.CachePolicy.disabled
        case .fiveMinutes:
            return L10n.Settings.CachePolicy.fiveMinutes
        case .thirtyMinutes:
            return L10n.Settings.CachePolicy.thirtyMinutes
        case .oneHour:
            return L10n.Settings.CachePolicy.oneHour
        case .manualRefresh:
            return L10n.Settings.CachePolicy.manualRefresh
        }
    }
}

enum UpdateCheckFrequency: String, CaseIterable {
    case launch
    case daily
    case weekly

    var localizedTitle: String {
        switch self {
        case .launch:
            return L10n.Settings.UpdateCheckFrequency.launch
        case .daily:
            return L10n.Settings.UpdateCheckFrequency.daily
        case .weekly:
            return L10n.Settings.UpdateCheckFrequency.weekly
        }
    }
}

enum UpdateChannel: String, CaseIterable {
    case stable
    case beta

    var localizedTitle: String {
        switch self {
        case .stable:
            return L10n.Settings.UpdateChannel.stable
        case .beta:
            return L10n.Settings.UpdateChannel.beta
        }
    }
}

enum DefaultLaunchSection: String, CaseIterable {
    case apps
    case builds
    case review
    case testFlight
    case iap
    case settings
    case logs

    var localizedTitle: String {
        switch self {
        case .apps:
            return L10n.Sidebar.apps
        case .builds:
            return L10n.Sidebar.builds
        case .review:
            return L10n.Sidebar.review
        case .testFlight:
            return L10n.Sidebar.testFlight
        case .iap:
            return L10n.Sidebar.iap
        case .settings:
            return L10n.Sidebar.settings
        case .logs:
            return L10n.Sidebar.logs
        }
    }
}

enum LogRetentionPolicy: String, CaseIterable {
    case days7
    case days30
    case days90
    case forever

    var localizedTitle: String {
        switch self {
        case .days7:
            return L10n.Settings.LogRetention.days7
        case .days30:
            return L10n.Settings.LogRetention.days30
        case .days90:
            return L10n.Settings.LogRetention.days90
        case .forever:
            return L10n.Settings.LogRetention.forever
        }
    }
}

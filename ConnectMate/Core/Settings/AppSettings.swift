import Foundation

final class AppSettings {
    static let shared = AppSettings()

    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var appearanceMode: AppearanceMode {
        get { enumValue(for: .appearanceMode, default: .system) }
        set { set(newValue, for: .appearanceMode) }
    }

    var startAtLogin: Bool {
        get { boolValue(for: .startAtLogin, default: false) }
        set { userDefaults.set(newValue, forKey: SettingKey.startAtLogin.rawValue) }
    }

    var autoRefreshOnLaunch: Bool {
        get { boolValue(for: .autoRefreshOnLaunch, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.autoRefreshOnLaunch.rawValue) }
    }

    var defaultLaunchSection: DefaultLaunchSection {
        get { enumValue(for: .defaultLaunchSection, default: .apps) }
        set { set(newValue, for: .defaultLaunchSection) }
    }

    var requiresActionConfirmation: Bool {
        get { boolValue(for: .requiresActionConfirmation, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.requiresActionConfirmation.rawValue) }
    }

    var sidebarItemStyle: SidebarItemStyle {
        get { enumValue(for: .sidebarItemStyle, default: .iconAndText) }
        set { set(newValue, for: .sidebarItemStyle) }
    }

    var listRowDensity: ListRowDensity {
        get { enumValue(for: .listRowDensity, default: .standard) }
        set { set(newValue, for: .listRowDensity) }
    }

    var reviewStatusNotifications: Bool {
        get { boolValue(for: .reviewStatusNotifications, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.reviewStatusNotifications.rawValue) }
    }

    var buildProcessingNotifications: Bool {
        get { boolValue(for: .buildProcessingNotifications, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.buildProcessingNotifications.rawValue) }
    }

    var testerAcceptanceNotifications: Bool {
        get { boolValue(for: .testerAcceptanceNotifications, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.testerAcceptanceNotifications.rawValue) }
    }

    var notificationDeliveryMode: NotificationDeliveryMode {
        get { enumValue(for: .notificationDeliveryMode, default: .both) }
        set { set(newValue, for: .notificationDeliveryMode) }
    }

    var cliPath: String {
        get { stringValue(for: .cliPath, default: "/usr/local/bin/asc") }
        set { userDefaults.set(newValue, forKey: SettingKey.cliPath.rawValue) }
    }

    var commandTimeout: Int {
        get { intValue(for: .commandTimeout, default: 30) }
        set { userDefaults.set(max(1, newValue), forKey: SettingKey.commandTimeout.rawValue) }
    }

    var apiRetryCount: Int {
        get { intValue(for: .apiRetryCount, default: 3) }
        set { userDefaults.set(min(max(1, newValue), 5), forKey: SettingKey.apiRetryCount.rawValue) }
    }

    var proxyEnabled: Bool {
        get { boolValue(for: .proxyEnabled, default: false) }
        set { userDefaults.set(newValue, forKey: SettingKey.proxyEnabled.rawValue) }
    }

    var proxyURL: String {
        get { stringValue(for: .proxyURL, default: "") }
        set { userDefaults.set(newValue, forKey: SettingKey.proxyURL.rawValue) }
    }

    var cachePolicy: CachePolicy {
        get { enumValue(for: .cachePolicy, default: .thirtyMinutes) }
        set { set(newValue, for: .cachePolicy) }
    }

    var logRetention: LogRetentionPolicy {
        get { enumValue(for: .logRetention, default: .days30) }
        set { set(newValue, for: .logRetention) }
    }

    var autoCheckUpdates: Bool {
        get { boolValue(for: .autoCheckUpdates, default: true) }
        set { userDefaults.set(newValue, forKey: SettingKey.autoCheckUpdates.rawValue) }
    }

    var updateCheckFrequency: UpdateCheckFrequency {
        get { enumValue(for: .updateCheckFrequency, default: .launch) }
        set { set(newValue, for: .updateCheckFrequency) }
    }

    var updateChannel: UpdateChannel {
        get { enumValue(for: .updateChannel, default: .stable) }
        set { set(newValue, for: .updateChannel) }
    }

    var globalHotkey: String {
        get { stringValue(for: .globalHotkey, default: "") }
        set { userDefaults.set(newValue, forKey: SettingKey.globalHotkey.rawValue) }
    }

    var refreshShortcut: String {
        get { stringValue(for: .refreshShortcut, default: "cmd+r") }
        set { userDefaults.set(newValue, forKey: SettingKey.refreshShortcut.rawValue) }
    }

    var newTaskShortcut: String {
        get { stringValue(for: .newTaskShortcut, default: "cmd+n") }
        set { userDefaults.set(newValue, forKey: SettingKey.newTaskShortcut.rawValue) }
    }

    var toggleAppearanceShortcut: String {
        get { stringValue(for: .toggleAppearanceShortcut, default: "cmd+shift+l") }
        set { userDefaults.set(newValue, forKey: SettingKey.toggleAppearanceShortcut.rawValue) }
    }

    private func boolValue(for key: SettingKey, default defaultValue: Bool) -> Bool {
        if userDefaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return userDefaults.bool(forKey: key.rawValue)
    }

    private func intValue(for key: SettingKey, default defaultValue: Int) -> Int {
        if userDefaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return userDefaults.integer(forKey: key.rawValue)
    }

    private func stringValue(for key: SettingKey, default defaultValue: String) -> String {
        userDefaults.string(forKey: key.rawValue) ?? defaultValue
    }

    private func enumValue<Value: RawRepresentable>(for key: SettingKey, default defaultValue: Value) -> Value where Value.RawValue == String {
        guard
            let rawValue = userDefaults.string(forKey: key.rawValue),
            let value = Value(rawValue: rawValue)
        else {
            return defaultValue
        }

        return value
    }

    private func set<Value: RawRepresentable>(_ value: Value, for key: SettingKey) where Value.RawValue == String {
        userDefaults.set(value.rawValue, forKey: key.rawValue)
    }
}

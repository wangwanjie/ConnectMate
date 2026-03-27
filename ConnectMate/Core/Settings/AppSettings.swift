import Foundation

final class AppSettings {
    static let shared = AppSettings()
    static let didChangeNotification = Notification.Name("ConnectMate.AppSettings.didChange")
    static let changedKeyUserInfoKey = "key"
    static let changedValueUserInfoKey = "value"

    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var appearanceMode: AppearanceMode {
        get { enumValue(for: .appearanceMode, default: .system) }
        set { set(newValue, for: .appearanceMode) }
    }

    var preferredLanguage: AppLanguage {
        get { enumValue(for: .preferredLanguage, default: .system) }
        set { set(newValue, for: .preferredLanguage) }
    }

    var startAtLogin: Bool {
        get { boolValue(for: .startAtLogin, default: false) }
        set { set(newValue, for: .startAtLogin) }
    }

    var autoRefreshOnLaunch: Bool {
        get { boolValue(for: .autoRefreshOnLaunch, default: true) }
        set { set(newValue, for: .autoRefreshOnLaunch) }
    }

    var defaultLaunchSection: DefaultLaunchSection {
        get { enumValue(for: .defaultLaunchSection, default: .apps) }
        set { set(newValue, for: .defaultLaunchSection) }
    }

    var requiresActionConfirmation: Bool {
        get { boolValue(for: .requiresActionConfirmation, default: true) }
        set { set(newValue, for: .requiresActionConfirmation) }
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
        set { set(newValue, for: .reviewStatusNotifications) }
    }

    var buildProcessingNotifications: Bool {
        get { boolValue(for: .buildProcessingNotifications, default: true) }
        set { set(newValue, for: .buildProcessingNotifications) }
    }

    var testerAcceptanceNotifications: Bool {
        get { boolValue(for: .testerAcceptanceNotifications, default: true) }
        set { set(newValue, for: .testerAcceptanceNotifications) }
    }

    var notificationDeliveryMode: NotificationDeliveryMode {
        get { enumValue(for: .notificationDeliveryMode, default: .both) }
        set { set(newValue, for: .notificationDeliveryMode) }
    }

    var cliPath: String {
        get { stringValue(for: .cliPath, default: "/usr/local/bin/asc") }
        set { set(newValue, for: .cliPath) }
    }

    var commandTimeout: Int {
        get { intValue(for: .commandTimeout, default: 30) }
        set { set(max(1, newValue), for: .commandTimeout) }
    }

    var apiRetryCount: Int {
        get { intValue(for: .apiRetryCount, default: 3) }
        set { set(min(max(1, newValue), 5), for: .apiRetryCount) }
    }

    var proxyEnabled: Bool {
        get { boolValue(for: .proxyEnabled, default: false) }
        set { set(newValue, for: .proxyEnabled) }
    }

    var proxyURL: String {
        get { stringValue(for: .proxyURL, default: "") }
        set { set(newValue, for: .proxyURL) }
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
        set { set(newValue, for: .autoCheckUpdates) }
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
        set { set(newValue, for: .globalHotkey) }
    }

    var refreshShortcut: String {
        get { stringValue(for: .refreshShortcut, default: "cmd+r") }
        set { set(newValue, for: .refreshShortcut) }
    }

    var newTaskShortcut: String {
        get { stringValue(for: .newTaskShortcut, default: "cmd+n") }
        set { set(newValue, for: .newTaskShortcut) }
    }

    var toggleAppearanceShortcut: String {
        get { stringValue(for: .toggleAppearanceShortcut, default: "cmd+shift+l") }
        set { set(newValue, for: .toggleAppearanceShortcut) }
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
        postChange(for: key, value: value.rawValue)
    }

    private func set(_ value: Bool, for key: SettingKey) {
        userDefaults.set(value, forKey: key.rawValue)
        postChange(for: key, value: value)
    }

    private func set(_ value: Int, for key: SettingKey) {
        userDefaults.set(value, forKey: key.rawValue)
        postChange(for: key, value: value)
    }

    private func set(_ value: String, for key: SettingKey) {
        userDefaults.set(value, forKey: key.rawValue)
        postChange(for: key, value: value)
    }

    private func postChange(for key: SettingKey, value: Any) {
        NotificationCenter.default.post(
            name: Self.didChangeNotification,
            object: self,
            userInfo: [
                Self.changedKeyUserInfoKey: key.rawValue,
                Self.changedValueUserInfoKey: value
            ]
        )
    }
}

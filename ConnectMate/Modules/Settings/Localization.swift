import Foundation

enum L10n {
    static func tr(_ key: String) -> String {
        LocalizationManager.shared.localizedString(forKey: key)
    }

    enum App {
        static var name: String { tr("app.name") }
    }

    enum Menu {
        static var about: String { tr("menu.about") }
        static var checkForUpdates: String { tr("menu.checkUpdates") }
        static var preferences: String { tr("menu.preferences") }
        static var quit: String { tr("menu.quit") }
        static var file: String { tr("menu.file") }
        static var createApp: String { tr("menu.createApp") }
        static var addVersion: String { tr("menu.addVersion") }
        static var edit: String { tr("menu.edit") }
        static var view: String { tr("menu.view") }
        static var window: String { tr("menu.window") }
        static var help: String { tr("menu.help") }
        static var services: String { tr("menu.services") }
        static var hideApp: String { tr("menu.hideApp") }
        static var hideOthers: String { tr("menu.hideOthers") }
        static var showAll: String { tr("menu.showAll") }
        static var manageAPIKeys: String { tr("menu.manageAPIKeys") }
        static var exportData: String { tr("menu.exportData") }
        static var exportCommandLogs: String { tr("menu.exportCommandLogs") }
        static var closeWindow: String { tr("menu.closeWindow") }
        static var undo: String { tr("menu.undo") }
        static var redo: String { tr("menu.redo") }
        static var cut: String { tr("menu.cut") }
        static var copy: String { tr("menu.copy") }
        static var paste: String { tr("menu.paste") }
        static var pasteAndMatchStyle: String { tr("menu.pasteAndMatchStyle") }
        static var delete: String { tr("menu.delete") }
        static var selectAll: String { tr("menu.selectAll") }
        static var showMainWindow: String { tr("menu.showMainWindow") }
        static var toggleSidebar: String { tr("menu.toggleSidebar") }
        static var refreshCurrentPage: String { tr("menu.refreshCurrentPage") }
        static var themeSystem: String { tr("menu.themeSystem") }
        static var themeLight: String { tr("menu.themeLight") }
        static var themeDark: String { tr("menu.themeDark") }
        static var startViewScopeInspector: String { tr("menu.startViewScopeInspector") }
        static var minimize: String { tr("menu.minimize") }
        static var zoom: String { tr("menu.zoom") }
        static var bringAllToFront: String { tr("menu.bringAllToFront") }
        static var githubRepository: String { tr("menu.githubRepository") }
        static var reportIssue: String { tr("menu.reportIssue") }
        static var ascCLIRepository: String { tr("menu.ascCLIRepository") }
        static var acknowledgements: String { tr("menu.acknowledgements") }
    }

    enum Sidebar {
        static var apps: String { tr("sidebar.apps") }
        static var builds: String { tr("sidebar.builds") }
        static var review: String { tr("sidebar.review") }
        static var testFlight: String { tr("sidebar.testflight") }
        static var iap: String { tr("sidebar.iap") }
        static var signing: String { tr("sidebar.signing") }
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
            static var appLanguage: String { tr("settings.general.appLanguage") }
            static var languageChangeHint: String { tr("settings.general.languageChangeHint") }
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
            static var clearCacheConfirmTitle: String { tr("settings.data.clearCacheConfirmTitle") }
            static var clearCacheConfirmMessage: String { tr("settings.data.clearCacheConfirmMessage") }
            static var logRetention: String { tr("settings.data.logRetention") }
            static var exportData: String { tr("settings.data.exportData") }
            static var exportDataDescription: String { tr("settings.data.exportDataDescription") }
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

        enum Language {
            static var system: String { tr("settings.language.system") }
            static var simplifiedChinese: String { tr("settings.language.simplifiedChinese") }
            static var traditionalChinese: String { tr("settings.language.traditionalChinese") }
            static var english: String { tr("settings.language.english") }
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
        static var createApp: String { tr("apps.createApp") }
        static var createTitle: String { tr("apps.createTitle") }
        static var createHint: String { tr("apps.createHint") }
        static var name: String { tr("apps.name") }
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
        static var primaryLocale: String { tr("apps.primaryLocale") }
        static var initialVersion: String { tr("apps.initialVersion") }
        static var createSucceeded: String { tr("apps.createSucceeded") }
        static var defaultPlatform: String { tr("apps.defaultPlatform") }
    }

    enum Builds {
        static var title: String { tr("builds.title") }
        static var addVersion: String { tr("builds.addVersion") }
        static var addVersionTitle: String { tr("builds.addVersionTitle") }
        static var versionString: String { tr("builds.versionString") }
        static var noAppsForVersion: String { tr("builds.noAppsForVersion") }
        static var appFilter: String { tr("builds.appFilter") }
        static var selectApp: String { tr("builds.selectApp") }
        static var refresh: String { tr("builds.refresh") }
        static var expireSelected: String { tr("builds.expireSelected") }
        static var loading: String { tr("builds.loading") }
        static var emptyAppsTitle: String { tr("builds.emptyAppsTitle") }
        static var emptyAppsDetail: String { tr("builds.emptyAppsDetail") }
        static var emptyBuildsTitle: String { tr("builds.emptyBuildsTitle") }
        static var emptyBuildsDetail: String { tr("builds.emptyBuildsDetail") }
        static var loadFailed: String { tr("builds.loadFailed") }
        static var version: String { tr("builds.version") }
        static var buildNumber: String { tr("builds.buildNumber") }
        static var status: String { tr("builds.status") }
        static var platform: String { tr("builds.platform") }
        static var uploadedAt: String { tr("builds.uploadedAt") }
        static var cachedAt: String { tr("builds.cachedAt") }
        static var buildID: String { tr("builds.buildID") }
        static var appID: String { tr("builds.appID") }
        static var expired: String { tr("builds.expired") }
        static var noSelectionTitle: String { tr("builds.noSelectionTitle") }
        static var noSelectionDetail: String { tr("builds.noSelectionDetail") }
        static var unavailable: String { tr("builds.unavailable") }
        static var expireTaskTitle: String { tr("builds.expireTaskTitle") }
        static var expireTaskDetail: String { tr("builds.expireTaskDetail") }
        static var expireSucceeded: String { tr("builds.expireSucceeded") }
        static var expireFailed: String { tr("builds.expireFailed") }
        static var addVersionSucceeded: String { tr("builds.addVersionSucceeded") }
        static var defaultPlatform: String { tr("builds.defaultPlatform") }

        enum Status {
            static var processing: String { tr("builds.status.processing") }
            static var valid: String { tr("builds.status.valid") }
            static var invalid: String { tr("builds.status.invalid") }
            static var expired: String { tr("builds.status.expired") }
            static var unknown: String { tr("builds.status.unknown") }
        }
    }

    enum Tasking {
        static var noActiveTasks: String { tr("tasking.noActiveTasks") }
        static var activeTaskCount: String { tr("tasking.activeTaskCount") }
    }

    enum Signing {
        static var title: String { tr("signing.title") }
        static var bundleIDs: String { tr("signing.bundleIDs") }
        static var certificates: String { tr("signing.certificates") }
        static var devices: String { tr("signing.devices") }
        static var profiles: String { tr("signing.profiles") }
        static var refresh: String { tr("signing.refresh") }
        static var register: String { tr("signing.register") }
        static var loading: String { tr("signing.loading") }
        static var loadFailed: String { tr("signing.loadFailed") }
        static var emptyBundleIDs: String { tr("signing.emptyBundleIDs") }
        static var emptyCertificates: String { tr("signing.emptyCertificates") }
        static var emptyDevices: String { tr("signing.emptyDevices") }
        static var emptyProfiles: String { tr("signing.emptyProfiles") }
        static var noSelectionTitle: String { tr("signing.noSelectionTitle") }
        static var noSelectionDetail: String { tr("signing.noSelectionDetail") }
        static var id: String { tr("signing.id") }
        static var name: String { tr("signing.name") }
        static var identifier: String { tr("signing.identifier") }
        static var platform: String { tr("signing.platform") }
        static var seedID: String { tr("signing.seedID") }
        static var type: String { tr("signing.type") }
        static var displayName: String { tr("signing.displayName") }
        static var serialNumber: String { tr("signing.serialNumber") }
        static var expirationDate: String { tr("signing.expirationDate") }
        static var status: String { tr("signing.status") }
        static var udid: String { tr("signing.udid") }
        static var deviceClass: String { tr("signing.deviceClass") }
        static var model: String { tr("signing.model") }
        static var profileState: String { tr("signing.profileState") }
        static var activate: String { tr("signing.activate") }
        static var disable: String { tr("signing.disable") }
        static var revoke: String { tr("signing.revoke") }
        static var download: String { tr("signing.download") }
        static var actionSucceeded: String { tr("signing.actionSucceeded") }
        static var createSucceeded: String { tr("signing.createSucceeded") }
        static var createBundleIDTitle: String { tr("signing.createBundleIDTitle") }
        static var createCertificateTitle: String { tr("signing.createCertificateTitle") }
        static var registerDeviceTitle: String { tr("signing.registerDeviceTitle") }
        static var createProfileTitle: String { tr("signing.createProfileTitle") }
        static var csrPath: String { tr("signing.csrPath") }
        static var commonName: String { tr("signing.commonName") }
        static var privateKeyOutputPath: String { tr("signing.privateKeyOutputPath") }
        static var generatedCSRPath: String { tr("signing.generatedCSRPath") }
        static var generateCSR: String { tr("signing.generateCSR") }
        static var generateCSRMissingFields: String { tr("signing.generateCSRMissingFields") }
        static var csrGenerated: String { tr("signing.csrGenerated") }
        static var certificateHint: String { tr("signing.certificateHint") }
        static var bundleID: String { tr("signing.bundleID") }
        static var certificateIDs: String { tr("signing.certificateIDs") }
        static var deviceIDs: String { tr("signing.deviceIDs") }
        static var invertSelection: String { tr("signing.invertSelection") }
        static var configureCapabilitiesTitle: String { tr("signing.configureCapabilitiesTitle") }
        static var existingCapabilities: String { tr("signing.existingCapabilities") }
        static var capability: String { tr("signing.capability") }
        static var settingsJSON: String { tr("signing.settingsJSON") }
        static var capabilityHint: String { tr("signing.capabilityHint") }
        static var bundleIDResolveFailed: String { tr("signing.bundleIDResolveFailed") }
        static var useCurrentMachineUDID: String { tr("signing.useCurrentMachineUDID") }
        static var profileHint: String { tr("signing.profileHint") }
    }

    enum Common {
        static var browse: String { tr("common.browse") }
        static var save: String { tr("common.save") }
        static var create: String { tr("common.create") }
        static var add: String { tr("common.add") }
        static var cancel: String { tr("common.cancel") }
        static var delete: String { tr("common.delete") }
        static var validate: String { tr("common.validate") }
        static var activate: String { tr("common.activate") }
        static var close: String { tr("common.close") }
        static var ok: String { tr("common.ok") }
    }

    enum Updates {
        static var unconfigured: String { tr("updates.unconfigured") }
        static var githubStatusError: String { tr("updates.githubStatusError") }
        static var latestTitle: String { tr("updates.latestTitle") }
        static var latestMessage: String { tr("updates.latestMessage") }
        static var availableTitle: String { tr("updates.availableTitle") }
        static var availableMessage: String { tr("updates.availableMessage") }
        static var availableNamedMessage: String { tr("updates.availableNamedMessage") }
        static var openRelease: String { tr("updates.openRelease") }
        static var notNow: String { tr("updates.notNow") }
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
        static var missingRequiredFields: String { tr("apikeys.missingRequiredFields") }
        static var privateKeyFileMissing: String { tr("apikeys.privateKeyFileMissing") }
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

import AppKit
import Foundation

#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
protocol AppUpdateManaging: AnyObject {
    var canCheckForUpdates: Bool { get }

    func configure()
    func scheduleBackgroundUpdateCheck()
    func checkForUpdates()
    func openRepository()
    func openIssues()
    func openCLIRepository()
}

@MainActor
final class AppUpdateManager: NSObject, AppUpdateManaging {
    static let shared = AppUpdateManager()

    private let lastUpdateCheckKey = "ConnectMateLastUpdateCheckDate"
    private let settings: AppSettings
    private let metadata: AppMetadata
    private let session: URLSession

    #if canImport(Sparkle)
    private var sparkleUpdaterController: SPUStandardUpdaterController?
    #endif

    init(
        settings: AppSettings = .shared,
        metadata: AppMetadata = AppMetadata(),
        session: URLSession = .shared
    ) {
        self.settings = settings
        self.metadata = metadata
        self.session = session
    }

    var canCheckForUpdates: Bool {
        #if canImport(Sparkle)
        if let updater = sparkleUpdaterController?.updater {
            return updater.canCheckForUpdates
        }
        #endif
        return metadata.latestReleaseAPIURL != nil
    }

    func configure() {
        #if canImport(Sparkle)
        guard sparkleUpdaterController == nil, metadata.isSparkleConfigured else {
            return
        }

        sparkleUpdaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        applySparkleSettings()
        #endif
    }

    func scheduleBackgroundUpdateCheck() {
        guard settings.autoCheckUpdates else {
            return
        }

        #if canImport(Sparkle)
        if let updater = sparkleUpdaterController?.updater {
            switch settings.updateCheckFrequency {
            case .launch:
                updater.checkForUpdatesInBackground()
            case .daily, .weekly:
                applySparkleSettings()
            }
            return
        }
        #endif

        guard shouldPerformGitHubFallbackCheck() else {
            return
        }

        Task { [weak self] in
            await self?.checkGitHubLatestRelease(interactive: false)
        }
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        if let sparkleUpdaterController {
            sparkleUpdaterController.checkForUpdates(nil)
            return
        }
        #endif

        Task { [weak self] in
            await self?.checkGitHubLatestRelease(interactive: true)
        }
    }

    func openRepository() {
        open(metadata.repositoryURL)
    }

    func openIssues() {
        open(metadata.issuesURL)
    }

    func openCLIRepository() {
        open(metadata.cliRepositoryURL)
    }

    #if canImport(Sparkle)
    private func applySparkleSettings() {
        guard let updater = sparkleUpdaterController?.updater else {
            return
        }

        guard settings.autoCheckUpdates else {
            updater.automaticallyChecksForUpdates = false
            return
        }

        switch settings.updateCheckFrequency {
        case .launch:
            updater.automaticallyChecksForUpdates = false
        case .daily:
            updater.updateCheckInterval = 24 * 60 * 60
            updater.automaticallyChecksForUpdates = true
        case .weekly:
            updater.updateCheckInterval = 7 * 24 * 60 * 60
            updater.automaticallyChecksForUpdates = true
        }
    }
    #endif

    private func shouldPerformGitHubFallbackCheck() -> Bool {
        guard metadata.latestReleaseAPIURL != nil else {
            return false
        }

        let interval: TimeInterval
        switch settings.updateCheckFrequency {
        case .launch:
            return true
        case .daily:
            interval = 24 * 60 * 60
        case .weekly:
            interval = 7 * 24 * 60 * 60
        }

        guard let lastCheck = UserDefaults.standard.object(forKey: lastUpdateCheckKey) as? Date else {
            return true
        }

        return Date().timeIntervalSince(lastCheck) >= interval
    }

    private func checkGitHubLatestRelease(interactive: Bool) async {
        guard let latestReleaseAPIURL = metadata.latestReleaseAPIURL else {
            if interactive {
                presentFailureAlert(message: L10n.Updates.unconfigured)
            }
            return
        }

        do {
            let release = try await fetchLatestRelease(from: latestReleaseAPIURL)
            UserDefaults.standard.set(Date(), forKey: lastUpdateCheckKey)
            presentReleaseResult(release, interactive: interactive)
        } catch {
            if interactive {
                presentFailureAlert(message: error.localizedDescription)
            }
        }
    }

    private func fetchLatestRelease(from url: URL) async throws -> GitHubRelease {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ConnectMate", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "ConnectMate.AppUpdateManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: L10n.Updates.githubStatusError]
            )
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func presentReleaseResult(_ release: GitHubRelease, interactive: Bool) {
        let currentVersion = ReleaseVersion(currentAppVersion)
        let latestVersion = ReleaseVersion(release.tagName)

        guard latestVersion > currentVersion else {
            if interactive {
                let alert = NSAlert()
                alert.messageText = L10n.Updates.latestTitle
                alert.informativeText = String(format: L10n.Updates.latestMessage, currentAppVersion, release.tagName)
                alert.alertStyle = .informational
                alert.addButton(withTitle: L10n.Common.ok)
                alert.runModal()
            }
            return
        }

        guard interactive else {
            return
        }

        let alert = NSAlert()
        alert.messageText = String(format: L10n.Updates.availableTitle, release.tagName)
        if let releaseName = release.name, !releaseName.isEmpty {
            alert.informativeText = String(format: L10n.Updates.availableNamedMessage, currentAppVersion, releaseName)
        } else {
            alert.informativeText = String(format: L10n.Updates.availableMessage, currentAppVersion)
        }
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.Updates.openRelease)
        alert.addButton(withTitle: L10n.Updates.notNow)

        if alert.runModal() == .alertFirstButtonReturn {
            open(release.htmlURL ?? metadata.repositoryURL)
        }
    }

    private func presentFailureAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = L10n.Settings.Updates.checkNow
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.Common.ok)
        alert.runModal()
    }

    private var currentAppVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private func open(_ url: URL?) {
        guard let url else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let htmlURL: URL?

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
    }
}

private struct ReleaseVersion: Comparable {
    let rawValue: String
    private let components: [Int]

    init(_ rawValue: String) {
        self.rawValue = rawValue
        self.components = Self.parse(rawValue)
    }

    static func < (lhs: ReleaseVersion, rhs: ReleaseVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for index in 0..<maxCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }

    private static func parse(_ rawValue: String) -> [Int] {
        var sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("v") || sanitized.hasPrefix("V") {
            sanitized.removeFirst()
        }

        if let suffixIndex = sanitized.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            sanitized = String(sanitized[..<suffixIndex])
        }

        let values = sanitized
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        let trimmed = values.reversed().drop(while: { $0 == 0 }).reversed()
        return Array(trimmed)
    }
}

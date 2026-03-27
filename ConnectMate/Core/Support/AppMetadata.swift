import Foundation

struct AppMetadata {
    private let infoDictionary: [String: Any]

    init(bundle: Bundle = .main) {
        self.infoDictionary = bundle.infoDictionary ?? [:]
    }

    init(infoDictionary: [String: Any]) {
        self.infoDictionary = infoDictionary
    }

    var repositoryURL: URL? {
        url(for: "ConnectMateGitHubURL")
    }

    var issuesURL: URL? {
        url(for: "ConnectMateGitHubIssuesURL")
    }

    var latestReleaseAPIURL: URL? {
        url(for: "ConnectMateGitHubLatestReleaseAPIURL")
    }

    var cliRepositoryURL: URL? {
        url(for: "ConnectMateCLIRepositoryURL")
    }

    var sparkleFeedURL: URL? {
        url(for: "SUFeedURL")
    }

    var sparklePublicKey: String? {
        string(for: "SUPublicEDKey")
    }

    var isSparkleConfigured: Bool {
        sparkleFeedURL != nil && !(sparklePublicKey?.isEmpty ?? true)
    }

    private func url(for key: String) -> URL? {
        guard let rawValue = string(for: key) else {
            return nil
        }
        return URL(string: rawValue)
    }

    private func string(for key: String) -> String? {
        guard let rawValue = infoDictionary[key] as? String else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

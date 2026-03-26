import Foundation

struct ASCCommandConfiguration: Sendable, Equatable {
    var cliPath: String
    var timeout: TimeInterval
    var retryCount: Int
    var proxyURL: String?
    var profileName: String?
    var apiKey: APIKeyRecord?
    var workingDirectory: URL?
    var environment: [String: String]

    init(
        cliPath: String = "/usr/local/bin/asc",
        timeout: TimeInterval = 30,
        retryCount: Int = 3,
        proxyURL: String? = nil,
        profileName: String? = nil,
        apiKey: APIKeyRecord? = nil,
        workingDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) {
        self.cliPath = cliPath
        self.timeout = timeout
        self.retryCount = max(1, retryCount)
        self.proxyURL = proxyURL?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.profileName = profileName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.apiKey = apiKey
        self.workingDirectory = workingDirectory
        self.environment = environment
    }

    init(settings: AppSettings, apiKey: APIKeyRecord? = nil, workingDirectory: URL? = nil, environment: [String: String] = [:]) {
        self.init(
            cliPath: settings.cliPath,
            timeout: TimeInterval(settings.commandTimeout),
            retryCount: settings.apiRetryCount,
            proxyURL: settings.proxyEnabled ? settings.proxyURL : nil,
            profileName: apiKey?.profileName,
            apiKey: apiKey,
            workingDirectory: workingDirectory,
            environment: environment
        )
    }

    func resolvedEnvironment(extraEnvironment: [String: String] = [:]) -> [String: String] {
        var resolved = ProcessInfo.processInfo.environment
        resolved.merge(environment) { _, new in new }
        resolved.merge(extraEnvironment) { _, new in new }
        resolved["ASC_TIMEOUT"] = String(max(1, Int(timeout.rounded(.up))))

        if let proxyURL {
            resolved["HTTP_PROXY"] = proxyURL
            resolved["HTTPS_PROXY"] = proxyURL
        }

        if let profileName {
            resolved["ASC_PROFILE"] = profileName
        }

        if let apiKey {
            resolved["ASC_KEY_ID"] = apiKey.keyID
            resolved["ASC_ISSUER_ID"] = apiKey.issuerID
            resolved["ASC_PRIVATE_KEY_PATH"] = apiKey.p8Path

            if resolved["ASC_PROFILE"] == nil, let profileName = apiKey.profileName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                resolved["ASC_PROFILE"] = profileName
            }
        }

        return resolved
    }

    static func == (lhs: ASCCommandConfiguration, rhs: ASCCommandConfiguration) -> Bool {
        lhs.cliPath == rhs.cliPath &&
            lhs.timeout == rhs.timeout &&
            lhs.retryCount == rhs.retryCount &&
            lhs.proxyURL == rhs.proxyURL &&
            lhs.profileName == rhs.profileName &&
            lhs.apiKey?.id == rhs.apiKey?.id &&
            lhs.apiKey?.issuerID == rhs.apiKey?.issuerID &&
            lhs.apiKey?.keyID == rhs.apiKey?.keyID &&
            lhs.apiKey?.p8Path == rhs.apiKey?.p8Path &&
            lhs.apiKey?.profileName == rhs.apiKey?.profileName &&
            lhs.workingDirectory == rhs.workingDirectory &&
            lhs.environment == rhs.environment
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

import Foundation
import GRDB

nonisolated enum AppCreationInputField: Equatable {
    case name
    case bundleID
    case sku
    case primaryLocale

    var title: String {
        switch self {
        case .name:
            return "Name"
        case .bundleID:
            return "Bundle ID"
        case .sku:
            return "SKU"
        case .primaryLocale:
            return "Primary Locale"
        }
    }
}

nonisolated enum AppCreationInputError: LocalizedError, Equatable {
    case missingRequiredFields([AppCreationInputField])

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields(let fields):
            let joined = fields.map(\.title).joined(separator: " / ")
            return "Missing required fields: \(joined)"
        }
    }
}

@MainActor
final class AppService {
    nonisolated struct CreateAppRequest: Equatable, Sendable {
        let name: String
        let bundleID: String
        let sku: String
        let primaryLocale: String
        let platform: String?
        let initialVersion: String?

        init(
            name: String,
            bundleID: String,
            sku: String,
            primaryLocale: String,
            platform: String? = nil,
            initialVersion: String? = nil
        ) {
            self.name = name
            self.bundleID = bundleID
            self.sku = sku
            self.primaryLocale = primaryLocale
            self.platform = platform
            self.initialVersion = initialVersion
        }
    }

    private let runner: any ASCCommandRunning
    private let webSessionRunner: any ASCCommandRunning
    let repository: AppRepository
    private let parser: ASCOutputParser
    private let activeProfileProvider: @MainActor @Sendable () throws -> APIKeyRecord?

    init(
        runner: any ASCCommandRunning,
        webSessionRunner: (any ASCCommandRunning)? = nil,
        repository: AppRepository? = nil,
        parser: ASCOutputParser = ASCOutputParser(),
        activeProfileProvider: (@MainActor @Sendable () throws -> APIKeyRecord?)? = nil
    ) {
        self.runner = runner
        self.webSessionRunner = webSessionRunner ?? runner
        self.repository = repository ?? AppRepository()
        self.parser = parser
        self.activeProfileProvider = activeProfileProvider ?? AppService.defaultActiveProfile
    }

    func loadCachedApps(search: String?) throws -> [AppSummary] {
        let activeProfile = try activeProfileProvider()
        return try repository
            .fetchAll(accountKeyID: activeProfile?.id, search: search)
            .map(AppSummary.init(record:))
    }

    func refreshApps(search: String?) async throws -> [AppSummary] {
        let result = try await runner.run(
            arguments: ["apps", "list"],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let payloads = try parser.decodeApps(from: Data(result.standardOutput.utf8))
        let activeProfile = try activeProfileProvider()
        try repository.replaceCache(with: payloads, accountKeyID: activeProfile?.id)
        return try loadCachedApps(search: search)
    }

    func createApp(_ request: CreateAppRequest) async throws -> ASCCommandResult {
        let normalized = try normalizeCreateRequest(request)

        var arguments = [
            "web", "apps", "create",
            "--name", normalized.name,
            "--bundle-id", normalized.bundleID,
            "--sku", normalized.sku,
            "--primary-locale", normalized.primaryLocale
        ]

        if let platform = normalized.platform {
            arguments.append(contentsOf: ["--platform", platform])
        }

        if let initialVersion = normalized.initialVersion {
            arguments.append(contentsOf: ["--version", initialVersion])
        }

        arguments.append(contentsOf: ["--output", "json"])

        return try await webSessionRunner.run(
            arguments: arguments,
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    private static func defaultActiveProfile() throws -> APIKeyRecord? {
        try DatabaseManager.shared.dbQueue.read { db in
            try APIKeyRecord
                .filter(Column("is_active") == true)
                .fetchOne(db)
        }
    }

    static func makeDefault() -> AppService {
        let databaseManager = DatabaseManager.shared
        let activeProfileProvider: @MainActor @Sendable () throws -> APIKeyRecord? = {
            try databaseManager.dbQueue.read { db in
                try APIKeyRecord
                    .filter(Column("is_active") == true)
                    .fetchOne(db)
            }
        }

        if let fixturePath = ProcessInfo.processInfo.environment["CONNECTMATE_APP_FIXTURE_PATH"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !fixturePath.isEmpty {
            return AppService(
                runner: FixtureAppsRunner(fixturePath: fixturePath),
                repository: AppRepository(dbWriter: databaseManager.dbQueue),
                activeProfileProvider: activeProfileProvider
            )
        }

        let activeProfile = try? activeProfileProvider()
        let apiConfiguration = ASCCommandConfiguration(
            settings: .shared,
            apiKey: activeProfile,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )
        let webConfiguration = ASCCommandConfiguration(
            settings: .shared,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )

        return AppService(
            runner: ASCCommandRunner(
                configuration: apiConfiguration,
                logRepository: databaseManager.commandLogRepository
            ),
            webSessionRunner: ASCCommandRunner(
                configuration: webConfiguration,
                logRepository: databaseManager.commandLogRepository
            ),
            repository: AppRepository(dbWriter: databaseManager.dbQueue),
            activeProfileProvider: activeProfileProvider
        )
    }

    private func normalizeCreateRequest(_ request: CreateAppRequest) throws -> CreateAppRequest {
        let name = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleID = request.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        let sku = request.sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryLocale = request.primaryLocale.trimmingCharacters(in: .whitespacesAndNewlines)
        let platform = request.platform?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let initialVersion = request.initialVersion?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        var missingFields: [AppCreationInputField] = []
        if name.isEmpty {
            missingFields.append(.name)
        }
        if bundleID.isEmpty {
            missingFields.append(.bundleID)
        }
        if sku.isEmpty {
            missingFields.append(.sku)
        }
        if primaryLocale.isEmpty {
            missingFields.append(.primaryLocale)
        }

        if !missingFields.isEmpty {
            throw AppCreationInputError.missingRequiredFields(missingFields)
        }

        return CreateAppRequest(
            name: name,
            bundleID: bundleID,
            sku: sku,
            primaryLocale: primaryLocale,
            platform: platform,
            initialVersion: initialVersion
        )
    }
}

private struct FixtureAppsRunner: ASCCommandRunning {
    let fixturePath: String

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
        let output = try String(contentsOfFile: fixturePath, encoding: .utf8)
        return ASCCommandResult(
            executablePath: fixturePath,
            arguments: arguments,
            standardOutput: output,
            standardError: "",
            exitCode: 0,
            duration: 0.01,
            attemptCount: 1
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

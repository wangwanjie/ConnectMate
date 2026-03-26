import Foundation
import GRDB

final class AppService {
    private let runner: any ASCCommandRunning
    let repository: AppRepository
    private let parser: ASCOutputParser
    private let activeProfileProvider: @Sendable () throws -> APIKeyRecord?

    init(
        runner: any ASCCommandRunning,
        repository: AppRepository = AppRepository(),
        parser: ASCOutputParser = ASCOutputParser(),
        activeProfileProvider: @escaping @Sendable () throws -> APIKeyRecord? = AppService.defaultActiveProfile
    ) {
        self.runner = runner
        self.repository = repository
        self.parser = parser
        self.activeProfileProvider = activeProfileProvider
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

    private static func defaultActiveProfile() throws -> APIKeyRecord? {
        try DatabaseManager.shared.dbQueue.read { db in
            try APIKeyRecord
                .filter(Column("is_active") == true)
                .fetchOne(db)
        }
    }

    static func makeDefault() -> AppService {
        let databaseManager = DatabaseManager.shared
        let activeProfileProvider: @Sendable () throws -> APIKeyRecord? = {
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
        let configuration = ASCCommandConfiguration(
            settings: .shared,
            apiKey: activeProfile,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )

        return AppService(
            runner: ASCCommandRunner(
                configuration: configuration,
                logRepository: databaseManager.commandLogRepository
            ),
            repository: AppRepository(dbWriter: databaseManager.dbQueue),
            activeProfileProvider: activeProfileProvider
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

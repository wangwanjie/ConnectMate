import Foundation
import GRDB

nonisolated enum VersionCreationInputField: Equatable {
    case appID
    case versionString

    var title: String {
        switch self {
        case .appID:
            return "App"
        case .versionString:
            return "Version"
        }
    }
}

nonisolated enum VersionCreationInputError: LocalizedError, Equatable {
    case missingRequiredFields([VersionCreationInputField])

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields(let fields):
            let joined = fields.map(\.title).joined(separator: " / ")
            return "Missing required fields: \(joined)"
        }
    }
}

@MainActor
final class BuildService {
    nonisolated struct CreateVersionRequest: Equatable, Sendable {
        let appID: String
        let versionString: String
        let platform: String?

        init(appID: String, versionString: String, platform: String? = nil) {
            self.appID = appID
            self.versionString = versionString
            self.platform = platform
        }
    }

    private let runner: any ASCCommandRunning
    let repository: BuildRepository
    private let parser: ASCOutputParser
    private let activeProfileProvider: @MainActor @Sendable () throws -> APIKeyRecord?
    private let taskReporter: any BuildTaskReporting

    init(
        runner: any ASCCommandRunning,
        repository: BuildRepository? = nil,
        parser: ASCOutputParser = ASCOutputParser(),
        taskReporter: (any BuildTaskReporting)? = nil,
        activeProfileProvider: (@MainActor @Sendable () throws -> APIKeyRecord?)? = nil
    ) {
        self.runner = runner
        self.repository = repository ?? BuildRepository()
        self.parser = parser
        self.taskReporter = taskReporter ?? TaskCenter.shared
        self.activeProfileProvider = activeProfileProvider ?? BuildService.defaultActiveProfile
    }

    func loadCachedBuilds(appID: String, status: BuildProcessingState?) throws -> [BuildSummary] {
        let activeProfile = try activeProfileProvider()
        return try repository
            .fetchAll(accountKeyID: activeProfile?.id, appID: appID, status: status)
            .map(BuildSummary.init(record:))
    }

    func refreshBuilds(appID: String, status: BuildProcessingState?) async throws -> [BuildSummary] {
        let result = try await runner.run(
            arguments: ["builds", "list", "--app", appID],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let payloads = try parser.decodeBuilds(from: Data(result.standardOutput.utf8))
        let activeProfile = try activeProfileProvider()
        try repository.replaceCache(with: payloads, accountKeyID: activeProfile?.id, appID: appID)
        return try loadCachedBuilds(appID: appID, status: status)
    }

    func createVersion(_ request: CreateVersionRequest) async throws -> ASCCommandResult {
        let normalized = try normalizeCreateRequest(request)

        var arguments = [
            "versions", "create",
            "--app", normalized.appID,
            "--version", normalized.versionString
        ]

        if let platform = normalized.platform {
            arguments.append(contentsOf: ["--platform", platform])
        }

        arguments.append(contentsOf: ["--output", "json"])

        return try await runner.run(
            arguments: arguments,
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func expireBuilds(_ buildIDs: [String]) async throws {
        let filteredBuildIDs = buildIDs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !filteredBuildIDs.isEmpty else {
            return
        }

        let taskID = taskReporter.startTask(
            title: L10n.Builds.expireTaskTitle,
            detail: L10n.Builds.expireTaskDetail
        )

        do {
            for (index, buildID) in filteredBuildIDs.enumerated() {
                _ = try await runner.run(
                    arguments: ["builds", "expire", "--build", buildID, "--confirm"],
                    standardInput: nil,
                    extraEnvironment: [:]
                )

                let progress = Double(index + 1) / Double(filteredBuildIDs.count)
                taskReporter.updateTask(
                    id: taskID,
                    detail: buildID,
                    fractionCompleted: progress,
                    state: .running
                )
            }

            taskReporter.finishTask(
                id: taskID,
                state: .succeeded,
                detail: L10n.Builds.expireSucceeded
            )
        } catch {
            taskReporter.finishTask(
                id: taskID,
                state: .failed,
                detail: error.localizedDescription
            )
            throw error
        }
    }

    private static func defaultActiveProfile() throws -> APIKeyRecord? {
        try DatabaseManager.shared.dbQueue.read { db in
            try APIKeyRecord
                .filter(Column("is_active") == true)
                .fetchOne(db)
        }
    }

    static func makeDefault() -> BuildService {
        let databaseManager = DatabaseManager.shared
        let activeProfileProvider: @MainActor @Sendable () throws -> APIKeyRecord? = {
            try databaseManager.dbQueue.read { db in
                try APIKeyRecord
                    .filter(Column("is_active") == true)
                    .fetchOne(db)
            }
        }

        if let fixturePath = ProcessInfo.processInfo.environment["CONNECTMATE_BUILD_FIXTURE_PATH"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !fixturePath.isEmpty {
            return BuildService(
                runner: FixtureBuildsRunner(fixturePath: fixturePath),
                repository: BuildRepository(dbWriter: databaseManager.dbQueue),
                taskReporter: TaskCenter.shared,
                activeProfileProvider: activeProfileProvider
            )
        }

        let activeProfile = try? activeProfileProvider()
        let configuration = ASCCommandConfiguration(
            settings: .shared,
            apiKey: activeProfile,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )

        return BuildService(
            runner: ASCCommandRunner(
                configuration: configuration,
                logRepository: databaseManager.commandLogRepository
            ),
            repository: BuildRepository(dbWriter: databaseManager.dbQueue),
            taskReporter: TaskCenter.shared,
            activeProfileProvider: activeProfileProvider
        )
    }

    private func normalizeCreateRequest(_ request: CreateVersionRequest) throws -> CreateVersionRequest {
        let appID = request.appID.trimmingCharacters(in: .whitespacesAndNewlines)
        let versionString = request.versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        let platform = request.platform?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        var missingFields: [VersionCreationInputField] = []
        if appID.isEmpty {
            missingFields.append(.appID)
        }
        if versionString.isEmpty {
            missingFields.append(.versionString)
        }

        if !missingFields.isEmpty {
            throw VersionCreationInputError.missingRequiredFields(missingFields)
        }

        return CreateVersionRequest(
            appID: appID,
            versionString: versionString,
            platform: platform
        )
    }
}

private struct FixtureBuildsRunner: ASCCommandRunning {
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

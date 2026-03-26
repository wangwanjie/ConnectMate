import Foundation
import GRDB

final class BuildService {
    private let runner: any ASCCommandRunning
    let repository: BuildRepository
    private let parser: ASCOutputParser
    private let activeProfileProvider: @Sendable () throws -> APIKeyRecord?
    private let taskReporter: any BuildTaskReporting

    init(
        runner: any ASCCommandRunning,
        repository: BuildRepository = BuildRepository(),
        parser: ASCOutputParser = ASCOutputParser(),
        taskReporter: any BuildTaskReporting = TaskCenter.shared,
        activeProfileProvider: @escaping @Sendable () throws -> APIKeyRecord? = BuildService.defaultActiveProfile
    ) {
        self.runner = runner
        self.repository = repository
        self.parser = parser
        self.taskReporter = taskReporter
        self.activeProfileProvider = activeProfileProvider
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

    func expireBuilds(_ buildIDs: [String]) async throws {
        let filteredBuildIDs = buildIDs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !filteredBuildIDs.isEmpty else {
            return
        }

        let taskID = await taskReporter.startTask(
            title: L10n.Builds.expireTaskTitle,
            detail: L10n.Builds.expireTaskDetail
        )

        do {
            for (index, buildID) in filteredBuildIDs.enumerated() {
                try await runner.run(
                    arguments: ["builds", "expire", "--build", buildID, "--confirm"],
                    standardInput: nil,
                    extraEnvironment: [:]
                )

                let progress = Double(index + 1) / Double(filteredBuildIDs.count)
                await taskReporter.updateTask(
                    id: taskID,
                    detail: buildID,
                    fractionCompleted: progress,
                    state: .running
                )
            }

            await taskReporter.finishTask(
                id: taskID,
                state: .succeeded,
                detail: L10n.Builds.expireSucceeded
            )
        } catch {
            await taskReporter.finishTask(
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
        let activeProfileProvider: @Sendable () throws -> APIKeyRecord? = {
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

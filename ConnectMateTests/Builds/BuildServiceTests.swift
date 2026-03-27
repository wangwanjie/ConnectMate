import Foundation
import GRDB
import Testing
@testable import ConnectMate

@MainActor
struct BuildServiceTests {
    @Test
    func refreshBuildsForAppCachesProcessingState() async throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)

        let runner = FixtureBuildRunner(fixtureName: "builds-list.json")
        let repository = BuildRepository(dbWriter: dbQueue)
        let service = BuildService(
            runner: runner,
            repository: repository,
            activeProfileProvider: { nil }
        )

        let builds = try await service.refreshBuilds(appID: "123456789", status: nil)
        let cachedBuilds = try repository.fetchAll(appID: "123456789")

        #expect(builds.count == 2)
        #expect(builds.first?.version == "1.2.3")
        #expect(builds.first?.buildNumber == "42")
        #expect(builds.first?.processingState == .valid)
        #expect(cachedBuilds.count == 2)
        #expect(cachedBuilds.first?.appAscID == "123456789")
    }

    @Test
    func expireSelectedBuildsSchedulesBatchTasks() async throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)

        let runner = CapturingBuildRunner()
        let reporter = BuildTaskReporterSpy()
        let service = BuildService(
            runner: runner,
            repository: BuildRepository(dbWriter: dbQueue),
            taskReporter: reporter,
            activeProfileProvider: { nil }
        )

        try await service.expireBuilds(["BUILD_1", "BUILD_2"])

        #expect(runner.capturedArguments == [
            ["builds", "expire", "--build", "BUILD_1", "--confirm"],
            ["builds", "expire", "--build", "BUILD_2", "--confirm"]
        ])
        #expect(reporter.startedTaskTitle == "Expire Builds")
        #expect(reporter.finishedStates == [.succeeded])
    }

    @Test
    func createVersionBuildsExpectedArguments() async throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)

        let runner = CapturingBuildRunner()
        let service = BuildService(
            runner: runner,
            repository: BuildRepository(dbWriter: dbQueue),
            activeProfileProvider: { nil }
        )

        _ = try await service.createVersion(
            .init(
                appID: "123456789",
                versionString: "2.0.0",
                platform: "MAC_OS"
            )
        )

        #expect(runner.capturedArguments.last == [
            "versions", "create",
            "--app", "123456789",
            "--version", "2.0.0",
            "--platform", "MAC_OS",
            "--output", "json"
        ])
    }
}

private struct FixtureBuildRunner: ASCCommandRunning {
    let fixtureName: String

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
        ASCCommandResult(
            executablePath: "/usr/local/bin/asc",
            arguments: arguments,
            standardOutput: try FixtureLoader.string(named: fixtureName),
            standardError: "",
            exitCode: 0,
            duration: 0.01,
            attemptCount: 1
        )
    }
}

private final class CapturingBuildRunner: ASCCommandRunning, @unchecked Sendable {
    private(set) var capturedArguments: [[String]] = []

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
        capturedArguments.append(arguments)
        return ASCCommandResult(
            executablePath: "/usr/local/bin/asc",
            arguments: arguments,
            standardOutput: "{\"data\":{\"id\":\"\(arguments[3])\"}}",
            standardError: "",
            exitCode: 0,
            duration: 0.01,
            attemptCount: 1
        )
    }
}

@MainActor
private final class BuildTaskReporterSpy: BuildTaskReporting {
    private(set) var startedTaskTitle: String?
    private(set) var finishedStates: [TaskState] = []

    func startTask(title: String, detail: String) -> UUID {
        startedTaskTitle = title
        return UUID()
    }

    func updateTask(id: UUID, detail: String?, fractionCompleted: Double?, state: TaskState?) {}

    func finishTask(id: UUID, state: TaskState, detail: String?) {
        finishedStates.append(state)
    }
}

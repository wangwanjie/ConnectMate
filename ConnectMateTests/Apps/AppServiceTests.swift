import Foundation
import GRDB
import Testing
@testable import ConnectMate

struct AppServiceTests {
    @Test
    func refreshAppsParsesAndCachesAppList() async throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)

        let runner = FixtureAppRunner(fixtureName: "apps-list.json")
        let repository = AppRepository(dbWriter: dbQueue)
        let service = AppService(
            runner: runner,
            repository: repository,
            activeProfileProvider: { nil }
        )

        let apps = try await service.refreshApps(search: nil)
        let cachedApps = try repository.fetchAll()

        #expect(apps.count == 2)
        #expect(apps.first?.name == "First App")
        #expect(cachedApps.count == 2)
        #expect(cachedApps.map(\.bundleID) == ["com.example.first", "com.example.second"])
    }
}

private struct FixtureAppRunner: ASCCommandRunning {
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

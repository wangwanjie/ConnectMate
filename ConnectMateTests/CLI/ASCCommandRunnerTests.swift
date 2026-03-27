import Foundation
import GRDB
import Testing
@testable import ConnectMate

struct ASCCommandRunnerTests {
    @Test
    func runnerCanExecuteInstalledASCCLI() async throws {
        let path = "/usr/local/bin/asc"
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }

        let runner = ASCCommandRunner(configuration: .init(cliPath: path, timeout: 5, retryCount: 1))
        let result = try await runner.run(arguments: ["version"])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput.contains("0."))
    }

    @Test
    func runnerCapturesStdoutAndInjectedEnvironment() async throws {
        let configuration = ASCCommandConfiguration(
            cliPath: "/bin/sh",
            timeout: 1,
            retryCount: 1,
            proxyURL: "http://127.0.0.1:9090",
            profileName: "connectmate-test"
        )
        let runner = ASCCommandRunner(configuration: configuration)

        let result = try await runner.run(arguments: [
            "-c",
            "printf '%s|%s|%s' \"$HTTP_PROXY\" \"$ASC_TIMEOUT\" \"$ASC_PROFILE\""
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "http://127.0.0.1:9090|1|connectmate-test")
        #expect(result.standardError.isEmpty)
        #expect(result.attemptCount == 1)
    }

    @Test
    func runnerRetriesNonZeroExitAndEventuallySucceeds() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let counterFile = temporaryDirectory.appendingPathComponent("counter.txt")
        let configuration = ASCCommandConfiguration(cliPath: "/bin/sh", timeout: 1, retryCount: 2)
        let runner = ASCCommandRunner(configuration: configuration)

        let script = """
        count=$(cat "\(counterFile.path)" 2>/dev/null || echo 0)
        count=$((count + 1))
        printf '%s' "$count" > "\(counterFile.path)"
        if [ "$count" -lt 2 ]; then
          echo 'try again' >&2
          exit 1
        fi
        echo 'ok'
        """

        let result = try await runner.run(arguments: ["-c", script])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines) == "ok")
        #expect(result.attemptCount == 2)
    }

    @Test
    func runnerSurfacesTimeoutAsStructuredError() async throws {
        let runner = ASCCommandRunner(configuration: .init(cliPath: "/bin/sleep", timeout: 0.1, retryCount: 1))

        await #expect(throws: ASCError.timeout) {
            _ = try await runner.run(arguments: ["2"])
        }
    }

    @Test
    func runnerWritesCommandLogs() async throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)
        let repository = CommandLogRepository(dbWriter: dbQueue)
        let runner = ASCCommandRunner(
            configuration: .init(cliPath: "/bin/echo", timeout: 1, retryCount: 1),
            logRepository: repository
        )

        _ = try await runner.run(arguments: ["logged"])
        let logs = try repository.fetchRecent(limit: 1)

        #expect(logs.count == 1)
        #expect(logs[0].command == "/bin/echo")
        #expect(logs[0].status == "success")
        #expect(logs[0].stdoutText.contains("logged"))
    }

    @Test
    func configurationResolvesPrivateKeyPathFromBookmark() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let originalURL = temporaryDirectory.appendingPathComponent("AuthKey_ORIGINAL.p8")
        let movedURL = temporaryDirectory.appendingPathComponent("AuthKey_MOVED.p8")
        try Data("PRIVATE KEY".utf8).write(to: originalURL)
        let bookmarkData = BookmarkedFileReference.makeBookmark(for: originalURL.path)
        try FileManager.default.moveItem(at: originalURL, to: movedURL)

        let record = APIKeyRecord(
            id: 1,
            name: "Moved",
            issuerID: "ISSUER",
            keyID: "KEY",
            p8Path: originalURL.path,
            p8Bookmark: bookmarkData,
            profileName: "Moved",
            isActive: true,
            lastVerifiedAt: nil,
            lastValidationStatus: nil
        )

        let configuration = ASCCommandConfiguration(apiKey: record)
        let environment = configuration.resolvedEnvironment()

        #expect(environment["ASC_PRIVATE_KEY_PATH"] == movedURL.standardizedFileURL.path)
    }
}

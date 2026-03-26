import Foundation
import Testing
@testable import ConnectMate

struct APIKeyServiceTests {
    @Test
    func validateProfileBuildsExpectedAscLoginArguments() async throws {
        let runner = CapturingAPIRunner()
        let service = APIKeyService(runner: runner)
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let privateKeyURL = temporaryDirectory.appendingPathComponent("AuthKey_KEY.p8")
        try Data("PRIVATE KEY".utf8).write(to: privateKeyURL)

        _ = try await service.validate(
            name: "Main",
            issuerID: "ISSUER",
            keyID: "KEY",
            privateKeyPath: privateKeyURL.path
        )

        #expect(runner.capturedArguments == [
            "auth", "login",
            "--name", "Main",
            "--key-id", "KEY",
            "--issuer-id", "ISSUER",
            "--private-key", privateKeyURL.path,
            "--network"
        ])
    }

    @Test
    func validateRejectsMissingRequiredFieldsBeforeInvokingCLI() async throws {
        let runner = CapturingAPIRunner()
        let service = APIKeyService(runner: runner)

        await #expect(throws: APIKeyInputError.missingRequiredFields([.profileName, .issuerID, .keyID, .privateKeyPath])) {
            _ = try await service.validate(
                name: "",
                issuerID: "",
                keyID: "",
                privateKeyPath: ""
            )
        }

        #expect(runner.runCount == 0)
    }

    @Test
    func validateInfersKeyIDAndDefaultNameFromAuthKeyFilename() async throws {
        let runner = CapturingAPIRunner()
        let service = APIKeyService(runner: runner)
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let privateKeyURL = temporaryDirectory.appendingPathComponent("AuthKey_2RU28PXQS7.p8")
        try Data("PRIVATE KEY".utf8).write(to: privateKeyURL)

        _ = try await service.validate(
            name: "",
            issuerID: "ISSUER-ID",
            keyID: "",
            privateKeyPath: privateKeyURL.path
        )

        #expect(runner.capturedArguments == [
            "auth", "login",
            "--name", "2RU28PXQS7",
            "--key-id", "2RU28PXQS7",
            "--issuer-id", "ISSUER-ID",
            "--private-key", privateKeyURL.path,
            "--network"
        ])
    }
}

private final class CapturingAPIRunner: ASCCommandRunning, @unchecked Sendable {
    private(set) var capturedArguments: [String] = []
    private(set) var runCount = 0

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
        runCount += 1
        capturedArguments = arguments
        return ASCCommandResult(
            executablePath: "/usr/local/bin/asc",
            arguments: arguments,
            standardOutput: "{\"ok\":true}",
            standardError: "",
            exitCode: 0,
            duration: 0.01,
            attemptCount: 1
        )
    }
}

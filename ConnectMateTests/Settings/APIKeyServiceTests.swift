import Foundation
import Testing
@testable import ConnectMate

struct APIKeyServiceTests {
    @Test
    func validateProfileBuildsExpectedAscLoginArguments() async throws {
        let runner = CapturingAPIRunner()
        let service = APIKeyService(runner: runner)

        _ = try await service.validate(
            name: "Main",
            issuerID: "ISSUER",
            keyID: "KEY",
            privateKeyPath: "/tmp/AuthKey.p8"
        )

        #expect(runner.capturedArguments == [
            "auth", "login",
            "--name", "Main",
            "--key-id", "KEY",
            "--issuer-id", "ISSUER",
            "--private-key", "/tmp/AuthKey.p8",
            "--network"
        ])
    }
}

private final class CapturingAPIRunner: ASCCommandRunning, @unchecked Sendable {
    private(set) var capturedArguments: [String] = []

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
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

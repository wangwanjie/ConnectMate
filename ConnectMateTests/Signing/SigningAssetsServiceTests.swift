import Foundation
import Testing
@testable import ConnectMate

@MainActor
struct SigningAssetsServiceTests {
    @Test
    func listsBundleIdentifiersFromCLIJSON() async throws {
        let runner = SigningFixtureRunner()
        let service = SigningAssetsService(runner: runner)

        let items = try await service.listBundleIDs()

        #expect(items.count == 1)
        #expect(items[0].id == "BUNDLE_1")
        #expect(items[0].identifier == "com.example.connectmate")
        #expect(items[0].name == "ConnectMate")
        #expect(items[0].platform == "MAC_OS")
    }

    @Test
    func createBundleIdentifierBuildsExpectedArguments() async throws {
        let runner = SigningFixtureRunner()
        let service = SigningAssetsService(runner: runner)

        _ = try await service.createBundleID(
            .init(identifier: "com.example.connectmate", name: "ConnectMate", platform: "MAC_OS")
        )

        #expect(runner.capturedArguments.last == [
            "bundle-ids", "create",
            "--identifier", "com.example.connectmate",
            "--name", "ConnectMate",
            "--platform", "MAC_OS",
            "--output", "json"
        ])
    }

    @Test
    func createsAndMutatesSigningAssetsWithExpectedArguments() async throws {
        let runner = SigningFixtureRunner()
        let service = SigningAssetsService(runner: runner)

        _ = try await service.createCertificate(.init(certificateType: "MAC_APP_DEVELOPMENT", csrPath: "/tmp/dev.csr"))
        _ = try await service.updateCertificateActivation(id: "CERT_1", activated: false)
        _ = try await service.revokeCertificate(id: "CERT_1")
        _ = try await service.registerDevice(.init(name: "My Mac", platform: "MAC_OS", udid: nil, useCurrentMachineUDID: true))
        _ = try await service.updateDevice(id: "DEVICE_1", name: "My MacBook", status: "DISABLED")
        _ = try await service.createProfile(.init(name: "ConnectMate Dev", profileType: "MAC_APP_DEVELOPMENT", bundleID: "BUNDLE_1", certificateIDs: ["CERT_1"], deviceIDs: ["DEVICE_1"]))
        _ = try await service.downloadProfile(id: "PROFILE_1", outputPath: "/tmp/ConnectMate.mobileprovision")
        _ = try await service.deleteProfile(id: "PROFILE_1")

        #expect(runner.capturedArguments == [
            ["certificates", "create", "--certificate-type", "MAC_APP_DEVELOPMENT", "--csr", "/tmp/dev.csr", "--output", "json"],
            ["certificates", "update", "--id", "CERT_1", "--activated", "false", "--output", "json"],
            ["certificates", "revoke", "--id", "CERT_1", "--confirm", "--output", "json"],
            ["devices", "register", "--name", "My Mac", "--udid-from-system", "--platform", "MAC_OS", "--output", "json"],
            ["devices", "update", "--id", "DEVICE_1", "--name", "My MacBook", "--status", "DISABLED", "--output", "json"],
            ["profiles", "create", "--name", "ConnectMate Dev", "--profile-type", "MAC_APP_DEVELOPMENT", "--bundle", "BUNDLE_1", "--certificate", "CERT_1", "--device", "DEVICE_1", "--output", "json"],
            ["profiles", "download", "--id", "PROFILE_1", "--output", "/tmp/ConnectMate.mobileprovision"],
            ["profiles", "delete", "--id", "PROFILE_1", "--confirm", "--output", "json"]
        ])
    }

    @Test
    func listsCertificatesDevicesAndProfiles() async throws {
        let runner = SigningFixtureRunner()
        let service = SigningAssetsService(runner: runner)

        let certificates = try await service.listCertificates()
        let devices = try await service.listDevices()
        let profiles = try await service.listProfiles()

        #expect(certificates.count == 1)
        #expect(certificates[0].id == "CERT_1")
        #expect(certificates[0].certificateType == "MAC_APP_DEVELOPMENT")
        #expect(devices.count == 1)
        #expect(devices[0].id == "DEVICE_1")
        #expect(devices[0].udid == "UDID-1")
        #expect(profiles.count == 1)
        #expect(profiles[0].id == "PROFILE_1")
        #expect(profiles[0].profileType == "MAC_APP_DEVELOPMENT")
    }

    @Test
    func generatesCSRAndManagesBundleIDCapabilitiesWithExpectedArguments() async throws {
        let runner = SigningFixtureRunner()
        let service = SigningAssetsService(runner: runner)

        _ = try await service.generateCSR(
            .init(
                commonName: "ConnectMate Signing",
                keyOutputPath: "/tmp/connectmate.key",
                csrOutputPath: "/tmp/connectmate.csr"
            )
        )
        let capabilities = try await service.listBundleIDCapabilities(bundleID: "BUNDLE_1")
        _ = try await service.addBundleIDCapability(
            .init(bundleID: "BUNDLE_1", capabilityType: "ICLOUD", settingsJSON: "[{\"key\":\"ICLOUD_VERSION\"}]")
        )
        _ = try await service.updateBundleIDCapability(
            .init(id: "CAP_1", capabilityType: "ICLOUD", settingsJSON: "[{\"key\":\"ICLOUD_VERSION\"}]")
        )
        _ = try await service.removeBundleIDCapability(id: "CAP_1")

        #expect(capabilities.count == 1)
        #expect(capabilities[0].id == "CAP_1")
        #expect(capabilities[0].capabilityType == "IN_APP_PURCHASE")
        #expect(runner.capturedArguments == [
            ["certificates", "csr", "generate", "--common-name", "ConnectMate Signing", "--key-out", "/tmp/connectmate.key", "--csr-out", "/tmp/connectmate.csr", "--output", "json"],
            ["bundle-ids", "capabilities", "list", "--bundle", "BUNDLE_1", "--paginate", "--output", "json"],
            ["bundle-ids", "capabilities", "add", "--bundle", "BUNDLE_1", "--capability", "ICLOUD", "--settings", "[{\"key\":\"ICLOUD_VERSION\"}]", "--output", "json"],
            ["bundle-ids", "capabilities", "update", "--id", "CAP_1", "--capability", "ICLOUD", "--settings", "[{\"key\":\"ICLOUD_VERSION\"}]", "--output", "json"],
            ["bundle-ids", "capabilities", "remove", "--id", "CAP_1", "--confirm", "--output", "json"]
        ])
    }
}

private final class SigningFixtureRunner: ASCCommandRunning, @unchecked Sendable {
    private(set) var capturedArguments: [[String]] = []

    func run(arguments: [String], standardInput: Data?, extraEnvironment: [String : String]) async throws -> ASCCommandResult {
        capturedArguments.append(arguments)
        let output: String

        switch Array(arguments.prefix(2)) {
        case ["bundle-ids", "list"]:
            output = """
            {"data":[{"type":"bundleIds","id":"BUNDLE_1","attributes":{"name":"ConnectMate","identifier":"com.example.connectmate","platform":"MAC_OS","seedId":"TEAMID"}}]}
            """
        case ["certificates", "list"]:
            output = """
            {"data":[{"type":"certificates","id":"CERT_1","attributes":{"name":"Apple Development: Example","certificateType":"MAC_APP_DEVELOPMENT","displayName":"Example","serialNumber":"SERIAL","platform":"MAC_OS","expirationDate":"2026-12-31T00:00:00.000+00:00"}}]}
            """
        case ["devices", "list"]:
            output = """
            {"data":[{"type":"devices","id":"DEVICE_1","attributes":{"name":"My Mac","platform":"MAC_OS","udid":"UDID-1","deviceClass":"MAC","status":"ENABLED","model":"MacBook Pro","addedDate":"2026-01-01T00:00:00.000+00:00"}}]}
            """
        case ["profiles", "list"]:
            output = """
            {"data":[{"type":"profiles","id":"PROFILE_1","attributes":{"name":"ConnectMate Dev","platform":"MAC_OS","profileType":"MAC_APP_DEVELOPMENT","profileState":"ACTIVE"}}]}
            """
        case ["bundle-ids", "capabilities"]:
            output = """
            {"data":[{"type":"bundleIdCapabilities","id":"CAP_1","attributes":{"capabilityType":"IN_APP_PURCHASE"}}]}
            """
        default:
            output = #"{"data":{"id":"ok"}}"#
        }

        return ASCCommandResult(
            executablePath: "/usr/local/bin/asc",
            arguments: arguments,
            standardOutput: output,
            standardError: "",
            exitCode: 0,
            duration: 0.01,
            attemptCount: 1
        )
    }
}

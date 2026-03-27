import Foundation
import GRDB

@MainActor
final class SigningAssetsService {
    nonisolated struct CreateBundleIDRequest: Equatable, Sendable {
        let identifier: String
        let name: String
        let platform: String?
    }

    nonisolated struct CreateCertificateRequest: Equatable, Sendable {
        let certificateType: String
        let csrPath: String
    }

    nonisolated struct GenerateCSRRequest: Equatable, Sendable {
        let commonName: String
        let keyOutputPath: String
        let csrOutputPath: String
    }

    nonisolated struct RegisterDeviceRequest: Equatable, Sendable {
        let name: String
        let platform: String
        let udid: String?
        let useCurrentMachineUDID: Bool
    }

    nonisolated struct CreateProfileRequest: Equatable, Sendable {
        let name: String
        let profileType: String
        let bundleID: String
        let certificateIDs: [String]
        let deviceIDs: [String]
    }

    nonisolated struct AddBundleIDCapabilityRequest: Equatable, Sendable {
        let bundleID: String
        let capabilityType: String
        let settingsJSON: String?
    }

    nonisolated struct UpdateBundleIDCapabilityRequest: Equatable, Sendable {
        let id: String
        let capabilityType: String?
        let settingsJSON: String?
    }

    private let runner: any ASCCommandRunning
    private let decoder = JSONDecoder()

    init(runner: any ASCCommandRunning) {
        self.runner = runner
    }

    static func makeDefault() -> SigningAssetsService {
        let databaseManager = DatabaseManager.shared
        let activeProfile: APIKeyRecord? = try? databaseManager.dbQueue.read { db in
            try APIKeyRecord
                .filter(Column("is_active") == true)
                .fetchOne(db)
        }

        let configuration = ASCCommandConfiguration(
            settings: .shared,
            apiKey: activeProfile,
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )

        return SigningAssetsService(
            runner: ASCCommandRunner(
                configuration: configuration,
                logRepository: databaseManager.commandLogRepository
            )
        )
    }

    func listBundleIDs() async throws -> [BundleIDSummary] {
        let result = try await runner.run(
            arguments: ["bundle-ids", "list", "--paginate", "--output", "json"],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let response = try decoder.decode(BundleIDListResponse.self, from: Data(result.standardOutput.utf8))
        return response.data.map {
            BundleIDSummary(
                id: $0.id,
                name: $0.attributes.name,
                identifier: $0.attributes.identifier,
                platform: $0.attributes.platform,
                seedID: $0.attributes.seedID
            )
        }
    }

    func createBundleID(_ request: CreateBundleIDRequest) async throws -> ASCCommandResult {
        var arguments = [
            "bundle-ids", "create",
            "--identifier", request.identifier,
            "--name", request.name
        ]
        if let platform = request.platform, !platform.isEmpty {
            arguments.append(contentsOf: ["--platform", platform])
        }
        arguments.append(contentsOf: ["--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func listCertificates() async throws -> [CertificateSummary] {
        let result = try await runner.run(
            arguments: ["certificates", "list", "--paginate", "--output", "json"],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let response = try decoder.decode(CertificateListResponse.self, from: Data(result.standardOutput.utf8))
        return response.data.map {
            CertificateSummary(
                id: $0.id,
                name: $0.attributes.name,
                certificateType: $0.attributes.certificateType,
                displayName: $0.attributes.displayName,
                serialNumber: $0.attributes.serialNumber,
                platform: $0.attributes.platform,
                expirationDate: $0.attributes.expirationDate
            )
        }
    }

    func createCertificate(_ request: CreateCertificateRequest) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "certificates", "create",
                "--certificate-type", request.certificateType,
                "--csr", request.csrPath,
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func generateCSR(_ request: GenerateCSRRequest) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "certificates", "csr", "generate",
                "--common-name", request.commonName,
                "--key-out", request.keyOutputPath,
                "--csr-out", request.csrOutputPath,
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func updateCertificateActivation(id: String, activated: Bool) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "certificates", "update",
                "--id", id,
                "--activated", activated ? "true" : "false",
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func revokeCertificate(id: String) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "certificates", "revoke",
                "--id", id,
                "--confirm",
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func listDevices() async throws -> [RegisteredDeviceSummary] {
        let result = try await runner.run(
            arguments: ["devices", "list", "--paginate", "--output", "json"],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let response = try decoder.decode(DeviceListResponse.self, from: Data(result.standardOutput.utf8))
        return response.data.map {
            RegisteredDeviceSummary(
                id: $0.id,
                name: $0.attributes.name,
                platform: $0.attributes.platform,
                udid: $0.attributes.udid,
                deviceClass: $0.attributes.deviceClass,
                status: $0.attributes.status,
                model: $0.attributes.model,
                addedDate: $0.attributes.addedDate
            )
        }
    }

    func registerDevice(_ request: RegisterDeviceRequest) async throws -> ASCCommandResult {
        var arguments = [
            "devices", "register",
            "--name", request.name
        ]
        if request.useCurrentMachineUDID {
            arguments.append("--udid-from-system")
        } else if let udid = request.udid, !udid.isEmpty {
            arguments.append(contentsOf: ["--udid", udid])
        }
        arguments.append(contentsOf: ["--platform", request.platform, "--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func updateDevice(id: String, name: String?, status: String?) async throws -> ASCCommandResult {
        var arguments = ["devices", "update", "--id", id]
        if let name, !name.isEmpty {
            arguments.append(contentsOf: ["--name", name])
        }
        if let status, !status.isEmpty {
            arguments.append(contentsOf: ["--status", status])
        }
        arguments.append(contentsOf: ["--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func listProfiles() async throws -> [ProvisioningProfileSummary] {
        let result = try await runner.run(
            arguments: ["profiles", "list", "--paginate", "--output", "json"],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let response = try decoder.decode(ProfileListResponse.self, from: Data(result.standardOutput.utf8))
        return response.data.map {
            ProvisioningProfileSummary(
                id: $0.id,
                name: $0.attributes.name,
                platform: $0.attributes.platform,
                profileType: $0.attributes.profileType,
                profileState: $0.attributes.profileState
            )
        }
    }

    func createProfile(_ request: CreateProfileRequest) async throws -> ASCCommandResult {
        var arguments = [
            "profiles", "create",
            "--name", request.name,
            "--profile-type", request.profileType,
            "--bundle", request.bundleID,
            "--certificate", request.certificateIDs.joined(separator: ",")
        ]
        if !request.deviceIDs.isEmpty {
            arguments.append(contentsOf: ["--device", request.deviceIDs.joined(separator: ",")])
        }
        arguments.append(contentsOf: ["--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func listBundleIDCapabilities(bundleID: String) async throws -> [BundleIDCapabilitySummary] {
        let result = try await runner.run(
            arguments: [
                "bundle-ids", "capabilities", "list",
                "--bundle", bundleID,
                "--paginate",
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
        let response = try decoder.decode(BundleIDCapabilityListResponse.self, from: Data(result.standardOutput.utf8))
        return response.data.map {
            BundleIDCapabilitySummary(
                id: $0.id,
                capabilityType: $0.attributes.capabilityType
            )
        }
    }

    func addBundleIDCapability(_ request: AddBundleIDCapabilityRequest) async throws -> ASCCommandResult {
        var arguments = [
            "bundle-ids", "capabilities", "add",
            "--bundle", request.bundleID,
            "--capability", request.capabilityType
        ]
        if let settingsJSON = request.settingsJSON, !settingsJSON.isEmpty {
            arguments.append(contentsOf: ["--settings", settingsJSON])
        }
        arguments.append(contentsOf: ["--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func updateBundleIDCapability(_ request: UpdateBundleIDCapabilityRequest) async throws -> ASCCommandResult {
        var arguments = [
            "bundle-ids", "capabilities", "update",
            "--id", request.id
        ]
        if let capabilityType = request.capabilityType, !capabilityType.isEmpty {
            arguments.append(contentsOf: ["--capability", capabilityType])
        }
        if let settingsJSON = request.settingsJSON, !settingsJSON.isEmpty {
            arguments.append(contentsOf: ["--settings", settingsJSON])
        }
        arguments.append(contentsOf: ["--output", "json"])
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func removeBundleIDCapability(id: String) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "bundle-ids", "capabilities", "remove",
                "--id", id,
                "--confirm",
                "--output", "json"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func downloadProfile(id: String, outputPath: String) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: ["profiles", "download", "--id", id, "--output", outputPath],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func deleteProfile(id: String) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: ["profiles", "delete", "--id", id, "--confirm", "--output", "json"],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }
}

private nonisolated struct BundleIDListResponse: Decodable {
    let data: [BundleIDResource]
}

private nonisolated struct BundleIDResource: Decodable {
    let id: String
    let attributes: BundleIDAttributes
}

private nonisolated struct BundleIDAttributes: Decodable {
    let name: String
    let identifier: String
    let platform: String
    let seedID: String?

    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case platform
        case seedID = "seedId"
    }
}

private nonisolated struct CertificateListResponse: Decodable {
    let data: [CertificateResource]
}

private nonisolated struct CertificateResource: Decodable {
    let id: String
    let attributes: CertificateAttributes
}

private nonisolated struct CertificateAttributes: Decodable {
    let name: String
    let certificateType: String
    let displayName: String?
    let serialNumber: String?
    let platform: String?
    let expirationDate: String?
}

private nonisolated struct DeviceListResponse: Decodable {
    let data: [DeviceResource]
}

private nonisolated struct DeviceResource: Decodable {
    let id: String
    let attributes: DeviceAttributes
}

private nonisolated struct DeviceAttributes: Decodable {
    let name: String
    let platform: String
    let udid: String
    let deviceClass: String?
    let status: String
    let model: String?
    let addedDate: String?
}

private nonisolated struct ProfileListResponse: Decodable {
    let data: [ProfileResource]
}

private nonisolated struct BundleIDCapabilityListResponse: Decodable {
    let data: [BundleIDCapabilityResource]
}

private nonisolated struct ProfileResource: Decodable {
    let id: String
    let attributes: ProfileAttributes
}

private nonisolated struct BundleIDCapabilityResource: Decodable {
    let id: String
    let attributes: BundleIDCapabilityAttributes
}

private nonisolated struct ProfileAttributes: Decodable {
    let name: String
    let platform: String?
    let profileType: String
    let profileState: String?
}

private nonisolated struct BundleIDCapabilityAttributes: Decodable {
    let capabilityType: String
}

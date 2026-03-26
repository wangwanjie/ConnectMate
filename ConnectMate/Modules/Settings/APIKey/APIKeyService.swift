import Foundation
import GRDB

protocol ASCCommandRunning {
    func run(
        arguments: [String],
        standardInput: Data?,
        extraEnvironment: [String: String]
    ) async throws -> ASCCommandResult
}

extension ASCCommandRunner: ASCCommandRunning {}

enum APIKeyInputField: Equatable {
    case profileName
    case issuerID
    case keyID
    case privateKeyPath

    var title: String {
        switch self {
        case .profileName:
            return L10n.APIKeys.profileName
        case .issuerID:
            return L10n.APIKeys.issuerID
        case .keyID:
            return L10n.APIKeys.keyID
        case .privateKeyPath:
            return L10n.APIKeys.privateKeyPath
        }
    }
}

enum APIKeyInputError: LocalizedError, Equatable {
    case missingRequiredFields([APIKeyInputField])
    case privateKeyFileMissing(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields(let fields):
            let titles = fields.map(\.title).joined(separator: " / ")
            return String(format: L10n.APIKeys.missingRequiredFields, titles)
        case .privateKeyFileMissing(let path):
            return String(format: L10n.APIKeys.privateKeyFileMissing, path)
        }
    }
}

final class APIKeyService {
    private let runner: any ASCCommandRunning
    private let dbWriter: any DatabaseWriter
    private let fileManager: FileManager

    init(
        runner: any ASCCommandRunning,
        dbWriter: any DatabaseWriter = DatabaseManager.shared.dbQueue,
        fileManager: FileManager = .default
    ) {
        self.runner = runner
        self.dbWriter = dbWriter
        self.fileManager = fileManager
    }

    func validate(name: String, issuerID: String, keyID: String, privateKeyPath: String) async throws -> ASCCommandResult {
        let input = try normalizeInput(
            name: name,
            issuerID: issuerID,
            keyID: keyID,
            privateKeyPath: privateKeyPath
        )

        return try await runner.run(
            arguments: [
                "auth", "login",
                "--name", input.name,
                "--key-id", input.keyID,
                "--issuer-id", input.issuerID,
                "--private-key", input.privateKeyPath,
                "--network"
            ],
            standardInput: nil,
            extraEnvironment: [:]
        )
    }

    func status(validateNetwork: Bool = true) async throws -> ASCCommandResult {
        var arguments = ["auth", "status"]
        if validateNetwork {
            arguments.append("--validate")
        }
        return try await runner.run(arguments: arguments, standardInput: nil, extraEnvironment: [:])
    }

    func doctor() async throws -> ASCCommandResult {
        try await runner.run(arguments: ["auth", "doctor"], standardInput: nil, extraEnvironment: [:])
    }

    func fetchProfiles() throws -> [APIKeyRecord] {
        try dbWriter.read { db in
            try APIKeyRecord
                .order(Column("is_active").desc, Column("name").asc)
                .fetchAll(db)
        }
    }

    func saveProfile(
        id: Int64? = nil,
        name: String,
        issuerID: String,
        keyID: String,
        privateKeyPath: String,
        activate: Bool
    ) throws -> APIKeyRecord {
        let input = try normalizeInput(
            name: name,
            issuerID: issuerID,
            keyID: keyID,
            privateKeyPath: privateKeyPath
        )

        var record = APIKeyRecord(
            id: id,
            name: input.name,
            issuerID: input.issuerID,
            keyID: input.keyID,
            p8Path: input.privateKeyPath,
            profileName: input.name,
            isActive: activate,
            lastVerifiedAt: nil,
            lastValidationStatus: nil
        )

        try dbWriter.write { db in
            if activate {
                try db.execute(sql: "UPDATE api_keys SET is_active = 0")
            }
            try record.save(db)
        }
        return record
    }

    func markValidationStatus(id: Int64, success: Bool, message: String) throws {
        try dbWriter.write { db in
            try db.execute(
                sql: """
                UPDATE api_keys
                SET last_verified_at = ?, last_validation_status = ?
                WHERE id = ?
                """,
                arguments: [Date(), success ? "success: \(message)" : "failure: \(message)", id]
            )
        }
    }

    func activateProfile(id: Int64) throws {
        try dbWriter.write { db in
            try db.execute(sql: "UPDATE api_keys SET is_active = 0")
            try db.execute(sql: "UPDATE api_keys SET is_active = 1 WHERE id = ?", arguments: [id])
        }
    }

    func deleteProfile(id: Int64) throws {
        try dbWriter.write { db in
            _ = try APIKeyRecord.deleteOne(db, key: id)
        }
    }

    static func inferredKeyID(from privateKeyPath: String) -> String? {
        let fileName = URL(fileURLWithPath: privateKeyPath).lastPathComponent
        guard fileName.hasPrefix("AuthKey_"), fileName.hasSuffix(".p8") else {
            return nil
        }

        let startIndex = fileName.index(fileName.startIndex, offsetBy: "AuthKey_".count)
        let endIndex = fileName.index(fileName.endIndex, offsetBy: -".p8".count)
        let keyID = String(fileName[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        return keyID.isEmpty ? nil : keyID
    }

    private func normalizeInput(
        name: String,
        issuerID: String,
        keyID: String,
        privateKeyPath: String
    ) throws -> NormalizedAPIKeyInput {
        let resolvedPrivateKeyPath = Self.resolvePrivateKeyPath(privateKeyPath)
        var resolvedKeyID = keyID.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedKeyID.isEmpty, let inferredKeyID = Self.inferredKeyID(from: resolvedPrivateKeyPath) {
            resolvedKeyID = inferredKeyID
        }

        var resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedName.isEmpty {
            resolvedName = resolvedKeyID
        }

        let resolvedIssuerID = issuerID.trimmingCharacters(in: .whitespacesAndNewlines)
        var missingFields: [APIKeyInputField] = []

        if resolvedName.isEmpty {
            missingFields.append(.profileName)
        }
        if resolvedIssuerID.isEmpty {
            missingFields.append(.issuerID)
        }
        if resolvedKeyID.isEmpty {
            missingFields.append(.keyID)
        }
        if resolvedPrivateKeyPath.isEmpty {
            missingFields.append(.privateKeyPath)
        }

        if !missingFields.isEmpty {
            throw APIKeyInputError.missingRequiredFields(missingFields)
        }

        guard fileManager.fileExists(atPath: resolvedPrivateKeyPath) else {
            throw APIKeyInputError.privateKeyFileMissing(resolvedPrivateKeyPath)
        }

        return NormalizedAPIKeyInput(
            name: resolvedName,
            issuerID: resolvedIssuerID,
            keyID: resolvedKeyID,
            privateKeyPath: resolvedPrivateKeyPath
        )
    }

    private static func resolvePrivateKeyPath(_ privateKeyPath: String) -> String {
        let trimmedPath = privateKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return ""
        }

        let expandedPath = (trimmedPath as NSString).expandingTildeInPath
        if expandedPath.hasPrefix("/") {
            return URL(fileURLWithPath: expandedPath).standardizedFileURL.path
        }

        return URL(
            fileURLWithPath: expandedPath,
            relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        ).standardizedFileURL.path
    }
}

private struct NormalizedAPIKeyInput {
    let name: String
    let issuerID: String
    let keyID: String
    let privateKeyPath: String
}

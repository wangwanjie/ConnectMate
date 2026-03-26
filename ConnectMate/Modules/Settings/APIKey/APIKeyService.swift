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

final class APIKeyService {
    private let runner: any ASCCommandRunning
    private let dbWriter: any DatabaseWriter

    init(
        runner: any ASCCommandRunning,
        dbWriter: any DatabaseWriter = DatabaseManager.shared.dbQueue
    ) {
        self.runner = runner
        self.dbWriter = dbWriter
    }

    func validate(name: String, issuerID: String, keyID: String, privateKeyPath: String) async throws -> ASCCommandResult {
        try await runner.run(
            arguments: [
                "auth", "login",
                "--name", name,
                "--key-id", keyID,
                "--issuer-id", issuerID,
                "--private-key", privateKeyPath,
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
        var record = APIKeyRecord(
            id: id,
            name: name,
            issuerID: issuerID,
            keyID: keyID,
            p8Path: privateKeyPath,
            profileName: name,
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
}

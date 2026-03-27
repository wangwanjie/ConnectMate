import Foundation
import GRDB

struct BuildRepository {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: (any DatabaseWriter)? = nil) {
        if let dbWriter {
            self.dbWriter = dbWriter
        } else {
            self.dbWriter = DatabaseManager.shared.dbQueue
        }
    }

    func replaceCache(with payloads: [ASCBuildPayload], accountKeyID: Int64?, appID: String) throws {
        try dbWriter.write { db in
            var request = BuildRecord.filter(Column("app_asc_id") == appID)
            if let accountKeyID {
                request = request.filter(Column("account_key_id") == accountKeyID)
            } else {
                request = request.filter(sql: "account_key_id IS NULL")
            }
            _ = try request.deleteAll(db)

            let now = Date()
            for payload in payloads {
                var record = BuildRecord(
                    id: nil,
                    accountKeyID: accountKeyID,
                    ascID: payload.id,
                    appAscID: payload.appID.isEmpty ? appID : payload.appID,
                    version: payload.version,
                    buildNumber: payload.buildNumber,
                    processingState: payload.processingState,
                    platform: payload.platform,
                    expired: payload.expired,
                    uploadedAt: payload.uploadedAt,
                    rawJSON: payload.rawJSON,
                    cachedAt: now
                )
                try record.insert(db)
            }
        }
    }

    func fetchAll(accountKeyID: Int64? = nil, appID: String, status: BuildProcessingState? = nil) throws -> [BuildRecord] {
        try dbWriter.read { db in
            var request = BuildRecord
                .filter(Column("app_asc_id") == appID)

            if let accountKeyID {
                request = request.filter(Column("account_key_id") == accountKeyID)
            } else {
                request = request.filter(sql: "account_key_id IS NULL")
            }

            if let status {
                switch status {
                case .expired:
                    request = request.filter(Column("expired") == true)
                case .unknown(let rawValue):
                    request = request
                        .filter(Column("expired") == false)
                        .filter(Column("processing_state") == rawValue)
                case .processing:
                    request = request
                        .filter(Column("expired") == false)
                        .filter(Column("processing_state") == "PROCESSING")
                case .valid:
                    request = request
                        .filter(Column("expired") == false)
                        .filter(Column("processing_state") == "VALID")
                case .invalid:
                    request = request
                        .filter(Column("expired") == false)
                        .filter(sql: "processing_state IN ('INVALID', 'FAILED')")
                }
            }

            return try request
                .order(Column("id").asc)
                .fetchAll(db)
        }
    }
}

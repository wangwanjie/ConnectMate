import Foundation
import GRDB

struct AppRepository {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter = DatabaseManager.shared.dbQueue) {
        self.dbWriter = dbWriter
    }

    func replaceCache(with payloads: [ASCAppPayload], accountKeyID: Int64?) throws {
        try dbWriter.write { db in
            if let accountKeyID {
                _ = try AppRecord
                    .filter(Column("account_key_id") == accountKeyID)
                    .deleteAll(db)
            } else {
                _ = try AppRecord
                    .filter(sql: "account_key_id IS NULL")
                    .deleteAll(db)
            }

            let now = Date()
            for payload in payloads {
                var record = AppRecord(
                    id: nil,
                    accountKeyID: accountKeyID,
                    ascID: payload.id,
                    name: payload.name,
                    bundleID: payload.bundleID,
                    sku: payload.sku,
                    platform: payload.platform ?? "UNKNOWN",
                    appState: payload.appState,
                    iconURL: payload.iconURL,
                    rawJSON: payload.rawJSON,
                    cachedAt: now
                )
                try record.insert(db)
            }
        }
    }

    func fetchAll(accountKeyID: Int64? = nil, search: String? = nil) throws -> [AppRecord] {
        try dbWriter.read { db in
            var request = AppRecord.all()

            if let accountKeyID {
                request = request.filter(Column("account_key_id") == accountKeyID)
            } else {
                request = request.filter(sql: "account_key_id IS NULL")
            }

            if let search = search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
                let pattern = "%\(search)%"
                request = request.filter(
                    sql: "name LIKE ? COLLATE NOCASE OR bundle_id LIKE ? COLLATE NOCASE OR sku LIKE ? COLLATE NOCASE",
                    arguments: [pattern, pattern, pattern]
                )
            }

            return try request
                .order(Column("name").asc)
                .fetchAll(db)
        }
    }
}

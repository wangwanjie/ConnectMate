import Foundation
import GRDB

struct BuildRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "builds"

    var id: Int64?
    var accountKeyID: Int64?
    var ascID: String
    var appAscID: String
    var version: String
    var buildNumber: String
    var processingState: String
    var platform: String?
    var expired: Bool
    var uploadedAt: Date?
    var rawJSON: String?
    var cachedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case ascID = "asc_id"
        case appAscID = "app_asc_id"
        case version
        case buildNumber = "build_number"
        case processingState = "processing_state"
        case platform
        case expired
        case uploadedAt = "uploaded_at"
        case rawJSON = "raw_json"
        case cachedAt = "cached_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

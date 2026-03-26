import Foundation
import GRDB

struct BetaGroupRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "beta_groups"

    var id: Int64?
    var accountKeyID: Int64?
    var groupID: String
    var appAscID: String?
    var name: String
    var isInternal: Bool
    var rawJSON: String?
    var cachedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case groupID = "group_id"
        case appAscID = "app_asc_id"
        case name
        case isInternal = "is_internal"
        case rawJSON = "raw_json"
        case cachedAt = "cached_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

import Foundation
import GRDB

struct AppRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "apps"

    var id: Int64?
    var accountKeyID: Int64?
    var ascID: String
    var name: String
    var bundleID: String
    var sku: String?
    var platform: String
    var appState: String?
    var iconURL: String?
    var rawJSON: String?
    var cachedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case ascID = "asc_id"
        case name
        case bundleID = "bundle_id"
        case sku
        case platform
        case appState = "app_state"
        case iconURL = "icon_url"
        case rawJSON = "raw_json"
        case cachedAt = "cached_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

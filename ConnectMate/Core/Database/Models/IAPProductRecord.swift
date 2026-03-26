import Foundation
import GRDB

struct IAPProductRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "iap_products"

    var id: Int64?
    var accountKeyID: Int64?
    var iapID: String
    var appAscID: String
    var productID: String
    var referenceName: String?
    var productType: String
    var status: String?
    var priceSummary: String?
    var rawJSON: String?
    var cachedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case iapID = "iap_id"
        case appAscID = "app_asc_id"
        case productID = "product_id"
        case referenceName = "reference_name"
        case productType = "product_type"
        case status
        case priceSummary = "price_summary"
        case rawJSON = "raw_json"
        case cachedAt = "cached_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

import Foundation
import GRDB

struct TesterRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "testers"

    var id: Int64?
    var accountKeyID: Int64?
    var testerID: String
    var appAscID: String?
    var email: String
    var firstName: String?
    var lastName: String?
    var inviteStatus: String?
    var rawJSON: String?
    var cachedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case testerID = "tester_id"
        case appAscID = "app_asc_id"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case inviteStatus = "invite_status"
        case rawJSON = "raw_json"
        case cachedAt = "cached_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

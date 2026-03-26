import Foundation
import GRDB

struct ReviewSubmissionRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "review_submissions"

    var id: Int64?
    var accountKeyID: Int64?
    var submissionID: String
    var appAscID: String
    var versionID: String?
    var buildID: String?
    var status: String
    var rawJSON: String?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountKeyID = "account_key_id"
        case submissionID = "submission_id"
        case appAscID = "app_asc_id"
        case versionID = "version_id"
        case buildID = "build_id"
        case status
        case rawJSON = "raw_json"
        case updatedAt = "updated_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

import Foundation
import GRDB

struct APIKeyRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "api_keys"

    var id: Int64?
    var name: String
    var issuerID: String
    var keyID: String
    var p8Path: String
    var p8Bookmark: Data?
    var profileName: String?
    var isActive: Bool
    var lastVerifiedAt: Date?
    var lastValidationStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case issuerID = "issuer_id"
        case keyID = "key_id"
        case p8Path = "p8_path"
        case p8Bookmark = "p8_bookmark"
        case profileName = "profile_name"
        case isActive = "is_active"
        case lastVerifiedAt = "last_verified_at"
        case lastValidationStatus = "last_validation_status"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    var displayName: String {
        profileName ?? name
    }

    var resolvedP8Path: String {
        BookmarkedFileReference.resolvePath(path: p8Path, bookmarkData: p8Bookmark)
    }
}

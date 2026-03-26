import Foundation
import GRDB

struct CommandLogRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Sendable {
    static let databaseTableName = "command_logs"

    var id: Int64?
    var command: String
    var argumentsJSON: String
    var stdoutText: String
    var stderrText: String
    var exitCode: Int32?
    var durationMs: Int
    var status: String
    var executedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case command
        case argumentsJSON = "arguments_json"
        case stdoutText = "stdout_text"
        case stderrText = "stderr_text"
        case exitCode = "exit_code"
        case durationMs = "duration_ms"
        case status
        case executedAt = "executed_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

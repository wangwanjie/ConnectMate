import Foundation
import GRDB

struct CommandLogRepository {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    func insert(_ record: inout CommandLogRecord) throws {
        try dbWriter.write { db in
            try record.insert(db)
        }
    }

    func record(
        command: String,
        arguments: [String],
        stdout: String,
        stderr: String,
        exitCode: Int32?,
        durationMs: Int,
        status: String,
        executedAt: Date = Date()
    ) throws {
        let argumentsData = try JSONEncoder().encode(arguments)
        let argumentsJSON = String(decoding: argumentsData, as: UTF8.self)
        var record = CommandLogRecord(
            id: nil,
            command: command,
            argumentsJSON: argumentsJSON,
            stdoutText: stdout,
            stderrText: stderr,
            exitCode: exitCode,
            durationMs: durationMs,
            status: status,
            executedAt: executedAt
        )
        try insert(&record)
    }

    func fetchRecent(limit: Int = 200) throws -> [CommandLogRecord] {
        try dbWriter.read { db in
            try CommandLogRecord
                .order(sql: "executed_at DESC")
                .limit(limit)
                .fetchAll(db)
        }
    }

    @discardableResult
    func cleanup(olderThan cutoffDate: Date) throws -> Int {
        try dbWriter.write { db in
            try CommandLogRecord
                .filter(sql: "executed_at < ?", arguments: [cutoffDate])
                .deleteAll(db)
        }
    }
}

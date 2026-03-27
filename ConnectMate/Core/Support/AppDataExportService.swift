import Foundation
import GRDB

struct AppDataExportService {
    static let exportedTableNames = [
        "api_keys",
        "apps",
        "builds",
        "review_submissions",
        "testers",
        "beta_groups",
        "iap_products",
        "command_logs"
    ]

    private let dbWriter: any DatabaseWriter

    init(dbWriter: (any DatabaseWriter)? = nil) {
        self.dbWriter = dbWriter ?? DatabaseManager.shared.dbQueue
    }

    func exportAllData() throws -> URL {
        let exportURL = try makeExportURL(prefix: "ConnectMate-export", pathExtension: "json")
        return try exportAllData(to: exportURL)
    }

    func exportAllData(to exportURL: URL) throws -> URL {
        let payload = try dbWriter.read { db -> [String: [[String: String]]] in
            func fetchTable(_ name: String) throws -> [[String: String]] {
                try Row.fetchAll(db, sql: "SELECT * FROM \(name)").map { row in
                    var object: [String: String] = [:]
                    for column in row.columnNames {
                        object[column] = row[column].map { String(describing: $0) } ?? ""
                    }
                    return object
                }
            }

            return [
                "api_keys": try fetchTable("api_keys"),
                "apps": try fetchTable("apps"),
                "builds": try fetchTable("builds"),
                "review_submissions": try fetchTable("review_submissions"),
                "testers": try fetchTable("testers"),
                "beta_groups": try fetchTable("beta_groups"),
                "iap_products": try fetchTable("iap_products"),
                "command_logs": try fetchTable("command_logs")
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        let directoryURL = exportURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: exportURL)
        return exportURL
    }

    func exportCommandLogs() throws -> URL {
        let exportURL = try makeExportURL(prefix: "ConnectMate-command-logs", pathExtension: "txt")
        let logs = try dbWriter.read { db in
            try CommandLogRecord
                .order(sql: "executed_at DESC")
                .fetchAll(db)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let body: String = logs.map { log in
            let timestamp = formatter.string(from: log.executedAt)
            return """
            [\(timestamp)] \(log.status.uppercased()) \(log.command)
            arguments: \(log.argumentsJSON)
            exit_code: \(log.exitCode.map(String.init) ?? "n/a")
            duration_ms: \(log.durationMs)
            stdout:
            \(log.stdoutText.isEmpty ? "(empty)" : log.stdoutText)
            stderr:
            \(log.stderrText.isEmpty ? "(empty)" : log.stderrText)
            """
        }.joined(separator: "\n\n----------------------------------------\n\n")

        try body.write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }

    private func makeExportURL(prefix: String, pathExtension: String) throws -> URL {
        let directory = try FileManager.default.url(
            for: .downloadsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return directory
            .appendingPathComponent("\(prefix)-\(formatter.string(from: Date()))")
            .appendingPathExtension(pathExtension)
    }
}

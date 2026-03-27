import Foundation
import GRDB
import Testing
@testable import ConnectMate

struct AppDataExportServiceTests {
    @Test
    func exportsAllDataToExplicitDestination() throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)
        try dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO apps (asc_id, name, bundle_id, platform, app_state, cached_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: ["123", "ConnectMate", "cn.vanjay.connectmate", "ios", "readyForSale", Date()]
            )
        }

        let service = AppDataExportService(dbWriter: dbQueue)
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")

        let exportedURL = try service.exportAllData(to: destinationURL)
        let data = try Data(contentsOf: destinationURL)
        let payload = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(exportedURL == destinationURL)
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(payload["apps"] != nil)
        try? FileManager.default.removeItem(at: destinationURL)
    }
}

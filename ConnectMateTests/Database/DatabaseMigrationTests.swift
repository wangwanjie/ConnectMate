import GRDB
import Testing
@testable import ConnectMate

struct DatabaseMigrationTests {
    @Test
    func migrationsCreateCoreTables() throws {
        let dbQueue = try DatabaseQueue()
        try DatabaseMigrator.connectMate.migrate(dbQueue)

        try dbQueue.read { db in
            let hasAPIKeys = try db.tableExists("api_keys")
            let hasApps = try db.tableExists("apps")
            let hasBuilds = try db.tableExists("builds")
            let hasCommandLogs = try db.tableExists("command_logs")
            let buildColumns = Set(try Row
                .fetchAll(db, sql: "PRAGMA table_info(builds)")
                .compactMap { row in row["name"] as String? })

            #expect(hasAPIKeys)
            #expect(hasApps)
            #expect(hasBuilds)
            #expect(hasCommandLogs)
            #expect(Set(try Row.fetchAll(db, sql: "PRAGMA table_info(api_keys)").compactMap { row in row["name"] as String? }).contains("p8_bookmark"))
            #expect(buildColumns.contains("platform"))
            #expect(buildColumns.contains("expired"))
        }
    }
}

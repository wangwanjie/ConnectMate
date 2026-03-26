import Foundation
import GRDB

final class DatabaseManager {
    static let shared = try! DatabaseManager()

    let dbQueue: DatabaseQueue

    init(
        dbQueue: DatabaseQueue? = nil,
        fileManager: FileManager = .default,
        appSupportDirectory: URL? = nil
    ) throws {
        if let dbQueue {
            self.dbQueue = dbQueue
        } else {
            let databaseURL = try Self.makeDatabaseURL(fileManager: fileManager, appSupportDirectory: appSupportDirectory)
            var configuration = Configuration()
            configuration.foreignKeysEnabled = true
            configuration.label = "ConnectMate.Database"
            self.dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: configuration)
        }

        try DatabaseMigrator.connectMate.migrate(self.dbQueue)
    }

    var commandLogRepository: CommandLogRepository {
        CommandLogRepository(dbWriter: dbQueue)
    }

    private static func makeDatabaseURL(fileManager: FileManager, appSupportDirectory: URL?) throws -> URL {
        let rootDirectory: URL

        if let appSupportDirectory {
            rootDirectory = appSupportDirectory
        } else {
            rootDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        let databaseDirectory = rootDirectory.appendingPathComponent("ConnectMate", isDirectory: true)
        try fileManager.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        return databaseDirectory.appendingPathComponent("ConnectMate.sqlite")
    }
}

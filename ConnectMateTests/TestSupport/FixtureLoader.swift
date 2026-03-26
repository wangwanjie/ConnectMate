import Foundation

enum FixtureLoader {
    static func data(named name: String) throws -> Data {
        try Data(contentsOf: url(named: name))
    }

    static func string(named name: String) throws -> String {
        let data = try data(named: name)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "FixtureLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fixture \(name) is not valid UTF-8"])
        }
        return string
    }

    static func url(named name: String) throws -> URL {
        let fixturesDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
        let fixtureURL = fixturesDirectory.appendingPathComponent(name)

        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            throw NSError(domain: "FixtureLoader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Missing fixture at \(fixtureURL.path)"])
        }

        return fixtureURL
    }
}

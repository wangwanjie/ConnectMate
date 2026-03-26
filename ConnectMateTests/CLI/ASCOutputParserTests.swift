import Foundation
import Testing
@testable import ConnectMate

struct ASCOutputParserTests {
    @Test
    func parsesAppListResponse() throws {
        let json = try FixtureLoader.data(named: "apps-list.json")
        let apps = try ASCOutputParser().decodeApps(from: json)

        #expect(apps.count == 2)
        #expect(apps.first?.bundleID == "com.example.first")
        #expect(apps.first?.name == "First App")
    }

    @Test
    func parsesBuildListResponse() throws {
        let json = try FixtureLoader.data(named: "builds-list.json")
        let builds = try ASCOutputParser().decodeBuilds(from: json)

        #expect(builds.count == 2)
        #expect(builds.first?.version == "1.2.3")
        #expect(builds.first?.buildNumber == "42")
        #expect(builds.first?.platform == "MAC_OS")
        #expect(builds.first?.appID == "123456789")
    }

    @Test
    func extractsFallbackPlainTextFromNonJSONOutput() throws {
        let stderr = try FixtureLoader.data(named: "asc-stderr-failure.txt")
        let diagnostics = ASCOutputParser().extractDiagnosticText(from: stderr)

        #expect(diagnostics.contains("missing authentication"))
        #expect(diagnostics.contains("asc auth init"))
    }
}

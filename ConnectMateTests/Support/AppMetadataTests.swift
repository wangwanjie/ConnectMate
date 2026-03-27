import Foundation
import Testing
@testable import ConnectMate

struct AppMetadataTests {
    @Test
    func resolvesGitHubAndAppcastConfiguration() throws {
        let metadata = AppMetadata(infoDictionary: [
            "ConnectMateGitHubURL": "https://github.com/wangwanjie/ConnectMate",
            "ConnectMateGitHubIssuesURL": "https://github.com/wangwanjie/ConnectMate/issues",
            "ConnectMateGitHubLatestReleaseAPIURL": "https://api.github.com/repos/wangwanjie/ConnectMate/releases/latest",
            "ConnectMateCLIRepositoryURL": "https://github.com/rudrankriyam/App-Store-Connect-CLI",
            "SUFeedURL": "https://raw.githubusercontent.com/wangwanjie/ConnectMate/main/appcast.xml",
            "SUPublicEDKey": "PUBLIC_KEY"
        ])

        #expect(metadata.repositoryURL?.absoluteString == "https://github.com/wangwanjie/ConnectMate")
        #expect(metadata.issuesURL?.absoluteString == "https://github.com/wangwanjie/ConnectMate/issues")
        #expect(metadata.latestReleaseAPIURL?.absoluteString == "https://api.github.com/repos/wangwanjie/ConnectMate/releases/latest")
        #expect(metadata.cliRepositoryURL?.absoluteString == "https://github.com/rudrankriyam/App-Store-Connect-CLI")
        #expect(metadata.sparkleFeedURL?.absoluteString == "https://raw.githubusercontent.com/wangwanjie/ConnectMate/main/appcast.xml")
        #expect(metadata.isSparkleConfigured)
    }
}

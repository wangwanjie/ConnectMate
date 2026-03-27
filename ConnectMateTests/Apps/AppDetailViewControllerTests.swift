import AppKit
import Testing
@testable import ConnectMate

@MainActor
struct AppDetailViewControllerTests {
    @Test
    func asyncImageViewDefaultsToAspectFitScaling() {
        let imageView = AsyncImageView()

        #expect(imageView.imageScaling == .scaleProportionallyUpOrDown)
        #expect(imageView.imageAlignment == .alignCenter)
    }
}

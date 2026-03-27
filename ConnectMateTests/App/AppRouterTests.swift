import Testing
@testable import ConnectMate

struct AppRouterTests {
    @Test
    func includesSigningSectionInSidebarOrder() {
        #expect(AppRouter().sections == [.apps, .builds, .review, .testFlight, .iap, .signing, .logs])
    }

    @Test
    func signingSectionUsesLocalizedTitle() {
        #expect(AppSection.signing.title == L10n.Sidebar.signing)
    }
}

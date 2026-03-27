import AppKit
import Testing
@testable import ConnectMate

@MainActor
struct SidebarViewControllerTests {
    @Test
    func respondsToSidebarStyleChanges() throws {
        let suiteName = "ConnectMateTests.SidebarViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = SidebarViewController(
            items: AppRouter().sections.map(SidebarItem.init(section:)),
            settings: settings
        )

        _ = controller.view

        let appsButton = try #require(findButton(in: controller.view, identifier: AppSection.apps.rawValue))
        #expect(appsButton.title == L10n.Sidebar.apps)

        settings.sidebarItemStyle = .iconOnly

        #expect(appsButton.title.isEmpty)
        #expect(appsButton.imagePosition == .imageOnly)
    }

    private func findButton(in rootView: NSView, identifier: String) -> NSButton? {
        if let button = rootView as? NSButton, button.identifier?.rawValue == identifier {
            return button
        }

        for subview in rootView.subviews {
            if let match = findButton(in: subview, identifier: identifier) {
                return match
            }
        }
        return nil
    }
}

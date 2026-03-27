import AppKit
import Testing
@testable import ConnectMate

@MainActor
struct BuildListViewControllerTests {
    @Test
    func respondsToListDensityChanges() throws {
        let suiteName = "ConnectMateTests.BuildListViewControllerTests.\(#function)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create suite defaults")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(userDefaults: defaults)
        let controller = BuildListViewController(
            service: BuildService.makeDefault(),
            appRepository: AppRepository(),
            settings: settings
        )

        _ = controller.view

        let tableView = try #require(findTableView(in: controller.view))
        #expect(tableView.rowHeight == 34)

        settings.listRowDensity = .spacious

        #expect(tableView.rowHeight == 44)
    }

    private func findTableView(in rootView: NSView) -> NSTableView? {
        if let tableView = rootView as? NSTableView {
            return tableView
        }

        for subview in rootView.subviews {
            if let match = findTableView(in: subview) {
                return match
            }
        }
        return nil
    }
}

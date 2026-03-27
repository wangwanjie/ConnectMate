import Cocoa

final class MainWindowController: NSWindowController {
    private let splitViewController: MainSplitViewController

    init(router: AppRouter) {
        let splitViewController = MainSplitViewController(router: router, settings: .shared)
        self.splitViewController = splitViewController
        let window = NSWindow(contentViewController: splitViewController)
        window.title = L10n.App.name
        window.setContentSize(NSSize(width: 1360, height: 840))
        window.minSize = NSSize(width: 1100, height: 640)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.toolbarStyle = .unifiedCompact
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentSection: AppSection? {
        splitViewController.currentSection
    }

    func select(section: AppSection) {
        splitViewController.select(section: section)
    }

    func refreshCurrentPage() {
        splitViewController.refreshCurrentPage()
    }

    func toggleSidebar() {
        splitViewController.toggleSidebarVisibility()
    }
}

import Cocoa

final class MainWindowController: NSWindowController {
    init(router: AppRouter) {
        let splitViewController = MainSplitViewController(router: router)
        let window = NSWindow(contentViewController: splitViewController)
        window.title = "ConnectMate"
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
}

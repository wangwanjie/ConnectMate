import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let bootstrap = AppBootstrap()

    func applicationDidFinishLaunching(_ notification: Notification) {
        bootstrap.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

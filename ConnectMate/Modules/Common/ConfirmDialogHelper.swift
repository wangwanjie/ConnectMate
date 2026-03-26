import Cocoa

enum ConfirmDialogHelper {
    static func confirm(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String = "Cancel",
        on window: NSWindow?
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: confirmTitle)
            alert.addButton(withTitle: cancelTitle)

            if let window {
                alert.beginSheetModal(for: window) { response in
                    continuation.resume(returning: response == .alertFirstButtonReturn)
                }
            } else {
                continuation.resume(returning: alert.runModal() == .alertFirstButtonReturn)
            }
        }
    }
}

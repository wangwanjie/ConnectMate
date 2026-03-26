import Foundation

@MainActor
final class GlobalHotKey {
    static let shared = GlobalHotKey()

    private(set) var shortcut: String = ""

    func update(shortcut: String) {
        self.shortcut = shortcut
    }

    func conflictDescription(for shortcut: String) -> String? {
        shortcut.isEmpty ? nil : L10n.Settings.Shortcuts.conflictHint
    }
}

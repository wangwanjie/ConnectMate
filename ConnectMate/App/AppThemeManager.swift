import AppKit

@MainActor
final class AppThemeManager {
    static let shared = AppThemeManager()

    private(set) var appliedMode: AppearanceMode = .system

    private init() {}

    func applyStoredPreference(settings: AppSettings = .shared, application: NSApplication = .shared) {
        apply(settings.appearanceMode, application: application)
    }

    func apply(_ mode: AppearanceMode, application: NSApplication = .shared) {
        appliedMode = mode

        switch mode {
        case .system:
            application.appearance = nil
        case .light:
            application.appearance = NSAppearance(named: .aqua)
        case .dark:
            application.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

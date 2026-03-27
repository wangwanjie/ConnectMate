import AppKit

@MainActor
final class AppThemeManager {
    static let shared = AppThemeManager()
    static let didChangeNotification = Notification.Name("ConnectMate.AppThemeManager.didChange")

    private(set) var appliedMode: AppearanceMode = .system

    private init() {}

    func applyStoredPreference(settings: AppSettings? = nil, application: NSApplication? = nil) {
        let settings = settings ?? .shared
        let application = application ?? .shared
        apply(settings.appearanceMode, application: application)
    }

    func apply(_ mode: AppearanceMode, application: NSApplication? = nil) {
        let application = application ?? .shared
        appliedMode = mode

        switch mode {
        case .system:
            application.appearance = nil
        case .light:
            application.appearance = NSAppearance(named: .aqua)
        case .dark:
            application.appearance = NSAppearance(named: .darkAqua)
        }

        NotificationCenter.default.post(name: Self.didChangeNotification, object: mode)
    }
}

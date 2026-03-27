import Foundation

enum AppSection: String, CaseIterable {
    case apps
    case builds
    case review
    case testFlight
    case iap
    case signing
    case settings
    case logs

    var title: String {
        switch self {
        case .apps:
            return L10n.Sidebar.apps
        case .builds:
            return L10n.Sidebar.builds
        case .review:
            return L10n.Sidebar.review
        case .testFlight:
            return L10n.Sidebar.testFlight
        case .iap:
            return L10n.Sidebar.iap
        case .signing:
            return L10n.Sidebar.signing
        case .settings:
            return L10n.Sidebar.settings
        case .logs:
            return L10n.Sidebar.logs
        }
    }

    var contentTitle: String {
        switch self {
        case .apps:
            return "Apps"
        case .builds:
            return "Builds"
        case .review:
            return "Review"
        case .testFlight:
            return "TestFlight"
        case .iap:
            return "In-App Purchases"
        case .signing:
            return "Signing Assets"
        case .settings:
            return "Settings"
        case .logs:
            return "Logs"
        }
    }

    var symbolName: String {
        switch self {
        case .apps:
            return "app.badge"
        case .builds:
            return "shippingbox"
        case .review:
            return "paperplane"
        case .testFlight:
            return "person.3"
        case .iap:
            return "dollarsign.circle"
        case .signing:
            return "checkmark.seal"
        case .settings:
            return "gearshape"
        case .logs:
            return "text.justify"
        }
    }
}

final class AppRouter {
    let sections: [AppSection] = [.apps, .builds, .review, .testFlight, .iap, .signing, .logs]

    func initialSection(for settings: AppSettings) -> AppSection {
        switch settings.defaultLaunchSection {
        case .apps:
            return .apps
        case .builds:
            return .builds
        case .review:
            return .review
        case .testFlight:
            return .testFlight
        case .iap:
            return .iap
        case .signing:
            return .signing
        case .settings:
            return .apps
        case .logs:
            return .logs
        }
    }
}

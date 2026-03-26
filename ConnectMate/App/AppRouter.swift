import Foundation

enum AppSection: String, CaseIterable {
    case apps
    case builds
    case review
    case testFlight
    case iap
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
        case .settings:
            return L10n.Sidebar.settings
        case .logs:
            return L10n.Sidebar.logs
        }
    }
}

final class AppRouter {
    let sections = AppSection.allCases
}

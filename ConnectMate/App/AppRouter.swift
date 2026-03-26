import Foundation

enum AppSection: String, CaseIterable {
    case apps = "我的 App"
    case builds = "构建版本"
    case review = "提交审核"
    case testFlight = "TestFlight"
    case iap = "内购管理"
    case settings = "设置"

    var title: String { rawValue }
}

final class AppRouter {
    let sections = AppSection.allCases
}

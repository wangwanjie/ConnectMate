import Foundation

nonisolated struct AppSummary: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let bundleID: String
    let sku: String?
    let platform: String
    let appState: String?
    let iconURL: URL?
    let rawJSON: String?
    let cachedAt: Date

    init(record: AppRecord) {
        id = record.ascID
        name = record.name
        bundleID = record.bundleID
        sku = record.sku
        platform = record.platform
        appState = record.appState
        iconURL = record.iconURL.flatMap(URL.init(string:))
        rawJSON = record.rawJSON
        cachedAt = record.cachedAt
    }
}

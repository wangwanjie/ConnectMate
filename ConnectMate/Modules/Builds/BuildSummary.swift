import AppKit
import Foundation

nonisolated enum BuildProcessingState: Equatable, Sendable {
    case processing
    case valid
    case invalid
    case expired
    case unknown(String)

    init(rawValue: String, expired: Bool) {
        if expired {
            self = .expired
            return
        }

        switch rawValue.uppercased() {
        case "PROCESSING":
            self = .processing
        case "VALID":
            self = .valid
        case "INVALID", "FAILED":
            self = .invalid
        case "":
            self = .unknown("")
        default:
            self = .unknown(rawValue)
        }
    }

    @MainActor
    var title: String {
        switch self {
        case .processing:
            return L10n.Builds.Status.processing
        case .valid:
            return L10n.Builds.Status.valid
        case .invalid:
            return L10n.Builds.Status.invalid
        case .expired:
            return L10n.Builds.Status.expired
        case .unknown(let rawValue):
            return rawValue.isEmpty ? L10n.Builds.Status.unknown : rawValue
        }
    }

    var tintColor: NSColor {
        switch self {
        case .processing:
            return .systemOrange
        case .valid:
            return .systemGreen
        case .invalid:
            return .systemRed
        case .expired:
            return .secondaryLabelColor
        case .unknown:
            return .systemGray
        }
    }
}

struct BuildSummary: Equatable, Identifiable, Sendable {
    let id: String
    let appID: String
    let version: String
    let buildNumber: String
    let processingState: BuildProcessingState
    let rawProcessingState: String
    let platform: String?
    let isExpired: Bool
    let uploadedAt: Date?
    let rawJSON: String?
    let cachedAt: Date

    init(record: BuildRecord) {
        id = record.ascID
        appID = record.appAscID
        version = record.version
        buildNumber = record.buildNumber
        processingState = BuildProcessingState(rawValue: record.processingState, expired: record.expired)
        rawProcessingState = record.processingState
        platform = record.platform
        isExpired = record.expired
        uploadedAt = record.uploadedAt
        rawJSON = record.rawJSON
        cachedAt = record.cachedAt
    }
}

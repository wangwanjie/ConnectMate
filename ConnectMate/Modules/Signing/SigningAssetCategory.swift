import Foundation

enum SigningAssetCategory: Int, CaseIterable {
    case bundleIDs
    case certificates
    case devices
    case profiles

    var title: String {
        switch self {
        case .bundleIDs:
            return L10n.Signing.bundleIDs
        case .certificates:
            return L10n.Signing.certificates
        case .devices:
            return L10n.Signing.devices
        case .profiles:
            return L10n.Signing.profiles
        }
    }

    var symbolName: String {
        switch self {
        case .bundleIDs:
            return "number.square"
        case .certificates:
            return "checkmark.seal"
        case .devices:
            return "desktopcomputer"
        case .profiles:
            return "doc.badge.gearshape"
        }
    }

    var emptyDetail: String {
        switch self {
        case .bundleIDs:
            return L10n.Signing.emptyBundleIDs
        case .certificates:
            return L10n.Signing.emptyCertificates
        case .devices:
            return L10n.Signing.emptyDevices
        case .profiles:
            return L10n.Signing.emptyProfiles
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .bundleIDs, .certificates, .profiles:
            return L10n.Common.create
        case .devices:
            return L10n.Signing.register
        }
    }
}

enum SigningAssetItem: Equatable {
    case bundleID(BundleIDSummary)
    case certificate(CertificateSummary)
    case device(RegisteredDeviceSummary)
    case profile(ProvisioningProfileSummary)

    var id: String {
        switch self {
        case .bundleID(let item):
            return item.id
        case .certificate(let item):
            return item.id
        case .device(let item):
            return item.id
        case .profile(let item):
            return item.id
        }
    }

    var title: String {
        switch self {
        case .bundleID(let item):
            return item.identifier
        case .certificate(let item):
            return item.name
        case .device(let item):
            return item.name
        case .profile(let item):
            return item.name
        }
    }

    var subtitle: String {
        switch self {
        case .bundleID(let item):
            return item.name
        case .certificate(let item):
            return item.certificateType
        case .device(let item):
            return item.udid
        case .profile(let item):
            return item.profileType
        }
    }

    var category: SigningAssetCategory {
        switch self {
        case .bundleID:
            return .bundleIDs
        case .certificate:
            return .certificates
        case .device:
            return .devices
        case .profile:
            return .profiles
        }
    }
}

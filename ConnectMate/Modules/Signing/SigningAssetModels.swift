import Foundation

nonisolated struct BundleIDSummary: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let identifier: String
    let platform: String
    let seedID: String?
}

nonisolated struct CertificateSummary: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let certificateType: String
    let displayName: String?
    let serialNumber: String?
    let platform: String?
    let expirationDate: String?
}

nonisolated struct RegisteredDeviceSummary: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let platform: String
    let udid: String
    let deviceClass: String?
    let status: String
    let model: String?
    let addedDate: String?
}

nonisolated struct ProvisioningProfileSummary: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let platform: String?
    let profileType: String
    let profileState: String?
}

nonisolated struct BundleIDCapabilitySummary: Identifiable, Equatable, Sendable {
    let id: String
    let capabilityType: String
}

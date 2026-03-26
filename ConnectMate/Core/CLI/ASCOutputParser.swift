import Foundation

struct ASCAppPayload: Equatable, Sendable {
    let id: String
    let name: String
    let bundleID: String
    let sku: String?
    let platform: String?
    let appState: String?
    let iconURL: String?
    let rawJSON: String?
}

struct ASCBuildPayload: Equatable, Sendable {
    let id: String
    let appID: String
    let version: String
    let buildNumber: String
    let processingState: String
    let uploadedAt: Date?
    let platform: String?
    let expired: Bool
    let rawJSON: String?
}

struct ASCOutputParser {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(decoder: JSONDecoder = ASCOutputParser.makeDecoder(), encoder: JSONEncoder = JSONEncoder()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    func decodeApps(from data: Data) throws -> [ASCAppPayload] {
        let response: AppListResponse = try decodeJSON(AppListResponse.self, from: data)
        return response.data.map { item in
            ASCAppPayload(
                id: item.id,
                name: item.attributes.name,
                bundleID: item.attributes.bundleID,
                sku: item.attributes.sku,
                platform: item.attributes.platform,
                appState: item.attributes.appState,
                iconURL: item.attributes.iconURL,
                rawJSON: encodeFragment(item)
            )
        }
    }

    func decodeBuilds(from data: Data) throws -> [ASCBuildPayload] {
        let response: BuildListResponse = try decodeJSON(BuildListResponse.self, from: data)
        let preReleaseMap = Dictionary(uniqueKeysWithValues: response.included.map { included in
            (included.id, included.attributes)
        })

        return response.data.map { item in
            let preReleaseVersion = (item.relationships?.preReleaseVersion?.data?.id).flatMap { preReleaseMap[$0] }
            return ASCBuildPayload(
                id: item.id,
                appID: item.relationships?.app?.data?.id ?? "",
                version: preReleaseVersion?.version ?? item.attributes.version,
                buildNumber: item.attributes.version,
                processingState: item.attributes.processingState ?? "",
                uploadedAt: Self.parseISO8601(item.attributes.uploadedDate),
                platform: preReleaseVersion?.platform,
                expired: item.attributes.expired ?? false,
                rawJSON: encodeFragment(item)
            )
        }
    }

    func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let diagnostics = extractDiagnosticText(from: data)
            let reason = diagnostics.isEmpty ? error.localizedDescription : diagnostics
            throw ASCError.invalidJSON(reason)
        }
    }

    func extractDiagnosticText(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data),
           let values = extractStrings(from: object),
           !values.isEmpty {
            return values.joined(separator: "\n")
        }

        return String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func encodeFragment<T: Encodable>(_ value: T) -> String? {
        guard let data = try? encoder.encode(value) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func extractStrings(from object: Any) -> [String]? {
        switch object {
        case let dictionary as [String: Any]:
            let prioritizedKeys = ["error", "message", "detail", "title", "hint"]
            let prioritized = prioritizedKeys.compactMap { key -> String? in
                guard let value = dictionary[key] else { return nil }
                return extractStrings(from: value)?.joined(separator: " ")
            }
            let remainder = dictionary
                .filter { !prioritizedKeys.contains($0.key) }
                .sorted { $0.key < $1.key }
                .compactMap { extractStrings(from: $0.value)?.joined(separator: " ") }
            return (prioritized + remainder).filter { !$0.isEmpty }

        case let array as [Any]:
            return array.compactMap { extractStrings(from: $0)?.joined(separator: " ") }

        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : [trimmed]

        default:
            return nil
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func parseISO8601(_ value: String?) -> Date? {
        guard let value else {
            return nil
        }

        if let date = fractionalSecondsFormatter.date(from: value) {
            return date
        }

        return basicFormatter.date(from: value)
    }

    private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let basicFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private struct AppListResponse: Codable {
    let data: [AppResource]
}

private struct AppResource: Codable {
    let id: String
    let attributes: AppAttributes
}

private struct AppAttributes: Codable {
    let name: String
    let bundleID: String
    let sku: String?
    let platform: String?
    let appState: String?
    let iconURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case bundleID = "bundleId"
        case sku
        case platform
        case appState = "appState"
        case iconURL = "iconUrl"
    }
}

private struct BuildListResponse: Codable {
    let data: [BuildResource]
    let included: [PreReleaseVersionResource]
}

private struct BuildResource: Codable {
    let id: String
    let attributes: BuildAttributes
    let relationships: BuildRelationships?
}

private struct BuildAttributes: Codable {
    let version: String
    let uploadedDate: String?
    let processingState: String?
    let expired: Bool?
}

private struct BuildRelationships: Codable {
    let preReleaseVersion: Relationship?
    let app: Relationship?
}

private struct Relationship: Codable {
    let data: RelationshipData?
}

private struct RelationshipData: Codable {
    let id: String
}

private struct PreReleaseVersionResource: Codable {
    let id: String
    let attributes: PreReleaseVersionAttributes
}

private struct PreReleaseVersionAttributes: Codable {
    let version: String
    let platform: String?
}

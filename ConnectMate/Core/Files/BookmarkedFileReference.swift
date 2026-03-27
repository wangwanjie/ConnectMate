import Foundation

enum BookmarkedFileReference {
    static func makeBookmark(for path: String) -> Data? {
        let resolvedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            return nil
        }

        return try? URL(fileURLWithPath: resolvedPath).bookmarkData(options: [.withSecurityScope])
    }

    static func resolvePath(path: String, bookmarkData: Data?) -> String {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        if FileManager.default.fileExists(atPath: standardizedPath) {
            return standardizedPath
        }

        guard let bookmarkData else {
            return standardizedPath
        }

        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return standardizedPath
        }

        let resolvedPath = resolvedURL.standardizedFileURL.path
        return FileManager.default.fileExists(atPath: resolvedPath) ? resolvedPath : standardizedPath
    }
}

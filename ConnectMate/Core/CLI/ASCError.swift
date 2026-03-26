import Foundation

enum ASCError: Error, Equatable {
    case cliNotFound(path: String)
    case cliNotExecutable(path: String)
    case failedToLaunch(description: String)
    case nonZeroExit(exitCode: Int32, stdout: String, stderr: String)
    case timeout
    case cancelled
    case invalidJSON(String)
}

extension ASCError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .cliNotFound(path):
            return "CLI not found at \(path)"
        case let .cliNotExecutable(path):
            return "CLI is not executable at \(path)"
        case let .failedToLaunch(description):
            return description
        case let .nonZeroExit(exitCode, _, stderr):
            let suffix = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if suffix.isEmpty {
                return "CLI exited with status \(exitCode)"
            }
            return "CLI exited with status \(exitCode): \(suffix)"
        case .timeout:
            return "CLI execution timed out"
        case .cancelled:
            return "CLI execution was cancelled"
        case let .invalidJSON(message):
            return message
        }
    }
}

import Foundation

struct ASCCommandResult: Sendable, Equatable {
    let executablePath: String
    let arguments: [String]
    let standardOutput: String
    let standardError: String
    let exitCode: Int32
    let duration: TimeInterval
    let attemptCount: Int

    var succeeded: Bool {
        exitCode == 0
    }

    var combinedOutput: String {
        [standardOutput, standardError]
            .filter { !$0.isEmpty }
            .joined(separator: standardOutput.isEmpty || standardError.isEmpty ? "" : "\n")
    }
}

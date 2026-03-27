import Foundation

final class ASCCommandRunner {
    private let configuration: ASCCommandConfiguration
    private let logRepository: CommandLogRepository?

    init(configuration: ASCCommandConfiguration, logRepository: CommandLogRepository? = nil) {
        self.configuration = configuration
        self.logRepository = logRepository
    }

    func run(
        arguments: [String],
        standardInput: Data? = nil,
        extraEnvironment: [String: String] = [:]
    ) async throws -> ASCCommandResult {
        try validateExecutable(at: configuration.cliPath)

        let maxAttempts = max(1, configuration.retryCount)
        var lastError: ASCError?

        for attempt in 1...maxAttempts {
            do {
                return try await executeOnce(
                    arguments: arguments,
                    standardInput: standardInput,
                    extraEnvironment: extraEnvironment,
                    attemptCount: attempt
                )
            } catch let error as ASCError {
                lastError = error

                guard shouldRetry(error: error, attempt: attempt, maxAttempts: maxAttempts) else {
                    throw error
                }
            }
        }

        throw lastError ?? .failedToLaunch(description: "Unknown CLI execution failure")
    }

    private func executeOnce(
        arguments: [String],
        standardInput: Data?,
        extraEnvironment: [String: String],
        attemptCount: Int
    ) async throws -> ASCCommandResult {
        let stdoutAccumulator = DataAccumulator()
        let stderrAccumulator = DataAccumulator()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let process = Process()

        process.executableURL = URL(fileURLWithPath: configuration.cliPath)
        process.arguments = arguments
        process.environment = configuration.resolvedEnvironment(extraEnvironment: extraEnvironment)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.currentDirectoryURL = configuration.workingDirectory

        let inputPipe: Pipe?
        if standardInput != nil {
            let pipe = Pipe()
            process.standardInput = pipe
            inputPipe = pipe
        } else {
            inputPipe = nil
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            stdoutAccumulator.append(data)
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            stderrAccumulator.append(data)
        }

        let startTime = Date()
        let startReference = CFAbsoluteTimeGetCurrent()

        do {
            try process.run()

            if let inputPipe {
                inputPipe.fileHandleForWriting.write(standardInput ?? Data())
                try? inputPipe.fileHandleForWriting.close()
            }

            while process.isRunning {
                try Task.checkCancellation()

                if CFAbsoluteTimeGetCurrent() - startReference > configuration.timeout {
                    process.terminate()
                    process.waitUntilExit()
                    let finalOutput = finalizeOutput(
                        stdoutPipe: stdoutPipe,
                        stderrPipe: stderrPipe,
                        stdoutAccumulator: stdoutAccumulator,
                        stderrAccumulator: stderrAccumulator
                    )
                    let durationMs = makeDurationMilliseconds(from: startReference)
                    recordLog(
                        arguments: arguments,
                        stdout: finalOutput.stdout,
                        stderr: finalOutput.stderr,
                        exitCode: process.terminationStatus,
                        durationMs: durationMs,
                        status: "timeout",
                        executedAt: startTime
                    )
                    throw ASCError.timeout
                }

                try await Task.sleep(nanoseconds: 50_000_000)
            }
        } catch is CancellationError {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }

            let finalOutput = finalizeOutput(
                stdoutPipe: stdoutPipe,
                stderrPipe: stderrPipe,
                stdoutAccumulator: stdoutAccumulator,
                stderrAccumulator: stderrAccumulator
            )
            let durationMs = makeDurationMilliseconds(from: startReference)
            recordLog(
                arguments: arguments,
                stdout: finalOutput.stdout,
                stderr: finalOutput.stderr,
                exitCode: process.isRunning ? nil : process.terminationStatus,
                durationMs: durationMs,
                status: "cancelled",
                executedAt: startTime
            )
            throw ASCError.cancelled
        } catch let error as ASCError {
            let finalOutput = finalizeOutput(
                stdoutPipe: stdoutPipe,
                stderrPipe: stderrPipe,
                stdoutAccumulator: stdoutAccumulator,
                stderrAccumulator: stderrAccumulator
            )
            let durationMs = makeDurationMilliseconds(from: startReference)
            recordLog(
                arguments: arguments,
                stdout: finalOutput.stdout,
                stderr: finalOutput.stderr,
                exitCode: process.isRunning ? nil : process.terminationStatus,
                durationMs: durationMs,
                status: "failure",
                executedAt: startTime
            )
            throw error
        } catch {
            let finalOutput = finalizeOutput(
                stdoutPipe: stdoutPipe,
                stderrPipe: stderrPipe,
                stdoutAccumulator: stdoutAccumulator,
                stderrAccumulator: stderrAccumulator
            )
            let durationMs = makeDurationMilliseconds(from: startReference)
            recordLog(
                arguments: arguments,
                stdout: finalOutput.stdout,
                stderr: finalOutput.stderr,
                exitCode: nil,
                durationMs: durationMs,
                status: "failure",
                executedAt: startTime
            )
            throw ASCError.failedToLaunch(description: error.localizedDescription)
        }

        let finalOutput = finalizeOutput(
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe,
            stdoutAccumulator: stdoutAccumulator,
            stderrAccumulator: stderrAccumulator
        )
        let duration = CFAbsoluteTimeGetCurrent() - startReference
        let durationMs = Int((duration * 1_000).rounded())
        let result = ASCCommandResult(
            executablePath: configuration.cliPath,
            arguments: arguments,
            standardOutput: finalOutput.stdout,
            standardError: finalOutput.stderr,
            exitCode: process.terminationStatus,
            duration: duration,
            attemptCount: attemptCount
        )

        if result.succeeded {
            recordLog(
                arguments: arguments,
                stdout: result.standardOutput,
                stderr: result.standardError,
                exitCode: result.exitCode,
                durationMs: durationMs,
                status: "success",
                executedAt: startTime
            )
            return result
        }

        recordLog(
            arguments: arguments,
            stdout: result.standardOutput,
            stderr: result.standardError,
            exitCode: result.exitCode,
            durationMs: durationMs,
            status: "failure",
            executedAt: startTime
        )
        throw ASCError.nonZeroExit(exitCode: result.exitCode, stdout: result.standardOutput, stderr: result.standardError)
    }

    private func finalizeOutput(
        stdoutPipe: Pipe,
        stderrPipe: Pipe,
        stdoutAccumulator: DataAccumulator,
        stderrAccumulator: DataAccumulator
    ) -> (stdout: String, stderr: String) {
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        let stdoutData = stdoutAccumulator.finalData(appending: stdoutPipe.fileHandleForReading.readDataToEndOfFile())
        let stderrData = stderrAccumulator.finalData(appending: stderrPipe.fileHandleForReading.readDataToEndOfFile())

        return (
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self)
        )
    }

    private func validateExecutable(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ASCError.cliNotFound(path: path)
        }

        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw ASCError.cliNotExecutable(path: path)
        }
    }

    private func shouldRetry(error: ASCError, attempt: Int, maxAttempts: Int) -> Bool {
        guard attempt < maxAttempts else {
            return false
        }

        switch error {
        case .nonZeroExit, .failedToLaunch:
            return true
        case .cliNotFound, .cliNotExecutable, .timeout, .cancelled, .invalidJSON:
            return false
        }
    }

    private func recordLog(
        arguments: [String],
        stdout: String,
        stderr: String,
        exitCode: Int32?,
        durationMs: Int,
        status: String,
        executedAt: Date
    ) {
        guard let logRepository else {
            return
        }

        do {
            try logRepository.record(
                command: configuration.cliPath,
                arguments: arguments,
                stdout: stdout,
                stderr: stderr,
                exitCode: exitCode,
                durationMs: durationMs,
                status: status,
                executedAt: executedAt
            )
        } catch {
            assertionFailure("Failed to write command log: \(error)")
        }
    }

    private func makeDurationMilliseconds(from startReference: CFAbsoluteTime) -> Int {
        Int(((CFAbsoluteTimeGetCurrent() - startReference) * 1_000).rounded())
    }
}

private final class DataAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var storage = Data()

    nonisolated func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(data)
    }

    nonisolated func finalData(appending trailingData: Data) -> Data {
        lock.lock()
        defer { lock.unlock() }
        storage.append(trailingData)
        return storage
    }
}

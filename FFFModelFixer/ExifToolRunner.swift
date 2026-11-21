import Foundation

struct ExifToolRunner: Sendable {
    let url: URL

    static func locate() -> URL? {
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            for dir in pathEnv.components(separatedBy: ":") {
                let candidate = URL(fileURLWithPath: dir).appendingPathComponent("exiftool")
                if FileManager.default.isExecutableFile(atPath: candidate.path) {
                    return candidate
                }
            }
        }
        for path in ["/opt/homebrew/bin/exiftool", "/usr/local/bin/exiftool"] {
            let candidate = URL(fileURLWithPath: path)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    func run(_ arguments: [String]) async throws -> String {
        let execURL = url
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = execURL
            process.arguments = arguments

            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = Pipe()

            try process.run()
            // Drain stdout continuously on this background thread so the pipe buffer
            // never fills up — without this, exiftool deadlocks on large sessions.
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }
}

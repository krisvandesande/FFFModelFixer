import Foundation
import SwiftUI

// MARK: - Data types

enum ProcessingState {
    case idle
    case processing
    case done(ProcessingResult)
    case error(String)

    var phaseID: Int {
        switch self {
        case .idle:       return 0
        case .processing: return 1
        case .done:       return 2
        case .error:      return 3
        }
    }
}

struct ProcessingResult {
    let folderURL: URL
    let backupURL: URL
    let fffCount: Int
    let fixes: [ModelFix]
    let alreadyCorrectCount: Int
}

struct ModelFix: Identifiable {
    let id = UUID()
    let original: String
    let corrected: String
    let filesUpdated: Int
}

struct LogEntry: Identifiable {
    let id = UUID()

    enum Kind { case info, fixed, alreadyCorrect, error }

    let kind: Kind
    let text: String

    var iconName: String {
        switch kind {
        case .info:           return "info.circle"
        case .fixed:          return "checkmark.circle.fill"
        case .alreadyCorrect: return "checkmark.circle"
        case .error:          return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch kind {
        case .info:           return .secondary
        case .fixed:          return .green
        case .alreadyCorrect: return .secondary
        case .error:          return .red
        }
    }
}

// MARK: - Processor

@Observable @MainActor final class FFFProcessor {
    var state: ProcessingState = .idle
    var logEntries: [LogEntry] = []
    var currentStep: String = ""

    func reset() {
        state = .idle
        logEntries = []
        currentStep = ""
    }

    func process(folderURL: URL) async {
        state = .processing
        logEntries = []

        // 1. Locate exiftool
        currentStep = "Locating exiftool…"
        guard let exiftoolURL = ExifToolRunner.locate() else {
            state = .error("exiftool not found.\n\nInstall it with Homebrew:\n    brew install exiftool")
            return
        }
        let runner = ExifToolRunner(url: exiftoolURL)

        // 2. Find .fff files at the top level
        currentStep = "Scanning for FFF files…"
        let fffFiles: [URL]
        do {
            fffFiles = try await Task.detached(priority: .userInitiated) {
                try FileManager.default.contentsOfDirectory(
                    at: folderURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                ).filter { $0.pathExtension.lowercased() == "fff" }
            }.value
        } catch {
            state = .error("Could not read folder:\n\(error.localizedDescription)")
            return
        }

        guard !fffFiles.isEmpty else {
            state = .error("No .fff files found at the top level of the dropped folder.")
            return
        }

        addLog(.info, "Found \(fffFiles.count) FFF file\(fffFiles.count == 1 ? "" : "s")")

        // 3. Create backup
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let backupURL = folderURL.appendingPathComponent("_FFF_Backup_\(formatter.string(from: Date()))")

        currentStep = "Backing up \(fffFiles.count) file\(fffFiles.count == 1 ? "" : "s")…"
        do {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
                for file in fffFiles {
                    try FileManager.default.copyItem(
                        at: file,
                        to: backupURL.appendingPathComponent(file.lastPathComponent)
                    )
                }
            }.value
        } catch {
            state = .error("Backup failed:\n\(error.localizedDescription)")
            return
        }

        addLog(.info, "Backup created: \(backupURL.lastPathComponent)")

        // 4. Read all unique Model values
        currentStep = "Reading camera metadata…"
        let modelsOutput: String
        do {
            // -fast2: read only up to the metadata headers, skip full image data.
            // FFF files can be 100–200 MB each; this drops read time from minutes to seconds.
            modelsOutput = try await runner.run(["-fast2", "-Model", "-s3", "-ext", "fff", folderURL.path])
        } catch {
            state = .error("exiftool read failed:\n\(error.localizedDescription)")
            return
        }

        let models = Set(
            modelsOutput
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )

        addLog(.info, "Found \(models.count) unique camera model\(models.count == 1 ? "" : "s")")

        // 5. Fix models that lack the "Hasselblad" prefix
        var fixes: [ModelFix] = []
        var alreadyCorrectCount = 0

        for model in models.sorted() {
            if model.hasPrefix("Hasselblad") {
                alreadyCorrectCount += 1
                addLog(.alreadyCorrect, "Already correct: \(model)")
            } else {
                let corrected = "Hasselblad \(model)"
                currentStep = "Fixing: \(model)…"
                do {
                    // Pass arguments directly — no shell, so $Model is literal (no escaping needed)
                    let result = try await runner.run([
                        "-m", "-overwrite_original",
                        "-Model=\(corrected)",
                        "-if", "$Model eq \"\(model)\"",
                        "-ext", "fff",
                        folderURL.path,
                    ])
                    let updated = parseUpdatedCount(from: result)
                    fixes.append(ModelFix(original: model, corrected: corrected, filesUpdated: updated))
                    addLog(.fixed, "Fixed \(updated) file\(updated == 1 ? "" : "s"): \"\(model)\" → \"\(corrected)\"")
                } catch {
                    addLog(.error, "Failed to fix \(model): \(error.localizedDescription)")
                }
            }
        }

        // 6. Write fix_log.txt into the backup folder
        let logText = buildLogText(folderURL: folderURL, fffCount: fffFiles.count)
        try? logText.write(
            to: backupURL.appendingPathComponent("fix_log.txt"),
            atomically: true,
            encoding: .utf8
        )

        state = .done(ProcessingResult(
            folderURL: folderURL,
            backupURL: backupURL,
            fffCount: fffFiles.count,
            fixes: fixes,
            alreadyCorrectCount: alreadyCorrectCount
        ))
    }

    // MARK: - Helpers

    private func addLog(_ kind: LogEntry.Kind, _ text: String) {
        logEntries.append(LogEntry(kind: kind, text: text))
    }

    private func parseUpdatedCount(from output: String) -> Int {
        for line in output.components(separatedBy: .newlines) {
            if line.contains("image files updated") {
                return line.split(separator: " ").first.flatMap { Int($0) } ?? 0
            }
        }
        return 0
    }

    private func buildLogText(folderURL: URL, fffCount: Int) -> String {
        var lines = [
            "FFF Model Fixer — \(Date())",
            "Folder: \(folderURL.path)",
            "FFF files found: \(fffCount)",
            "",
        ]
        for entry in logEntries {
            lines.append("  \(entry.text)")
        }
        return lines.joined(separator: "\n")
    }
}

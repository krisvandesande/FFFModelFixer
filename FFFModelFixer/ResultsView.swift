import SwiftUI

struct ResultsView: View {
    let result: ProcessingResult
    let logEntries: [LogEntry]
    let onReset: () -> Void

    private var summaryLine: String {
        var parts: [String] = []
        parts.append("\(result.fffCount) file\(result.fffCount == 1 ? "" : "s") processed")
        if !result.fixes.isEmpty {
            parts.append("\(result.fixes.count) model\(result.fixes.count == 1 ? "" : "s") fixed")
        }
        if result.alreadyCorrectCount > 0 {
            parts.append("\(result.alreadyCorrectCount) already correct")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)
                    .padding(.top, 28)

                Text("Done")
                    .font(.title.weight(.semibold))

                Text(summaryLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)

            Divider()

            // Log list
            LogListView(entries: logEntries)
                .frame(maxHeight: 220)

            Divider()

            // Buttons
            HStack(spacing: 12) {
                Button("Open Backup Folder") {
                    NSWorkspace.shared.open(result.backupURL)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Process Another Folder") {
                    onReset()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(16)
        }
        .frame(minHeight: 380)
    }
}

// MARK: - Shared log components

struct LogListView: View {
    let entries: [LogEntry]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entries) { entry in
                        LogRowView(entry: entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onChange(of: entries.count) { _, _ in
                if let last = entries.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
}

struct LogRowView: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Image(systemName: entry.iconName)
                .foregroundStyle(entry.color)
                .frame(width: 14)
                .font(.footnote)

            Text(entry.text)
                .font(.callout)
                .foregroundStyle(
                    entry.kind == .fixed ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
                )
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    ResultsView(
        result: ProcessingResult(
            folderURL: URL(fileURLWithPath: "/path/to/session"),
            backupURL: URL(fileURLWithPath: "/path/to/session/_FFF_Backup_20260611_120000"),
            fffCount: 847,
            fixes: [ModelFix(original: "X2D 100C", corrected: "Hasselblad X2D 100C", filesUpdated: 423)],
            alreadyCorrectCount: 1
        ),
        logEntries: [
            LogEntry(kind: .info, text: "Found 847 FFF files"),
            LogEntry(kind: .info, text: "Backup created: _FFF_Backup_20260611_120000"),
            LogEntry(kind: .alreadyCorrect, text: "Already correct: Hasselblad X1D-50c"),
            LogEntry(kind: .fixed, text: "Fixed 423 files: \"X2D 100C\" → \"Hasselblad X2D 100C\""),
        ],
        onReset: {}
    )
    .frame(width: 500)
}

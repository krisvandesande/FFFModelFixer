import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var processor = FFFProcessor()
    @State private var isDropTargeted = false

    var body: some View {
        Group {
            switch processor.state {
            case .idle:
                DropZoneView(isTargeted: isDropTargeted)
                    .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)

            case .processing:
                ProcessingView(
                    currentStep: processor.currentStep,
                    logEntries: processor.logEntries
                )

            case .done(let result):
                ResultsView(
                    result: result,
                    logEntries: processor.logEntries,
                    onReset: processor.reset
                )

            case .error(let message):
                ErrorView(message: message, onReset: processor.reset)
            }
        }
        .frame(width: 500)
        .animation(.easeInOut(duration: 0.2), value: processor.state.phaseID)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            guard isDir else { return }
            Task { @MainActor in
                await processor.process(folderURL: url)
            }
        }
        return true
    }
}

// MARK: - Processing view

struct ProcessingView: View {
    let currentStep: String
    let logEntries: [LogEntry]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.4)
                    .padding(.top, 36)

                Text(currentStep)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)

            if !logEntries.isEmpty {
                Divider()
                LogListView(entries: logEntries)
                    .frame(maxHeight: 220)
            }

            Spacer(minLength: 20)
        }
        .frame(minHeight: 300)
    }
}

// MARK: - Error view

struct ErrorView: View {
    let message: String
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button("Try Again") { onReset() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])

            Spacer()
        }
        .frame(minHeight: 300)
    }
}

#Preview {
    ContentView()
}

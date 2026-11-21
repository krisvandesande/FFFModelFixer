import SwiftUI

@main
struct FFFModelFixerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

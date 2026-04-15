import SwiftUI

@main
struct CopyasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // No main window — menu bar only
        Settings {
            EmptyView()
        }
    }
}

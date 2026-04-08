import SwiftUI

/// FoxBuddy app entry point.
///
/// All real setup happens in AppDelegate (overlay panel, hotkey, permissions).
/// The SwiftUI App conformance is just the minimum required by @main.
@main
struct FoxBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — FoxBuddy is menu bar only.
        // The Settings scene is the minimum needed to satisfy the compiler.
        Settings { EmptyView() }
    }
}

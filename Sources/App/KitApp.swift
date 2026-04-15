import SwiftUI

/// Kit app entry point.
///
/// All real setup happens in AppDelegate (overlay panel, hotkey, permissions).
/// The SwiftUI App conformance is just the minimum required by @main.
@main
struct KitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — Kit is menu bar only.
        Settings { EmptyView() }
    }
}

import AppKit
import CoreGraphics

/// Checks and requests Screen Recording permission on first launch.
/// Without this permission, SCShareableContent and CGDisplayCreateImage both fail silently.
@MainActor
final class PermissionService {
    static let shared = PermissionService()
    private init() {}

    func requestIfNeeded() {
        // CGPreflightScreenCaptureAccess() returns true if permission is already granted —
        // no dialog, no interruption.
        guard !CGPreflightScreenCaptureAccess() else { return }

        // Trigger the system prompt. This may not show immediately if the user has already
        // denied once; they'll need to go to System Settings.
        CGRequestScreenCaptureAccess()

        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = """
            FoxBuddy needs Screen Recording access to see your windows.

            Go to System Settings → Privacy & Security → Screen Recording, \
            enable FoxBuddy, then relaunch.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            )
        }
    }
}

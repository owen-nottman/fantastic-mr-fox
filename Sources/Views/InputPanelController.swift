import AppKit
import SwiftUI

/// Manages the floating input panel that appears when the user presses ⌥F.
///
/// Unlike the overlay mascot panel, this panel *does* become key so the user can type.
/// It remembers the previously active app and restores focus when dismissed.
final class InputPanelController {
    private var panel: NSPanel?
    private let store: FoxStore

    /// The app that was frontmost when the input panel appeared, so we can restore it on close.
    private var previousApp: NSRunningApplication?

    init(store: FoxStore) {
        self.store = store
    }

    // MARK: - Show / Hide

    func show() {
        // Remember the current frontmost app so we can restore focus on dismissal
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = frontmost
        }

        if panel == nil { createPanel() }
        panel?.center()
        // makeKeyAndOrderFront is intentional here — the user needs to type
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
        // Restore activation policy so FoxBuddy disappears from the app switcher
        NSApp.setActivationPolicy(.accessory)
        // Give focus back to whatever the user was doing before
        previousApp?.activate(options: [])
        previousApp = nil
    }

    // MARK: - Panel creation

    private func createPanel() {
        // Width is fixed; height accommodates either state (with/without attachment preview)
        let size = CGSize(width: 540, height: 130)

        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.isFloatingPanel = true
        p.level = .floating
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.animationBehavior = .alertPanel
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        p.contentView = NSHostingView(rootView: InputPanelView(store: store))
        self.panel = p
    }
}

import AppKit
import SwiftUI

// MARK: - Overlay Panel

/// A transparent, always-on-top, non-focus-stealing panel.
/// Adapted from masko-code/Sources/Views/Overlay/OverlayPanel.swift.
///
/// Key properties that keep the fox visible everywhere without stealing focus:
/// - `.nonactivatingPanel` — clicks don't activate FoxBuddy
/// - `.screenSaver` level — floats above fullscreen apps
/// - `.canJoinAllSpaces` — visible in every Space and fullscreen app
final class OverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        level = .screenSaver           // level 1000 — above fullscreen apps
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        animationBehavior = .none

        collectionBehavior = [
            .canJoinAllSpaces,          // visible in every Space/desktop
            .fullScreenAuxiliary,       // allowed into fullscreen app Spaces
            .stationary,                // stay fixed during Mission Control
            .ignoresCycle,              // skip Cmd+` window cycling
            .fullScreenDisallowsTiling, // prevent macOS 13+ tiling
        ]
    }

    // Must return true so SwiftUI tap gestures register on the panel
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var isExcludedFromWindowsMenu: Bool {
        get { true }
        set { }
    }
}

// MARK: - Overlay Window Controller

/// Manages the always-visible fox mascot panel in the bottom-right corner of the screen.
/// Uses `orderFront` (never `makeKeyAndOrderFront`) so focus is never stolen.
final class OverlayWindowController {
    private var panel: OverlayPanel?
    private let store: KitStore

    init(store: KitStore) {
        self.store = store
    }

    func show() {
        guard panel == nil else { return }

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        // Wider + taller to accommodate the conversation panel above the fox
        let size = CGSize(width: 420, height: 620)
        let origin = CGPoint(
            x: screenFrame.maxX - size.width - 16,
            y: screenFrame.minY + 16
        )

        let p = OverlayPanel(contentRect: NSRect(origin: origin, size: size))
        p.contentView = NSHostingView(rootView: KitOverlayView(store: store))
        // orderFront — NOT makeKeyAndOrderFront — leaves focus with the current app
        p.orderFront(nil)

        // When the fox enters .awaitingInput, make the panel key so the
        // integrated SwiftUI TextField can become first responder.
        store.onNeedsKeyFocus = { [weak p] in
            p?.makeKey()
        }

        self.panel = p
    }
}

import AppKit
import ScreenCaptureKit

// MARK: - Panel subclass

private final class CapturePanel: NSPanel {
    // Allows the panel to become key (receive keyboard events like Escape)
    // without activating the FoxBuddy application, because .nonactivatingPanel is set.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Overlay NSView

/// Full-screen transparent view that dims the display and handles two capture modes:
///  • Click on a window  →  captures that window via ScreenCaptureKit
///  • Drag a rectangle   →  captures that region via CGDisplayCreateImageForRect
///  • Escape             →  cancels
final class CaptureOverlayView: NSView {

    /// Called exactly once when the user finalises a selection or cancels.
    var onComplete: ((CaptureResult?) -> Void)?

    /// On-screen windows fetched before the overlay appears, used for hover-highlight
    /// and click-to-capture. Ordered front-to-back (index 0 = topmost).
    var windows: [SCWindow] = []

    // MARK: - Private state

    private var highlightedWindow: SCWindow?
    private var dragStart: NSPoint?
    private var selectionRect: NSRect?

    // MARK: - First-responder

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Dim the entire screen
        NSColor.black.withAlphaComponent(0.45).setFill()
        bounds.fill()

        // Highlight the hovered window with an orange border (Kit brand)
        if let win = highlightedWindow {
            let r = win.frame
            NSColor(red: 0.910, green: 0.388, blue: 0.165, alpha: 0.15).setFill()
            r.fill()
            NSColor(red: 0.910, green: 0.388, blue: 0.165, alpha: 0.9).setStroke()
            let border = NSBezierPath(roundedRect: r, xRadius: 4, yRadius: 4)
            border.lineWidth = 2
            border.stroke()
        }

        // Draw the drag-selection rectangle in orange
        if let rect = selectionRect, rect.width > 4, rect.height > 4 {
            NSColor(red: 0.910, green: 0.388, blue: 0.165, alpha: 0.15).setFill()
            rect.fill()
            NSColor(red: 0.910, green: 0.388, blue: 0.165, alpha: 0.9).setStroke()
            let sel = NSBezierPath(rect: rect)
            sel.lineWidth = 1.5
            sel.stroke()
        }
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: - Mouse tracking

    override func mouseMoved(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        // frontmost window under the cursor (windows[0] = topmost)
        let hovered = windows.first(where: { $0.frame.contains(pt) })
        guard hovered?.windowID != highlightedWindow?.windowID else { return }
        highlightedWindow = hovered
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        selectionRect = nil
        highlightedWindow = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
        selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)

        if let rect = selectionRect, rect.width > 10, rect.height > 10 {
            // Region mode
            fireCompletion(frame: rect) {
                try await ScreenCaptureService.shared.captureRegion(rect)
            }
            return
        }

        // Click mode — topmost window under the cursor
        if let win = windows.first(where: { $0.frame.contains(pt) }) {
            fireCompletion(frame: win.frame) {
                try await ScreenCaptureService.shared.captureWindow(win)
            }
            return
        }

        // Clicked empty space — cancel
        fireCompletion(with: nil)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            fireCompletion(with: nil)
        }
    }

    // MARK: - Helpers

    /// Captures an image asynchronously, then calls `onComplete` exactly once.
    private func fireCompletion(frame: CGRect, capture: @escaping () async throws -> NSImage) {
        let completion = onComplete
        onComplete = nil
        Task { @MainActor in
            let image = try? await capture()
            if let image {
                completion?(CaptureResult(image: image, frame: frame))
            } else {
                completion?(nil)
            }
        }
    }

    private func fireCompletion(with result: CaptureResult?) {
        let completion = onComplete
        onComplete = nil
        completion?(result)
    }
}

// MARK: - Controller

/// Manages the full-screen capture overlay panel.
/// Call `present()` to run the capture flow asynchronously.
final class CaptureOverlayController: NSObject {

    private static var active: CaptureOverlayController?

    private var panel: CapturePanel?
    private var overlayView: CaptureOverlayView?
    private var onComplete: ((CaptureResult?) -> Void)?

    // MARK: - Public API

    /// Presents the full-screen capture overlay and suspends until the user makes
    /// a selection or presses Escape. Returns `nil` on cancellation.
    @MainActor
    static func present() async -> CaptureResult? {
        await withCheckedContinuation { continuation in
            let controller = CaptureOverlayController()
            CaptureOverlayController.active = controller
            controller.onComplete = { result in
                CaptureOverlayController.active = nil
                continuation.resume(returning: result)
            }
            controller.show()
        }
    }

    // MARK: - Private

    private func show() {
        guard let screen = NSScreen.main else { return }

        let panel = CapturePanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // One level above the fox overlay (.screenSaver = 1000) so it covers everything
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let overlay = CaptureOverlayView()
        overlay.frame = panel.contentView!.bounds
        overlay.autoresizingMask = [.width, .height]
        overlay.onComplete = { [weak self, weak panel] result in
            NSCursor.pop()
            panel?.orderOut(nil)
            self?.onComplete?(result)
        }

        overlay.addTrackingArea(NSTrackingArea(
            rect: overlay.bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: overlay,
            userInfo: nil
        ))

        panel.contentView?.addSubview(overlay)
        self.panel = panel
        self.overlayView = overlay

        // Fetch on-screen windows, then reveal the overlay
        Task { @MainActor [weak self] in
            guard let self else { return }
            let windows = (try? await ScreenCaptureService.shared.getOnScreenWindows()) ?? []
            self.overlayView?.windows = windows

            NSCursor.crosshair.push()
            panel.makeKeyAndOrderFront(nil)
            panel.makeFirstResponder(self.overlayView)
        }
    }
}

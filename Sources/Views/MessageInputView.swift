import AppKit

// MARK: - Panel subclass

private final class InputPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Controller

/// A small floating input bar anchored near the capture frame.
/// Returns the typed message on Return, or nil on Escape/dismissal.
final class MessageInputController: NSObject, NSTextFieldDelegate {

    private static var active: MessageInputController?

    private var panel: InputPanel?
    private var textField: NSTextField?
    private var onComplete: ((String?) -> Void)?

    // MARK: - Public API

    /// Presents the message input bar below `frame` and suspends until the user
    /// presses Return (returns typed text, possibly empty string) or Escape (returns nil).
    @MainActor
    static func present(near frame: CGRect) async -> String? {
        await withCheckedContinuation { continuation in
            let controller = MessageInputController()
            MessageInputController.active = controller
            controller.onComplete = { text in
                MessageInputController.active = nil
                continuation.resume(returning: text)
            }
            controller.show(near: frame)
        }
    }

    // MARK: - Private

    private func show(near frame: CGRect) {
        let width: CGFloat = 420
        let height: CGFloat = 48

        // Anchor below the captured frame, horizontally centred
        var x = frame.midX - width / 2
        var y = frame.minY - height - 10

        // Clamp to visible screen area
        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            x = max(vf.minX + 8, min(x, vf.maxX - width - 8))
            y = max(vf.minY + 8, y)
        }

        let panel = InputPanel(
            contentRect: CGRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Two levels above the fox overlay so it appears above the capture overlay
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
        panel.backgroundColor = NSColor(white: 0.1, alpha: 0.92)
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        // Rounded corners
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12
        panel.contentView?.layer?.masksToBounds = true

        // Text field, vertically centred in the panel
        let tf = NSTextField(frame: CGRect(x: 14, y: (height - 22) / 2, width: width - 28, height: 22))
        tf.placeholderString = "Ask FoxBuddy about this…  (↩ send · Esc cancel)"
        tf.isBordered = false
        tf.drawsBackground = false
        tf.font = .systemFont(ofSize: 13.5)
        tf.textColor = .white
        tf.focusRingType = .none
        tf.delegate = self

        // Dim placeholder text
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(0.35),
            .font: NSFont.systemFont(ofSize: 13.5)
        ]
        (tf.cell as? NSTextFieldCell)?.placeholderAttributedString =
            NSAttributedString(string: tf.placeholderString ?? "", attributes: attrs)

        panel.contentView?.addSubview(tf)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(tf)

        self.panel = panel
        self.textField = tf
    }

    // MARK: - NSTextFieldDelegate

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            dismiss(with: textField?.stringValue ?? "")
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            dismiss(with: nil)
            return true
        default:
            return false
        }
    }

    // MARK: - Helpers

    private func dismiss(with text: String?) {
        panel?.orderOut(nil)
        panel = nil
        textField = nil
        let completion = onComplete
        onComplete = nil
        completion?(text)
    }
}

import AppKit
import ScreenCaptureKit

/// The result of a successful screen capture, ready to send to Claude.
struct CaptureResult {
    /// The captured screenshot image.
    let image: NSImage
    /// The bounding rect in AppKit screen coordinates (bottom-left origin).
    /// Used to anchor the message input bar near the selection.
    let frame: CGRect
}

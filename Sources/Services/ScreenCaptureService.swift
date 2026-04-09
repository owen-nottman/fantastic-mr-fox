import AppKit
import ScreenCaptureKit

/// Wraps a live SCWindow with a pre-fetched thumbnail for display in the window picker.
struct WindowInfo: Identifiable {
    /// Uses SCWindow's windowID as the stable identity.
    var id: CGWindowID { window.windowID }
    let window: SCWindow
    let thumbnail: NSImage
    let appName: String
    let windowTitle: String
}

/// Provides window enumeration (with thumbnails) and on-demand window capture.
/// All methods are async and require Screen Recording permission.
final class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    private init() {}

    // MARK: - Window enumeration

    /// Returns all on-screen windows (excluding FoxBuddy itself) with pre-fetched thumbnails.
    /// Thumbnail capture failures are silently skipped so the picker still shows remaining windows.
    func getWindowInfos() async throws -> [WindowInfo] {
        let content = try await SCShareableContent.current
        let windows = content.windows.filter {
            $0.isOnScreen &&
            $0.frame.width > 100 &&
            $0.frame.height > 100 &&
            $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
        }

        var infos: [WindowInfo] = []
        await withTaskGroup(of: WindowInfo?.self) { group in
            for window in windows {
                group.addTask {
                    guard let thumbnail = try? await self.captureThumbnail(window: window) else { return nil }
                    let appName = window.owningApplication?.applicationName ?? "Unknown"
                    let title = window.title.flatMap { $0.isEmpty ? nil : $0 } ?? appName
                    return WindowInfo(window: window, thumbnail: thumbnail, appName: appName, windowTitle: title)
                }
            }
            for await info in group {
                if let info { infos.append(info) }
            }
        }

        // Sort: named windows (with distinct titles) first, then by app name
        return infos.sorted {
            if $0.windowTitle != $0.appName && $1.windowTitle == $1.appName { return true }
            if $0.windowTitle == $0.appName && $1.windowTitle != $1.appName { return false }
            return $0.appName < $1.appName
        }
    }

    // MARK: - Full-res window capture

    /// Captures the full-resolution contents of a specific window for the Claude API.
    func captureWindow(_ window: SCWindow) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        // 2× the logical size gives a crisp Retina capture
        config.width = Int(window.frame.width * 2)
        config.height = Int(window.frame.height * 2)
        config.scalesToFit = true
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return NSImage(cgImage: cgImage, size: window.frame.size)
    }

    // MARK: - On-screen window list (no thumbnails — for overlay hover-highlight)

    /// Returns all on-screen windows (excluding FoxBuddy) without fetching thumbnails.
    /// Used by the capture overlay to know window positions for hover-highlight and click-to-capture.
    func getOnScreenWindows() async throws -> [SCWindow] {
        let content = try await SCShareableContent.current
        return content.windows.filter {
            $0.isOnScreen &&
            $0.frame.width > 100 &&
            $0.frame.height > 100 &&
            $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
        }
    }

    // MARK: - Region capture (for drag-to-select)

    /// Captures a rectangular region of the main display using CGDisplayCreateImageForRect.
    /// `rect` is in AppKit screen coordinates (origin at bottom-left of screen, in points).
    func captureRegion(_ rect: CGRect) async throws -> NSImage {
        let displayID = CGMainDisplayID()
        let screenHeightPx = CGFloat(CGDisplayPixelsHigh(displayID))
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        // Convert AppKit points (Y=0 at bottom-left) → CG pixels (Y=0 at top-left)
        let pixelRect = CGRect(
            x: rect.origin.x * scale,
            y: screenHeightPx - (rect.origin.y + rect.height) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let cgImage = CGDisplayCreateImage(displayID, rect: pixelRect) else {
            throw NSError(
                domain: "FoxBuddy",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "CGDisplayCreateImageForRect returned nil"]
            )
        }
        return NSImage(cgImage: cgImage, size: rect.size)
    }

    // MARK: - Thumbnail capture (for future use)

    private func captureThumbnail(window: SCWindow) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        // Thumbnails are ~30% of real size — fast and small enough for the grid
        let scale = 0.3
        config.width = max(Int(window.frame.width * scale), 160)
        config.height = max(Int(window.frame.height * scale), 100)
        config.scalesToFit = true
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        let thumbSize = CGSize(width: config.width, height: config.height)
        return NSImage(cgImage: cgImage, size: thumbSize)
    }
}

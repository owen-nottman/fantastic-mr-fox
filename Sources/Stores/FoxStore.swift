import Foundation
import AppKit
import ScreenCaptureKit
import Observation

/// Central state machine for FoxBuddy.
/// AppDelegate and all views share a single instance of this class.
@Observable
final class FoxStore {

    // MARK: - Fox mascot state

    /// Drives the fox emoji animation and bubble visibility.
    var foxState: FoxState = .idle

    /// The current speech bubble. Non-nil while the fox is speaking.
    var bubble: SpeechBubble?

    // MARK: - Input panel state

    /// True while the floating input panel is visible.
    var showInputPanel = false

    /// The text the user has typed in the input field.
    var promptText = ""

    // MARK: - Window attachment state

    /// The SCWindow the user selected from the picker. Captured on submit.
    var selectedWindow: SCWindow?

    /// Thumbnail shown in the input panel to confirm the attachment.
    var selectedWindowThumbnail: NSImage?

    // MARK: - Window picker state

    /// True while the window picker sheet is visible.
    var showWindowPicker = false

    /// Windows loaded for the picker, with pre-fetched thumbnails.
    var availableWindows: [WindowInfo] = []

    /// True while window thumbnails are being fetched.
    var isLoadingWindows = false

    // MARK: - Input panel lifecycle

    func openInputPanel() {
        promptText = ""
        selectedWindow = nil
        selectedWindowThumbnail = nil
        showInputPanel = true
    }

    func closeInputPanel() {
        showInputPanel = false
        showWindowPicker = false
    }

    // MARK: - Window picker

    func openWindowPicker() {
        showWindowPicker = true
        Task { await loadWindows() }
    }

    private func loadWindows() async {
        await MainActor.run { isLoadingWindows = true }
        defer { Task { @MainActor in self.isLoadingWindows = false } }

        do {
            let windows = try await ScreenCaptureService.shared.getWindowInfos()
            await MainActor.run { self.availableWindows = windows }
        } catch {
            // Permission denied or no windows — show empty state in picker
            await MainActor.run { self.availableWindows = [] }
            print("[FoxBuddy] Window enumeration failed: \(error)")
        }
    }

    func selectWindow(_ info: WindowInfo) {
        selectedWindow = info.window
        selectedWindowThumbnail = info.thumbnail
        showWindowPicker = false
    }

    func clearSelectedWindow() {
        selectedWindow = nil
        selectedWindowThumbnail = nil
    }

    // MARK: - Submit

    /// Called when the user presses Return or the send button.
    /// Closes the input panel immediately so the user's workflow is unblocked,
    /// then captures the window and calls Claude in the background.
    func submit() {
        let prompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        let window = selectedWindow
        closeInputPanel()
        foxState = .thinking
        bubble = nil

        Task {
            do {
                // Capture the selected window at full resolution for the API
                var image: NSImage? = nil
                if let window {
                    image = try await ScreenCaptureService.shared.captureWindow(window)
                }
                let response = try await ClaudeAPIService.shared.ask(prompt: prompt, image: image)
                await MainActor.run {
                    self.foxState = .speaking
                    self.bubble = SpeechBubble(content: response)
                    self.scheduleDismiss()
                }
            } catch {
                await MainActor.run {
                    self.foxState = .error(error.localizedDescription)
                    self.bubble = SpeechBubble(content: "Oops — \(error.localizedDescription)")
                    self.scheduleDismiss()
                }
            }
        }
    }

    // MARK: - Bubble dismiss

    func dismissBubble() {
        dismissTask?.cancel()
        bubble = nil
        foxState = .idle
    }

    // MARK: - Private

    private var dismissTask: Task<Void, Never>?

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(SpeechBubble.autoDismissInterval))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.dismissBubble() }
        }
    }
}

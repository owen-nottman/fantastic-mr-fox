import Foundation
import AppKit
import Observation

/// Central state machine for FoxBuddy.
/// AppDelegate and all views share a single instance of this class.
@Observable
final class FoxStore {

    // MARK: - State

    /// Drives fox animation and bubble visibility.
    var foxState: FoxState = .idle

    /// The current speech bubble. Non-nil while the fox is speaking.
    var bubble: SpeechBubble?

    // MARK: - Trigger

    /// Starts the full capture → input → Claude → bubble flow.
    /// Safe to call from any sync context; the async work runs in a Task.
    func trigger() {
        guard foxState == .idle || foxState == .sleeping || foxState == .stretching else { return }
        Task { @MainActor in await runFlow() }
    }

    // MARK: - Bubble dismiss

    func dismissBubble() {
        dismissTask?.cancel()
        bubble = nil
        transitionToIdle()
    }

    // MARK: - Private

    private var dismissTask: Task<Void, Never>?
    private var sleepTask: Task<Void, Never>?

    /// Seconds of idle before the fox falls asleep.
    private static let sleepDelay: TimeInterval = 30
    /// Duration of the stretch animation before capture begins.
    private static let stretchDuration: TimeInterval = 1.2

    @MainActor
    private func runFlow() async {
        cancelSleep()

        // Wake up with a stretch if currently sleeping
        if foxState == .sleeping {
            foxState = .stretching
            try? await Task.sleep(for: .seconds(FoxStore.stretchDuration))
        }

        foxState = .capturing
        bubble = nil

        // 1. Show capture overlay — user drags a region or clicks a window
        guard let captureResult = await CaptureOverlayController.present() else {
            transitionToIdle()
            return
        }

        // 2. Show the message input bar anchored to the captured frame
        let rawMessage = await MessageInputController.present(near: captureResult.frame)

        guard let rawMessage else {
            transitionToIdle()
            return
        }

        foxState = .thinking

        // 3. Ask Claude — image always included; message text is optional
        do {
            let prompt = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = prompt.isEmpty
                ? "What's happening on my screen? React as FoxBuddy."
                : prompt
            let response = try await ClaudeAPIService.shared.ask(
                prompt: text,
                image: captureResult.image
            )
            bubble = SpeechBubble(content: response)
            foxState = .speaking
            scheduleDismiss()
        } catch {
            bubble = SpeechBubble(content: "Oops — \(error.localizedDescription)")
            foxState = .error(error.localizedDescription)
            scheduleDismiss()
        }
    }

    /// Moves to idle and starts the sleep countdown.
    private func transitionToIdle() {
        foxState = .idle
        scheduleSleep()
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(SpeechBubble.autoDismissInterval))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.dismissBubble() }
        }
    }

    private func scheduleSleep() {
        sleepTask?.cancel()
        sleepTask = Task {
            try? await Task.sleep(for: .seconds(FoxStore.sleepDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self.foxState == .idle {
                    self.foxState = .sleeping
                }
            }
        }
    }

    private func cancelSleep() {
        sleepTask?.cancel()
        sleepTask = nil
    }
}

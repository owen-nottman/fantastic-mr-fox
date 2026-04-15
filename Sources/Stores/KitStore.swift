import Foundation
import AppKit
import Observation

/// Central state machine for Kit.
/// AppDelegate and all views share a single instance of this class.
@Observable
final class KitStore {

    // MARK: - State

    /// Drives fox animation and conversation panel visibility.
    var foxState: FoxState = .idle

    /// Full session conversation history.
    var messages: [ConversationMessage] = []

    /// True while the Claude API call is in flight (shows typing indicator).
    var isTyping = false

    // MARK: - Focus callback

    /// Called when the overlay panel should become key (integrated input needs focus).
    /// Set by OverlayWindowController after creating the panel.
    var onNeedsKeyFocus: (() -> Void)?

    // MARK: - Trigger

    /// Starts the full capture → input → Claude → conversation flow.
    func trigger() {
        guard foxState == .idle || foxState == .sleeping || foxState == .stretching else { return }
        Task { @MainActor in await runFlow() }
    }

    // MARK: - Integrated input

    private var inputContinuation: CheckedContinuation<String?, Never>?

    /// Called by ConversationView when the user submits a message.
    func submitMessage(_ text: String) {
        inputContinuation?.resume(returning: text)
        inputContinuation = nil
    }

    /// Called by ConversationView when the user presses Escape.
    func cancelInput() {
        inputContinuation?.resume(returning: nil)
        inputContinuation = nil
    }

    // MARK: - Private

    private var sleepTask: Task<Void, Never>?

    /// Seconds of idle before the fox falls asleep.
    private static let sleepDelay: TimeInterval = 120
    /// Duration of the stretch animation before capture begins.
    private static let stretchDuration: TimeInterval = 2.0
    /// How long the speaking animation plays before returning to idle.
    private static let speakingDuration: TimeInterval = 2.5

    @MainActor
    private func runFlow() async {
        cancelSleep()

        // Wake up with a stretch if currently sleeping
        if foxState == .sleeping {
            foxState = .stretching
            try? await Task.sleep(for: .seconds(KitStore.stretchDuration))
        }

        foxState = .capturing

        // 1. Show capture overlay — user drags a region or clicks a window
        guard let captureResult = await CaptureOverlayController.present() else {
            transitionToIdle()
            return
        }

        // 2. Focus the integrated input in the conversation panel
        foxState = .awaitingInput
        onNeedsKeyFocus?()

        let rawMessage: String? = await withCheckedContinuation { continuation in
            self.inputContinuation = continuation
        }

        guard let rawMessage else {
            transitionToIdle()
            return
        }

        // 3. Add the user's message to the conversation (skip if empty prompt)
        let prompt = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !prompt.isEmpty {
            messages.append(ConversationMessage(sender: .user, content: prompt))
        }

        isTyping = true
        foxState = .thinking

        // 4. Ask Claude — image always included; message text is optional
        do {
            let text = prompt.isEmpty
                ? "What's happening on my screen? React as Kit."
                : prompt
            let response = try await ClaudeAPIService.shared.ask(
                prompt: text,
                image: captureResult.image
            )
            messages.append(ConversationMessage(sender: .fox, content: response))
            isTyping = false
            foxState = .speaking
        } catch {
            messages.append(ConversationMessage(sender: .fox, content: "Oops — \(error.localizedDescription)"))
            isTyping = false
            foxState = .error(error.localizedDescription)
        }

        // Brief speaking/error animation, then return to idle
        try? await Task.sleep(for: .seconds(KitStore.speakingDuration))
        transitionToIdle()
    }

    /// Moves to idle and starts the sleep countdown.
    private func transitionToIdle() {
        foxState = .idle
        scheduleSleep()
    }

    private func scheduleSleep() {
        sleepTask?.cancel()
        sleepTask = Task {
            try? await Task.sleep(for: .seconds(KitStore.sleepDelay))
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

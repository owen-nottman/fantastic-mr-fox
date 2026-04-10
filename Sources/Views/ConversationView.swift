import SwiftUI

// MARK: - Fox colour palette

/// Shared design tokens used across the conversation UI.
enum FoxTheme {
    /// Burnt sienna — primary fox-fur orange.  #E8632A
    static let orange      = Color(red: 0.910, green: 0.388, blue: 0.165)
    /// Soft peachy orange — user bubble fill.  #F4956A
    static let lightOrange = Color(red: 0.957, green: 0.584, blue: 0.416)
    /// Warm cream — fox bubble fill.           #FFF3E6
    static let cream       = Color(red: 1.000, green: 0.953, blue: 0.902)
    /// Panel background cream.                 #FFF8F0
    static let creamPanel  = Color(red: 1.000, green: 0.973, blue: 0.941)
    /// Input row tint.                         #FFF0E0
    static let creamInput  = Color(red: 1.000, green: 0.941, blue: 0.878)
    /// Dark fox-brown for text on light bgs.   #2D1A08
    static let darkBrown   = Color(red: 0.176, green: 0.102, blue: 0.031)
}

// MARK: - ConversationView

/// The chat panel that floats above the fox mascot.
/// Shows the full session history, a typing indicator, and an integrated input field.
struct ConversationView: View {
    let store: FoxStore

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputDivider
            inputRow
        }
        .background(FoxTheme.creamPanel.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: FoxTheme.orange.opacity(0.18), radius: 20, x: 0, y: 6)
        .onChange(of: store.foxState) { _, newState in
            isInputFocused = (newState == .awaitingInput)
        }
    }

    // MARK: - Subviews

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(store.messages) { msg in
                        MessageBubbleView(message: msg)
                    }
                    if store.isTyping {
                        TypingIndicatorView()
                            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
                    }
                    // Anchor for auto-scroll
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 12)
                .padding(.top, 14)
                .padding(.bottom, 8)
            }
            .frame(minHeight: 60, maxHeight: 300)
            .onChange(of: store.messages.count) { _, _ in
                withAnimation(.spring(response: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: store.isTyping) { _, typing in
                if typing {
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.isTyping)
    }

    private var inputDivider: some View {
        Rectangle()
            .fill(FoxTheme.orange.opacity(0.2))
            .frame(height: 1)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Ask FoxBuddy…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(FoxTheme.darkBrown)
                .focused($isInputFocused)
                .disabled(store.foxState != .awaitingInput)
                .onSubmit { submit() }
                .onExitCommand { cancel() }

            if store.foxState == .awaitingInput {
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? FoxTheme.orange.opacity(0.35)
                                : FoxTheme.orange
                        )
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isInputFocused
                ? FoxTheme.creamInput
                : FoxTheme.creamPanel.opacity(0.6)
        )
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: store.foxState == .awaitingInput)
    }

    // MARK: - Actions

    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        store.submitMessage(text)
    }

    private func cancel() {
        inputText = ""
        store.cancelInput()
    }
}

// MARK: - MessageBubbleView

private struct MessageBubbleView: View {
    let message: ConversationMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.sender == .user { Spacer(minLength: 40) }

            Text(message.content)
                .font(.system(size: 13))
                .lineSpacing(2)
                .foregroundStyle(message.sender == .user ? .white : FoxTheme.darkBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if message.sender == .user {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(FoxTheme.lightOrange)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(FoxTheme.cream)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(FoxTheme.orange.opacity(0.32), lineWidth: 1.5)
                            }
                    }
                }

            if message.sender == .fox { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.88, anchor: message.sender == .user ? .bottomTrailing : .bottomLeading)
                .combined(with: .opacity),
            removal: .opacity
        ))
    }
}

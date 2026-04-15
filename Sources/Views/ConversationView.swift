import SwiftUI

/// The chat panel that floats above the fox mascot.
///
/// Structure (top to bottom):
///   Panel bar — icon, title "Kit", decorative traffic lights
///   Progress bar — animated orange strip shown while typing
///   Message list — scrollable conversation history
///   Input row — creamInput-tinted text field + send button
struct ConversationView: View {
    let store: KitStore

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            panelBar
            progressBar
            messageList
            if store.foxState == .awaitingInput {
                inputRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(KitTheme.creamPanel.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(KitTheme.border, lineWidth: 1)
        }
        .shadow(color: KitTheme.orange.opacity(0.18), radius: 20, x: 0, y: 6)
        .onChange(of: store.foxState) { _, newState in
            // Auto-focus the field when input row appears
            isInputFocused = (newState == .awaitingInput)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.foxState == .awaitingInput)
    }

    // MARK: - Panel bar

    private var panelBar: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(KitTheme.orange)
                .frame(width: 20, height: 20)
                .overlay { Text("🦊").font(.system(size: 12)) }

            Text("Kit")
                .font(KitTheme.label())
                .foregroundStyle(KitTheme.darkBrown)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 40)
        .background(KitTheme.creamPanel)
        .overlay(alignment: .bottom) {
            Rectangle().fill(KitTheme.borderLight).frame(height: 0.5)
        }
    }

    // MARK: - Progress bar (shown while typing)

    @ViewBuilder
    private var progressBar: some View {
        if store.isTyping {
            IndeterminateProgressBar()
                .frame(height: 4)
                .transition(.opacity)
        }
    }

    // MARK: - Message list

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
                    Color.clear.frame(height: 1).id("bottom")
                }
                // Essential: forces the stack (and its children) to fill the scroll view width
                .frame(maxWidth: .infinity)
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

    // MARK: - Input row

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField(
                "",
                text: $inputText,
                prompt: Text("Ask Kit…").foregroundStyle(KitTheme.darkBrown.opacity(0.40))
            )
            .textFieldStyle(.plain)
            .font(KitTheme.body())
            .foregroundStyle(KitTheme.darkBrown)
            .focused($isInputFocused)
            .onSubmit { submit() }
            .onExitCommand { cancel() }

            if store.foxState == .awaitingInput {
                sendButton
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(KitTheme.creamInput)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(KitTheme.darkBrown.opacity(isInputFocused ? 0.25 : 0.15), lineWidth: 1)
                }
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(KitTheme.creamPanel)
        .overlay(alignment: .top) {
            Rectangle().fill(KitTheme.borderLight).frame(height: 0.5)
        }
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: store.foxState == .awaitingInput)
    }

    private var sendButton: some View {
        let hasText = !inputText.trimmingCharacters(in: .whitespaces).isEmpty
        return Button(action: submit) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(KitTheme.orange.opacity(hasText ? 1 : 0.35))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
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

// MARK: - Indeterminate progress bar

/// Animated orange strip that slides across the panel bar while Kit is thinking.
private struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(KitTheme.darkBrown.opacity(0.08))

                Rectangle()
                    .fill(KitTheme.orange)
                    .frame(width: geo.size.width * 0.35)
                    .offset(x: offset * geo.size.width)
            }
        }
        .clipShape(Rectangle())
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                offset = 1
            }
        }
    }
}

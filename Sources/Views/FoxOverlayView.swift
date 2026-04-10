import SwiftUI

/// Root SwiftUI view hosted inside the always-visible overlay panel.
/// Stacks the conversation panel above the fox mascot; both slide in/out with springs.
struct FoxOverlayView: View {
    let store: FoxStore

    private var showConversation: Bool {
        !store.messages.isEmpty || store.isTyping || store.foxState == .awaitingInput
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()

            if showConversation {
                ConversationView(store: store)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88, anchor: .bottomTrailing).combined(with: .opacity),
                        removal: .scale(scale: 0.92, anchor: .bottomTrailing).combined(with: .opacity)
                    ))
                    .padding(.bottom, 8)
            }

            FoxMascotView(store: store)
        }
        .padding(8)
        .animation(.spring(response: 0.38, dampingFraction: 0.74), value: showConversation)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: store.messages.count)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: store.isTyping)
    }
}

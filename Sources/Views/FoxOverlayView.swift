import SwiftUI

/// Root SwiftUI view hosted inside the always-visible overlay panel.
/// Stacks the speech bubble above the fox mascot, animating in/out with a spring.
struct FoxOverlayView: View {
    let store: FoxStore

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Spacer()

            // Speech bubble slides in above the fox when the fox is speaking
            if let bubble = store.bubble {
                SpeechBubbleView(bubble: bubble) {
                    store.dismissBubble()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            FoxMascotView(store: store)
        }
        .padding(8)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: store.bubble != nil)
    }
}

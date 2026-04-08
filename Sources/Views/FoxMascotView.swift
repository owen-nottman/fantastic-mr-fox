import SwiftUI

/// The fox emoji that floats on screen.
/// Tapping it opens the input panel, the same as pressing ⌥F.
struct FoxMascotView: View {
    let store: FoxStore

    @State private var isHovered = false
    @State private var bounce = false

    var body: some View {
        Text("🦊")
            .font(.system(size: 52))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            // Hover scale
            .scaleEffect(isHovered ? 1.12 : 1.0)
            // Gentle bounce while thinking
            .offset(y: bounce ? -4 : 0)
            .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: bounce)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
            .onHover { isHovered = $0 }
            .onTapGesture { store.openInputPanel() }
            .onChange(of: store.foxState) { _, newState in
                bounce = (newState == .thinking)
            }
            .help("Tap or press ⌥F to ask FoxBuddy")
    }
}

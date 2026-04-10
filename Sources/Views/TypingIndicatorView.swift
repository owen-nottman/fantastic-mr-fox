import SwiftUI

/// Three bouncing dots shown while FoxBuddy is waiting for a Claude response.
struct TypingIndicatorView: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(FoxTheme.orange)
                    .frame(width: 7, height: 7)
                    .offset(y: animate ? -5 : 2)
                    .animation(
                        .easeInOut(duration: 0.48)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.16),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

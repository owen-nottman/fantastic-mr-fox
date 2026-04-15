import SwiftUI

/// Three bouncing orange dots rendered inside a fox-style cream bubble,
/// shown while Kit is waiting for a Claude response.
struct TypingIndicatorView: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar matches fox bubble layout
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(KitTheme.orange)
                .frame(width: 30, height: 30)
                .overlay {
                    Text("🦊")
                        .font(.system(size: 16))
                }
                .padding(.top, 2)

            // Dots inside a cream bubble shell
            HStack(alignment: .center, spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(KitTheme.orange)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 3,
                    bottomTrailingRadius: 14,
                    topTrailingRadius: 14,
                    style: .continuous
                )
                .fill(KitTheme.cream)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 3,
                        bottomTrailingRadius: 14,
                        topTrailingRadius: 14,
                        style: .continuous
                    )
                    .strokeBorder(KitTheme.orange.opacity(0.22), lineWidth: 0.5)
                }
            }

            Spacer(minLength: 40)
        }
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

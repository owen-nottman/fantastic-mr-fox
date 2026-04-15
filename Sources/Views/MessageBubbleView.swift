import SwiftUI

/// A single chat message rendered as a branded bubble.
///
/// Fox bubbles sit left-aligned with a warm cream fill and a sharp bottom-left corner.
/// User bubbles sit right-aligned with a peachy orange fill and a sharp bottom-right corner.
struct MessageBubbleView: View {
    let message: ConversationMessage

    var body: some View {
        if message.sender == .fox {
            foxBubble
        } else {
            userBubble
        }
    }

    // MARK: - Fox bubble (left-aligned, with avatar)

    private var foxBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            foxAvatar

            Text(message.content)
                .font(KitTheme.body())
                .foregroundStyle(KitTheme.darkBrown)
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
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

            Spacer()
        }
        // Force the row to fill available width so the bubble + avatar expand correctly
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.88, anchor: .bottomLeading).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - User bubble (right-aligned)

    private var userBubble: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer()

            Text(message.content)
                .font(KitTheme.body())
                .foregroundStyle(KitTheme.darkBrown)
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 3,
                        topTrailingRadius: 14,
                        style: .continuous
                    )
                    .fill(KitTheme.lightOrange)
                }
        }
        // Force the row to fill available width so the bubble right-aligns correctly
        .frame(maxWidth: .infinity, alignment: .trailing)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.88, anchor: .bottomTrailing).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Fox avatar

    private var foxAvatar: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(KitTheme.orange)
            .frame(width: 30, height: 30)
            .overlay { Text("🦊").font(.system(size: 16)) }
            .padding(.top, 2)
    }
}

import SwiftUI

/// A frosted-glass speech bubble that appears above the fox mascot.
/// Tapping it or waiting `autoDismissInterval` seconds dismisses it.
struct SpeechBubbleView: View {
    let bubble: SpeechBubble
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Scrollable text so long responses don't overflow the overlay panel
            ScrollView {
                Text(bubble.content)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: 160)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 260)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        )
        .onTapGesture { onDismiss() }
    }
}

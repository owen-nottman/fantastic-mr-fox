import Foundation

/// A speech bubble that FoxBuddy displays above the fox mascot.
/// Auto-dismissed after `autoDismissInterval` seconds unless tapped first.
struct SpeechBubble: Identifiable {
    let id = UUID()
    let content: String
    let createdAt = Date()

    static let autoDismissInterval: TimeInterval = 10
}

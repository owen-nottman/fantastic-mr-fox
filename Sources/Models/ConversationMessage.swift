import Foundation

/// A single message in the FoxBuddy conversation thread.
struct ConversationMessage: Identifiable {
    enum Sender { case user, fox }
    let id = UUID()
    let sender: Sender
    let content: String
    let timestamp = Date()
}

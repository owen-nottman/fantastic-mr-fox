/// The observable state of the fox mascot.
/// Drives animation and determines what the conversation panel shows.
enum FoxState: Equatable {
    case idle
    case sleeping           // entered after 120 s of idle
    case stretching         // brief waking animation when triggered from sleep
    case capturing
    case awaitingInput      // capture done; integrated input field is focused
    case thinking
    case speaking
    case error(String)

    static func == (lhs: FoxState, rhs: FoxState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.sleeping, .sleeping), (.stretching, .stretching),
             (.capturing, .capturing), (.awaitingInput, .awaitingInput),
             (.thinking, .thinking), (.speaking, .speaking): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

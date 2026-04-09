/// The observable state of the fox mascot.
/// Drives animation and determines whether a speech bubble is shown.
enum FoxState: Equatable {
    case idle
    case sleeping           // entered after 30 s of idle
    case stretching         // brief waking animation when triggered from sleep
    case capturing
    case thinking
    case speaking
    case error(String)

    static func == (lhs: FoxState, rhs: FoxState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.sleeping, .sleeping), (.stretching, .stretching),
             (.capturing, .capturing), (.thinking, .thinking), (.speaking, .speaking): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// The observable state of the fox mascot.
/// Drives emoji animation and determines whether a speech bubble is shown.
enum FoxState: Equatable {
    case idle
    case thinking
    case speaking
    case error(String)

    static func == (lhs: FoxState, rhs: FoxState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.thinking, .thinking), (.speaking, .speaking): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

import Foundation

// MARK: - Response

/// Top-level response from the Claude Messages API.
struct ClaudeResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case missingAPIKey
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "ANTHROPIC_API_KEY environment variable is not set."
        case .apiError(let code, let body):
            return "API error \(code): \(body)"
        }
    }
}

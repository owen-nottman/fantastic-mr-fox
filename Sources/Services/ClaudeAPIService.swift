import Foundation
import AppKit
import Security

/// Sends text + optional window screenshot to Claude's Messages API and returns the response.
final class ClaudeAPIService {
    static let shared = ClaudeAPIService()
    private init() {}

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    /// Reads from the environment first, then falls back to the macOS Keychain.
    /// This ensures the key is available whether or not the shell sourced .zshrc.
    private var apiKey: String? {
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            return key
        }
        return keychainAPIKey()
    }

    private func keychainAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "ANTHROPIC_API_KEY",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    private let systemPrompt = """
        You are FoxBuddy, a sharp and friendly fox who helps users understand what's on their screen. \
        Give concise, useful responses — like a clever friend looking over their shoulder. \
        Keep replies under 3 sentences unless more detail is truly needed. \
        Be direct and occasionally witty, never verbose.
        """

    // MARK: - Public API

    /// Ask Claude a question, optionally attaching a screenshot of a window.
    ///
    /// - Parameters:
    ///   - prompt: The user's text question.
    ///   - image: An NSImage of the window to include in the request, or nil for text-only.
    /// - Returns: The assistant's response text.
    func ask(prompt: String, image: NSImage?) async throws -> String {
        guard let key = apiKey else { throw ClaudeError.missingAPIKey }

        // Build the content array: image first (if present), then text
        var content: [[String: Any]] = []

        if let image, let pngData = image.pngData() {
            content.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/png",
                    "data": pngData.base64EncodedString()
                ]
            ])
        }

        content.append([
            "type": "text",
            "text": prompt
        ])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [["role": "user", "content": content]]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.apiError(0, "No HTTP response")
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw ClaudeError.apiError(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.content.first(where: { $0.type == "text" })?.text ?? "(no response)"
    }
}

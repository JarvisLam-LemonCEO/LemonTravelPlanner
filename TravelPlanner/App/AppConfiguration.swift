import Foundation

enum AppConfiguration {

    // MARK: - AI Provider

    enum AIProvider {
        case mock
        case lmStudio
        case openAI
    }

    /// Select the AI provider
    static let provider: AIProvider = .lmStudio

    // MARK: - LM Studio

    static let lmStudioBaseURL = URL(
        string: "http://127.0.0.1:1234"
    )!

    static let lmStudioModel =
        "google/gemma-4-e4b"

    // MARK: - OpenAI Backend

    static let backendURL = URL(
        string: "https://your-server.com"
    )!
}

import Foundation

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ResponseFormat: Encodable {
    let type: String
    let jsonSchema: JSONSchemaContainer

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

struct JSONSchemaContainer: Encodable {
    let name: String
    let strict: Bool
    let schema: JSONValue
}

struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ResponseMessage
    }

    struct ResponseMessage: Decodable {
        let role: String?
        let content: String?
    }
}

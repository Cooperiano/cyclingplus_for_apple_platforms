//
//  RemoteAIClient.swift
//  cyclingplus
//
//  Created by Codex on 2025/11/30.
//

import Foundation

struct RemoteAIClient {
    enum Provider: String {
        case deepseek
        case openai
        
        var endpoint: URL {
            switch self {
            case .deepseek:
                return URL(string: "https://api.deepseek.com/chat/completions")!
            case .openai:
                return URL(string: "https://api.openai.com/v1/chat/completions")!
            }
        }
        
        var defaultModel: String {
            switch self {
            case .deepseek: return "deepseek-chat"
            case .openai: return "gpt-3.5-turbo"
            }
        }
    }
    
    struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        
        let model: String
        let messages: [Message]
        let temperature: Double?
        let max_tokens: Int?
    }
    
    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
    
    func chat(
        provider: Provider,
        apiKey: String,
        prompt: String,
        model: String? = nil,
        system: String? = nil
    ) async throws -> String {
        var request = URLRequest(url: provider.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var messages: [ChatRequest.Message] = []
        if let system = system {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", content: prompt))
        
        let payload = ChatRequest(
            model: model ?? provider.defaultModel,
            messages: messages,
            temperature: 0.7,
            max_tokens: 1200
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw CyclingPlusError.analysisError("Invalid response from AI provider")
        }
        guard 200..<300 ~= http.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CyclingPlusError.analysisError("AI provider error \(http.statusCode): \(text)")
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw CyclingPlusError.analysisError("Empty response from AI provider")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation
import SwiftUI

// Chat template protocol for formatting messages
protocol ChatTemplate {
    func formatMessages(_ messages: [ChatMessage]) -> String
}


class ChatMessage: ObservableObject, Identifiable, Codable {
    let id: UUID // Asegurarse de que el id sea codificable
    @Published var content: String
    let role: Role
    let date: Date
    @Published var isLoading: Bool // Nueva propiedad para indicar si el mensaje está en proceso de carga
    
    init(id: UUID = UUID(), content: String, role: Role, date: Date = Date(), isLoading: Bool = false) {
        self.id = id
        self.content = content
        self.role = role
        self.date = date
        self.isLoading = isLoading
    }
    
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, content, role, date, isLoading
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.role = try container.decode(Role.self, forKey: .role)
        self.date = try container.decode(Date.self, forKey: .date) // Decodificar date
        self.isLoading = try container.decodeIfPresent(Bool.self, forKey: .isLoading) ?? false // Decodificar isLoading, por defecto en false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(role, forKey: .role)
        try container.encode(date, forKey: .date) // Codificar date
        try container.encode(isLoading, forKey: .isLoading) // Codificar isLoading
    }
}

@MainActor
class LlamaChatCompletion {
    private var llamaState: LlamaState
    private var stopGeneration = false
    @Published var isLoading = false
    
    init(llamaState: LlamaState) {
        self.llamaState = llamaState
    }
    
    /// Emulates OpenAI's `chatCompletion` method using the model state in `LlamaState`.
    /// - Parameters:
    ///   - messages: A list of `ChatMessage` in chat format with roles like "system", "user", and "assistant".
    ///   - model: Name of the model to be used. If downloaded in `LlamaState`, it loads it.
    ///   - maxTokens: Maximum number of tokens in the response (optional).
    ///   - temperature: Creativity control in the response (optional).
    ///   - stop: A list of sequences to stop text generation (optional).
    ///   - resultHandler: A function that handles each generated text fragment.
    ///   - onComplete: A function that runs when generation is completed.
    func chatCompletion(
        messages: [ChatMessage],
        maxTokens: Int = 100,
        temperature: Double = 0.7,
        stop: [String]? = nil,
        resultHandler: @escaping (String) -> Void,
        onComplete: @escaping () -> Void
    ) async {
        if let prompt = llamaState.selectedModel?.chatTemplate(messages) {
            await llamaState.complete(text: prompt, resultHandler: resultHandler, onComplete: onComplete)
        } else {
            print("Error: el modelo no está disponible o no se generó un prompt.")
            onComplete()
        }
    }
    
    // Method to stop the ongoing generation
    func stopCompletion() async {
        stopGeneration = true
        await self.llamaState.stop()
    }
}

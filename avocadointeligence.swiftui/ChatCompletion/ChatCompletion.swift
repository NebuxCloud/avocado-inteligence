import Foundation

// Chat template protocol for formatting messages
protocol ChatTemplate {
    func formatMessages(_ messages: [ChatMessage]) -> String
}

class ChatMessage: ObservableObject {
    let content: String
    let role: Role
    
    init(content: String, role: Role) {
        self.content = content
        self.role = role
    }
    
    enum Role {
        case user
        case assistant
        case system
    }
}

@BackgroundActor
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
    func stopCompletion() {
        stopGeneration = true
    }
}

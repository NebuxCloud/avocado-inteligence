import SwiftUI
import Combine
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversation: Conversation?
    @Published var selectedConversationIndex: Int?
    @Published var isLoading: Bool = false
    @Published var userInput: String = ""
    @Published var stopGeneration: Bool = false
    private var llamaState: LlamaState
    private var chatCompletion: LlamaChatCompletion
    @Binding var isMenuVisible: Bool // Binding para sincronizar el estado del menú

    init(llamaState: LlamaState, isMenuVisible: Binding<Bool>) {
        self.llamaState = llamaState
        self._isMenuVisible = isMenuVisible // Asignar el binding
        self.chatCompletion = LlamaChatCompletion(llamaState: llamaState)
        loadConversations()
    }

    func selectConversation(at index: Int) {
        guard conversations.indices.contains(index) else { return }
        selectedConversationIndex = index
        selectedConversation = conversations[index]
        print("selected conversation \(index)")
    }

    func startNewConversation() {
        let newConversation = Conversation(
            title: "",
            messages: [Message(text: "You are an intelligent and highly responsive assistant, equipped with deep knowledge across diverse fields. Your primary goal is to provide clear, accurate, and well-structured information that meets the user’s needs. Always prioritize clarity, professionalism, and conciseness, and adapt your responses to align with the user’s intent. Answer questions thoroughly but avoid unnecessary detail, and engage in a friendly yet respectful manner. You aim to be insightful, approachable, and consistently helpful.", role: .system)],
            date: Date()
        )
        conversations.append(newConversation)
        selectConversation(at: conversations.count - 1)
    }

    func sendMessage() async {
        guard let selectedIndex = selectedConversationIndex else { return }
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Prepare user message
        let userMessage = Message(text: userInput.trimmingCharacters(in: .whitespacesAndNewlines), role: .user)
        conversations[selectedIndex].messages.append(userMessage)
        userInput = ""
        isLoading = true
        stopGeneration = false

        // Prepare placeholder for assistant response
        let assistantMessage = Message(text: "", role: .assistant)
        conversations[selectedIndex].messages.append(assistantMessage)

        do {
            // Generate assistant response
            let chatMessages = conversations[selectedIndex].messages.map {
                ChatMessage(content: $0.text, role: $0.role == .user ? .user : .assistant)
            }

            try await chatCompletion.chatCompletion(
                messages: chatMessages,
                resultHandler: { [weak self] newResult in
                    guard let self = self else { return }
                    if self.stopGeneration {
                        self.isLoading = false
                        return
                    }
                    Task { @MainActor in
                        // Append newResult to assistant's last message text
                        if let messageIndex = self.conversations[selectedIndex].messages.lastIndex(where: { $0.role == .assistant }) {
                            self.conversations[selectedIndex].messages[messageIndex].text += newResult
                        }
                    }
                },
                onComplete: { [weak self] in
                    Task { @MainActor in
                        self?.isLoading = false
                        
                        if chatMessages.count == 3 {
                            guard let self = self else { return }

                            await self.generateTitle(for: selectedIndex)
                        }
                        
                        self?.saveConversations()
                    }
                }
            )
        } catch {
            // Handle error during message generation
            let errorMessage = Message(text: "An error occurred: \(error.localizedDescription)", role: .assistant)
            conversations[selectedIndex].messages.append(errorMessage)
            isLoading = false
        }
    }
    
    private func generateTitle(for index: Int) async {
        // Create a prompt to generate a title based on the conversation context
        let prompt = "Generate a concise and engaging title for the following conversation based on the initial message:\n\n\(conversations[index].messages[1].text)"
        
        do {
            // Call the chat completion API to generate a title
            try await chatCompletion.chatCompletion(
                messages: [ChatMessage(content: prompt, role: .system)],
                resultHandler: { [weak self] newTitle in
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.conversations[index].title += newTitle
                        self.saveConversations()
                    }
                },
                onComplete: {}
            )
        } catch {
            print("Failed to generate title: \(error)")
        }
    }
    
    func stopConversation() async {
        stopGeneration = false
        await self.llamaState.stop()
    }

    // Save conversations to UserDefaults
    func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Failed to save conversations: \(error)")
        }
    }
    
    func deleteConversation(byID id: UUID) {
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations.remove(at: index)
            saveConversations()

            // Si la conversación eliminada era la seleccionada, actualiza la selección
            if selectedConversation?.id == id {
                if conversations.isEmpty {
                    startNewConversation()
                } else if index > 0 {
                    selectConversation(at: index - 1)
                } else {
                    selectConversation(at: 0)
                }
            }
        }
    }

    // Load conversations from UserDefaults
    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "savedConversations") {
            do {
                conversations = try JSONDecoder().decode([Conversation].self, from: data)
                if let lastIndex = conversations.indices.last {
                    selectConversation(at: lastIndex)
                } else {
                    startNewConversation()
                }
            } catch {
                print("Failed to load conversations: \(error)")
                startNewConversation()
            }
        } else {
            startNewConversation()
        }
    }
}

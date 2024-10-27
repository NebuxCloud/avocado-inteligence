import SwiftUI
import Combine
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversationIndex: Int?
    @Published var isLoading: Bool = false
    @Published var userInput: String = ""
    @Published var stopGeneration: Bool = false
    @Published var showConversationList = false
    private var llamaState: LlamaState
    private var chatCompletion: LlamaChatCompletion

    init(llamaState: LlamaState) {
        self.llamaState = llamaState
        self.chatCompletion = LlamaChatCompletion(llamaState: llamaState)
        loadConversations()
    }
    
    func stop() {
        stopGeneration = true
    }
    
    var selectedConversation: Conversation? {
        get {
            guard let index = selectedConversationIndex else { return nil }
            return conversations[index]
        }
        set {
            guard let index = selectedConversationIndex, let newValue = newValue else { return }
            conversations[index] = newValue
        }
    }

    func sendMessage() async {
        guard var conversation = selectedConversation else { return }

        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        let userMessage = Message(text: input, role: .user)
        conversation.messages.append(userMessage)
        selectedConversation = conversation
        userInput = ""
        isLoading = true
        stopGeneration = false

        let assistantMessage = Message(text: "", role: .assistant)
        conversation.messages.append(assistantMessage)
        selectedConversation = conversation

        do {
            var assistantText = ""
            let chatMessages = conversation.messages.map { ChatMessage(content: $0.text, role: $0.role == .user ? .user : .assistant) }

            if conversation.messages.count == 3 {
                await self.updateConversationTitle(for: conversation, initialMessage: input)
            }
            
            try await chatCompletion.chatCompletion(
                messages: chatMessages,
                resultHandler: { [weak self] newResult in
                    guard let self = self else { return }
                    
                    if self.stopGeneration {
                        self.isLoading = false
                        return
                    }

                    assistantText += newResult
                    Task { @MainActor in
                        if var selected = self.selectedConversation {
                            if let index = selected.messages.lastIndex(where: { $0.role == .assistant }) {
                                selected.messages[index].text += newResult
                                self.selectedConversation = selected
                            }
                        }
                    }
                },
                onComplete: { [weak self] in
                    Task { @MainActor in
                        guard let self = self else { return }
                        
                        self.isLoading = false
                        self.saveConversations()
                    }
                }
            )
        } catch {
            let errorMessage = Message(text: "An error occurred: \(error.localizedDescription)", role: .assistant)
            conversation.messages.append(errorMessage)
            selectedConversation = conversation
            isLoading = false
        }
    }
    
    func deleteAllConversations() {
        conversations.removeAll()
        saveConversations()
    }

    func deleteConversation(at indexSet: IndexSet) {
        for index in indexSet {
            conversations.remove(at: index)
            if selectedConversationIndex == index {
                selectedConversationIndex = nil
            } else if let selected = selectedConversationIndex, selected > index {
                selectedConversationIndex = selected - 1
            }
        }
        
        saveConversations()
    }
    
    func startNewConversation() {
        let newConversation = Conversation(title: "", messages: [Message(text: "You are a knowledgeable and responsive assistant...", role: .system)], date: Date())
        conversations.append(newConversation)
        selectedConversationIndex = conversations.count - 1
        
        Task { @MainActor in
            self.showConversationList = false
        }
    }

    private func updateConversationTitle(for conversation: Conversation, initialMessage: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task {
                do {
                    var title = ""
                    try await chatCompletion.chatCompletion(
                        messages: [
                            ChatMessage(content: "Create a title from the initial message, with 3 words, no more output: \(initialMessage)", role: .system)
                        ],
                        resultHandler: { [weak self] newResult in
                            guard let self = self else { return }
                            
                            if self.stopGeneration {
                                self.isLoading = false
                                continuation.resume(returning: nil)
                                return
                            }

                            title += newResult
                        },
                        onComplete: { [weak self] in
                            Task { @MainActor in
                                guard let self = self else { return }
                                
                                if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                                    self.conversations[index].title = title
                                }
                                continuation.resume(returning: title)
                            }
                        }
                    )
                } catch {
                    isLoading = false
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func selectConversation(at index: Int) {
        selectedConversationIndex = index
    }


    func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Failed to save conversations: \(error)")
        }
    }

    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "savedConversations") {
            do {
                conversations = try JSONDecoder().decode([Conversation].self, from: data)
            } catch {
                print("Failed to load conversations: \(error)")
                startNewConversation()
            }
        } else {
            startNewConversation()
        }
    }
}

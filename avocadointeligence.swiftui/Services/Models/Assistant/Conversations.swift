import Foundation
import Combine

class Conversations: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    private let conversationsKey = "savedConversations"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFromUserDefaults()
    }
    
    func addConversation(title: String, date: Date = Date(), messages: [ChatMessage] = []) {
        let conversation = Conversation(title: title, date: date, messages: messages)
        conversations.append(conversation)
        saveToUserDefaults()
        observeConversation(conversation)
    }
    
    func addEmptyConversation() -> Conversation {
        let newConversation = Conversation(title: "", date: Date(), messages: [])
        conversations.append(newConversation)
        saveToUserDefaults()
        observeConversation(newConversation)
        return newConversation
    }
    
    func deleteConversation(at index: Int) {
        guard conversations.indices.contains(index) else {
            print("Index out of range.")
            return
        }
        conversations.remove(at: index)
        saveToUserDefaults()
    }
    
    func deleteConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            deleteConversation(at: index)
        } else {
            print("Conversation not found.")
        }
    }
    
    func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(conversations)
            UserDefaults.standard.set(data, forKey: conversationsKey)
            print("Conversations saved to UserDefaults.")
        } catch {
            print("Error saving conversations: \(error)")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: conversationsKey) {
            do {
                conversations = try JSONDecoder().decode([Conversation].self, from: data)
                for conversation in conversations {
                    observeConversation(conversation)
                }
                print("Conversations loaded from UserDefaults.")
            } catch {
                print("Error loading conversations: \(error)")
            }
        } else {
            print("No conversations found in UserDefaults.")
        }
    }
    
    private func observeConversation(_ conversation: Conversation) {
        conversation.objectWillChange
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
    }
}

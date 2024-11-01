import Foundation

class Conversation: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var title: String
    var date: Date
    @Published var messages: [ChatMessage]
    
    init(id: UUID = UUID(), title: String, date: Date, messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.messages = messages
    }
    
    // Enum para las claves de codificación
    private enum CodingKeys: String, CodingKey {
        case id, title, date, messages
    }
    
    func addMessage(content: String, role: ChatMessage.Role) {
        let newMessage = ChatMessage(content: content, role: role)
        messages.append(newMessage)
        self.date = Date()
    }
    
    // Nuevo método para añadir un ChatMessage existente
    func appendMessage(_ message: ChatMessage) {
        messages.append(message)
        self.date = Date()
    }
    
    func updateTitle(newTitle: String) {
        title = newTitle
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(messages, forKey: .messages)
    }
}

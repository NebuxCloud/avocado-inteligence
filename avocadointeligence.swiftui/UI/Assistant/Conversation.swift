import SwiftUI
import Foundation

class Conversation: ObservableObject, Identifiable, Codable {
    @Published var title: String
    @Published var messages: [Message]
    var date: Date
    let id: UUID

    // Propiedades privadas para respaldo en codificación
    private var titleStorage: String
    private var messagesStorage: [Message]

    enum CodingKeys: CodingKey {
        case title, messages, date, id
    }

    init(title: String, messages: [Message], date: Date) {
        self.title = title
        self.messages = messages
        self.date = date
        self.id = UUID()

        // Inicializar los valores de respaldo
        self.titleStorage = title
        self.messagesStorage = messages
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        titleStorage = try container.decode(String.self, forKey: .title)
        messagesStorage = try container.decode([Message].self, forKey: .messages)
        date = try container.decode(Date.self, forKey: .date)
        id = try container.decode(UUID.self, forKey: .id)

        // Sincronizar con propiedades @Published
        title = titleStorage
        messages = messagesStorage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(date, forKey: .date)
        try container.encode(id, forKey: .id)
    }
}

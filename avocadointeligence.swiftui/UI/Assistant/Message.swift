import SwiftUI
import Combine

class Message: Identifiable, ObservableObject, Codable, Equatable {
    let id = UUID()
    @Published var text: String
    let role: Role

    init(text: String, role: Role) {
        self.text = text
        self.role = role
    }

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    // Implementación manual de codificación y decodificación
    enum CodingKeys: CodingKey {
        case text, role
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id && lhs.text == rhs.text && lhs.role == rhs.role
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.role = try container.decode(Role.self, forKey: .role)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(role, forKey: .role)
    }
}

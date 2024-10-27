import SwiftUI

struct Conversation: Identifiable, Codable {
    let id = UUID()
    var title: String
    var messages: [Message]
    var date: Date
}

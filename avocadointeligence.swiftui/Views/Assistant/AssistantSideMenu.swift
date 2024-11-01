import SwiftUI

struct AssistantMenuContent: View {
    @Binding var selectedConversation: Conversation?
    @Binding var conversations: Conversations?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("conversations_title", comment: "Title for conversations list"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            List {
                if let conversations = conversations?.conversations {
                    ForEach(conversations) { conversation in
                        Button(action: {
                            selectedConversation = conversation
                        }) {
                            HStack {
                                Text(conversation.title)
                                    .font(.subheadline)
                                Spacer()
                                Text(conversation.date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .onDelete(perform: deleteConversation)
                } else {
                    Text(NSLocalizedString("no_conversations_available", comment: "Message when no conversations are available"))
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func deleteConversation(at offsets: IndexSet) {
        guard let conversations = conversations else { return }
        
        offsets.forEach { index in
            let conversationToDelete = conversations.conversations[index]
            let isSelectedConversation = conversationToDelete.id == selectedConversation?.id
            
            conversations.deleteConversation(at: index)
            
            if isSelectedConversation {
                let newConversation = conversations.addEmptyConversation()
                selectedConversation = newConversation
            }
        }
    }
}

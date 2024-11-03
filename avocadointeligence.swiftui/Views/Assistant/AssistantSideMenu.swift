import SwiftUI

struct AssistantMenuContent: View {
    @Binding var selectedConversation: Conversation?
    @Binding var conversations: Conversations?
    @Binding var refreshTrigger: Bool
    @State private var isEditing = false

    // Style properties
    private let headerFont = Font.system(size: 24, weight: .bold)
    private let titleFont = Font.system(size: 18, weight: .medium)
    private let dateFont = Font.system(size: 14, weight: .regular)
    private let backgroundColor = Color(UIColor.systemGroupedBackground)
    private let accentColor = Color.blue

    // Computed property to group conversations by day
    private var groupedConversations: [(key: String, value: [Conversation])] {
        guard let conversations = conversations?.conversations else { return [] }
        let sortedConversations = conversations.sorted { $0.date > $1.date }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: sortedConversations) { conversation -> String in
            formatter.string(from: conversation.date)
        }
        return grouped.sorted { lhs, rhs in
            guard let lhsDate = formatter.date(from: lhs.key),
                  let rhsDate = formatter.date(from: rhs.key) else { return false }
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(NSLocalizedString("conversations_title", comment: "Title for conversations list"))
                    .font(headerFont)
                    .padding(.leading)
                    .padding(.top)
                Spacer()
                // Edit button
                Button(action: {
                    withAnimation {
                        isEditing.toggle()
                    }
                }) {
                    Text(isEditing ? NSLocalizedString("done", comment: "Done editing") : NSLocalizedString("edit", comment: "Edit"))
                        .foregroundColor(accentColor)
                        .padding(.trailing)
                        .padding(.top)
                }
            }
            .padding(.bottom)

            if let conversations = conversations?.conversations, !conversations.isEmpty {
                List {
                    ForEach(groupedConversations, id: \.key) { group in
                        Section(header: Text(group.key).font(.headline)) {
                            ForEach(group.value) { conversation in
                                Button(action: {
                                    selectedConversation = conversation
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(conversation.title)
                                                .font(titleFont)
                                                .foregroundColor(.primary)
                                            Text(conversation.date, style: .time)
                                                .font(dateFont)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if conversation.id == selectedConversation?.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(accentColor)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .onDelete { indices in
                                deleteConversation(in: group.value, at: indices)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            } else {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("no_conversations_available", comment: "Message when no conversations are available"))
                        .foregroundColor(.gray)
                        .italic()
                    Spacer()
                }
            }
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
    }

    private func deleteConversation(in group: [Conversation], at offsets: IndexSet) {
        guard var conversations = conversations else { return }
        offsets.forEach { index in
            let conversationToDelete = group[index]
            if let originalIndex = conversations.conversations.firstIndex(where: { $0.id == conversationToDelete.id }) {
                let isSelectedConversation = conversations.conversations[originalIndex].id == selectedConversation?.id
                conversations.deleteConversation(at: originalIndex)
                if isSelectedConversation {
                    let newConversation = conversations.addEmptyConversation()
                    selectedConversation = newConversation
                }
            }
        }
        self.refreshTrigger.toggle()
    }
}

import SwiftUI
import Combine

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.conversations.isEmpty {
                    VStack {
                        Text("No conversations available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(groupedConversations.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date)).font(.subheadline).foregroundColor(.secondary)) {
                            ForEach(groupedConversations[date] ?? []) { conversation in
                                Button(action: {
                                    if let index = viewModel.conversations.firstIndex(where: { $0.id == conversation.id }) {
                                        viewModel.selectConversation(at: index)
                                    }
                                }) {
                                    HStack {
                                        Text(conversation.title.isEmpty ? "New Conversation" : conversation.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(formatTime(conversation.date))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .onDelete { indexSet in
                                deleteConversationByIndex(indexSet, date: date)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Conversations")
            .toolbar {
                EditButton()
            }
        }
    }
    
    // Group conversations by date
    private var groupedConversations: [Date: [Conversation]] {
        Dictionary(grouping: viewModel.conversations, by: { Calendar.current.startOfDay(for: $0.date) })
    }
    
    // Delete conversation by index
    private func deleteConversationByIndex(_ indexSet: IndexSet, date: Date) {
        if let index = indexSet.first, let conversation = groupedConversations[date]?[index] {
            viewModel.deleteConversation(byID: conversation.id)
        }
    }
    
    // Format date for section headers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Formatter to display time in each conversation cell
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

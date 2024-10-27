import SwiftUI
import Combine

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.conversations.isEmpty {
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No conversations available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Convert dictionary to an array of tuples for ForEach compatibility
                    ForEach(Array(groupConversationsByDay(viewModel.conversations)), id: \.key) { day, conversations in
                        Section(header: Text(formatRelativeDate(day))) {
                            ForEach(conversations) { conversation in
                                Button(action: {
                                    if let index = viewModel.conversations.firstIndex(where: { $0.id == conversation.id }) {
                                        viewModel.selectConversation(at: index)
                                        viewModel.showConversationList = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text(conversation.title.isEmpty ? "New Conversation" : conversation.title)
                                                .font(.headline)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                            Text(formatTime(conversation.date))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .onDelete { indexSet in
                                viewModel.deleteConversation(at: indexSet)
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
    
    // Group conversations by day
    private func groupConversationsByDay(_ conversations: [Conversation]) -> [(key: Date, value: [Conversation])] {
        let sortedConversations = conversations.sorted(by: { $0.date > $1.date })
        let grouped = Dictionary(grouping: sortedConversations) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.sorted(by: { $0.key > $1.key }) // Ordered from newest to oldest
    }
    
    // Formatter to display relative or exact date
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
            return "\(daysAgo) days ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    // Formatter to display time in each conversation cell
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

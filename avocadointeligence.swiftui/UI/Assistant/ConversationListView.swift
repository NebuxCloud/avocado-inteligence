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
                            ForEach(groupedConversations[date]?.sorted(by: { $0.date > $1.date }) ?? []) { conversation in
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
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .contentShape(Rectangle())
                            }
                            .onDelete { indexSet in
                                deleteConversations(at: indexSet, date: date)
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
    
    // Agrupar conversaciones por fecha
    private var groupedConversations: [Date: [Conversation]] {
        Dictionary(grouping: viewModel.conversations, by: { Calendar.current.startOfDay(for: $0.date) })
    }
    
    private func deleteConversations(at indexSet: IndexSet, date: Date) {
        let idsToDelete = indexSet.compactMap { index in
            groupedConversations[date]?[index].id
        }
        
        viewModel.conversations.removeAll { conversation in
            idsToDelete.contains(conversation.id)
        }
        
        viewModel.saveConversations()
    }
    
    // Formatear la fecha para los encabezados de las secciones
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Formatear la hora para cada celda de conversación
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

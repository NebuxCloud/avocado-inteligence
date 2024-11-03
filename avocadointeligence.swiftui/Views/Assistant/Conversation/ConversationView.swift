import SwiftUI

struct ConversationView: View {
    @ObservedObject var conversation: Conversation
    @State private var isKeyboardVisible = false
    @Binding var refreshTrigger: Bool
    var setScrollToEndAction: ((@escaping () -> Void) -> Void)? // Callback to set scroll action

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(conversation.messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("EndOfConversation") // Marker for the end of the conversation
                }
                .padding()
                .onAppear {
                    // Set the scroll action callback when the view appears
                    setScrollToEndAction? {
                        scrollToEnd(proxy: proxy)
                    }
                    scrollToEnd(proxy: proxy)
                }
                .onChange(of: conversation.messages.count) { _ in
                    scrollToEnd(proxy: proxy)
                }
                .onChange(of: refreshTrigger) { _ in
                    scrollToEnd(proxy: proxy)
                }
            }
        }
    }
    
    private func scrollToEnd(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo("EndOfConversation", anchor: .bottom)
            }
        }
    }
}

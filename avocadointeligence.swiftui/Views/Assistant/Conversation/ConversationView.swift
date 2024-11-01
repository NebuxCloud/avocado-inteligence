import SwiftUI

struct ConversationView: View {
    @ObservedObject var conversation: Conversation
    @State private var isKeyboardVisible = false // Rastrea el estado del teclado
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(conversation.messages) { message in
                        MessageView(message: message)
                            .id(message.id.hashValue ^ message.content.hashValue)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("EndOfConversation") 
                }
                .padding()
                .onChange(of: conversation.messages.count) { _ in
                    scrollToEnd(proxy: proxy)
                }
                .onAppear {
                    scrollToEnd(proxy: proxy)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    isKeyboardVisible = true
                    scrollToEnd(proxy: proxy)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    isKeyboardVisible = false
                }
            }
        }
    }
    
    private func scrollToEnd(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo("EndOfConversation", anchor: .bottom)
        }
    }
}

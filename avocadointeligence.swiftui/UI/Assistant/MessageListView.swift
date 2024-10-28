import SwiftUI
import Combine
import UIKit

struct MessageListView: View {
    let messages: [Message]
    var isLoading: Bool

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    ForEach(messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                    .id(messages.count)
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Thinking...")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("scrollAnchor")
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: messages) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isLoading) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("scrollAnchor", anchor: .bottom)
            }
        }
    }
}

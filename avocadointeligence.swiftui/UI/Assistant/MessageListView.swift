import SwiftUI
import Combine
import UIKit

struct MessageListView: View {
    let messages: [Message]
    var isLoading: Bool

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack {
                    ForEach(messages.indices, id: \.self) { index in
                        MessageView(
                            message: messages[index],
                            isLoading: isLoading && index == messages.count - 1
                        )
                        .id(messages[index].id)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("scrollAnchor")
    
                }
                .padding(.horizontal)
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

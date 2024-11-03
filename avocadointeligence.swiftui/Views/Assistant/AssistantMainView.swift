import SwiftUI

struct AssistantView: View {
    @Binding var isMenuVisible: Bool
    @Binding var menuContent: AnyView?
    @State private var conversations: Conversations?
    @State private var selectedConversation: Conversation?
    @State private var isLoading = true
    @State private var newMessageText: String = "" // State for new message
    @State private var isGeneratingMessage: Bool = false
    @EnvironmentObject var llamaState: LlamaState
    @State private var refreshTrigger = false
    @State private var scrollToEndAction: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView(NSLocalizedString("loading_conversations", comment: "Loading conversations indicator"))
                        .padding()
                        .onAppear {
                            loadConversations()
                        }
                } else {
                    if let conversation = selectedConversation {
                        ConversationView(conversation: conversation,
                                         refreshTrigger: $refreshTrigger,
                                         setScrollToEndAction: { action in
                            self.scrollToEndAction = action // Set the scroll action
                        })
                        
                        HStack(alignment: .bottom) {
                            CustomTextField(input: $newMessageText, isLoading: $isGeneratingMessage, send: sendMessage, stopLoading: stopMessage)
                        }
                        .padding(.horizontal)
                        .background(Color(UIColor.systemGray6))
                    } else {
                        Text(NSLocalizedString("select_or_create_conversation", comment: "Prompt to select or create a conversation"))
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
            }
            .id(refreshTrigger)
            .navigationBarTitle(selectedConversation?.title ?? NSLocalizedString("assistant_title", comment: "Title of the assistant view"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: openMenu) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                },
                trailing: Button(action: {
                    addNewConversation()
                }) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
                .disabled(conversations?.conversations.isEmpty == false && selectedConversation?.messages.isEmpty == true)
            )
            .contentShape(Rectangle()) // Makes the content area tappable
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear{
                menuContent = AnyView(
                    AssistantMenuContent(
                        selectedConversation: $selectedConversation,
                        conversations: $conversations,
                        refreshTrigger: $refreshTrigger
                    )
                )
            }
        }
    }

    
    private func refreshView() {
        refreshTrigger.toggle()
    }

    private func loadConversations() {
        DispatchQueue.main.async {
            self.conversations = Conversations()
            self.conversations?.loadFromUserDefaults()
            if let lastConversation = self.conversations?.conversations.last {
                self.selectedConversation = lastConversation
            } else {
                self.addNewConversation() // Create a new conversation if none exist
            }
            self.isLoading = false
        }
    }
    
    private func addNewConversation() {
        conversations?.addEmptyConversation()
        selectedConversation = conversations?.conversations.last
    }
    
    private func openMenu() {
        if let conversations = conversations {
            isMenuVisible = true
        }
    }
    
    private func sendMessage() {
        isGeneratingMessage = true
        selectedConversation?.addMessage(content: newMessageText, role: .user)
        
        let chatCompletion = LlamaChatCompletion(llamaState: llamaState)
        
        let assistantMsg = ChatMessage(content: "", role: .assistant)
        assistantMsg.isLoading = true
        
        // Append assistantMsg once
        selectedConversation?.appendMessage(assistantMsg)
        newMessageText = ""
        
        Task { @MainActor in
            await chatCompletion.chatCompletion(
                messages: selectedConversation?.messages ?? [],
                resultHandler: { token in
                    // Append tokens directly to assistantMsg's content
                    assistantMsg.content += token
                    scrollToEndAction?()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                onComplete: {
                    Task {
                        if var userMessages = selectedConversation?.messages, userMessages.count == 2 {
                            let systemMessage = ChatMessage(content: "Generate a title for this conversation in the same language as the user.", role: .system)
                            userMessages.append(systemMessage)
                            selectedConversation?.title = "" // Clear the title
                            
                            await chatCompletion.chatCompletion(
                                messages: userMessages,
                                resultHandler: { token in
                                    selectedConversation?.title += token
                                },
                                onComplete: {
                                    self.refreshView()
                                }
                            )
                        }
                        assistantMsg.isLoading = false
                        isGeneratingMessage = false
                        conversations?.saveToUserDefaults()
                    }
                }
            )
        }
    }
    
    private func stopMessage() {
        Task { @MainActor in
            await llamaState.stop()
            isGeneratingMessage = false
        }
    }
}

// Extension to hide the keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

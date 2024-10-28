import SwiftUI
import Combine

struct AssistantView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    @Binding var isMenuVisible: Bool
    private let textFieldHeight: CGFloat = 40

    init(isMenuVisible: Binding<Bool>, llamaState: LlamaState) {
        _isMenuVisible = isMenuVisible
        _viewModel = StateObject(wrappedValue: ChatViewModel(llamaState: llamaState, isMenuVisible: isMenuVisible))
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                VStack {
                    conversationView

                    Divider()

                    inputFieldWithButton

                    Spacer()
                }
                .navigationTitle(viewModel.selectedConversation?.title ?? "Assistant")
                .id(viewModel.selectedConversation?.title)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation { isMenuVisible.toggle() }
                        }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { viewModel.startNewConversation() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .onAppear {
                    handleOnAppear()
                }
                .offset(x: isMenuVisible ? UIScreen.main.bounds.width * 0.75 : 0)
                .disabled(isMenuVisible)
                .onTapGesture {
                    dismissKeyboard()
                } // Cierra el teclado al hacer tap fuera del campo de texto
            }
            .navigationViewStyle(StackNavigationViewStyle())

            if isMenuVisible {
                menuOverlay
            }

            if isMenuVisible {
                sideMenu
            }
        }
        .animation(.easeInOut, value: isMenuVisible)
    }
    
    // MARK: - Subviews

    private var conversationView: some View {
        Group {
            if let selectedConversation = viewModel.selectedConversation {
                MessageListView(messages: selectedConversation.messages, isLoading: viewModel.isLoading)
            } else {
                Text("No conversation selected")
                    .foregroundColor(.gray)
            }
        }
    }

    private var inputFieldWithButton: some View {
        HStack {
            TextField("Type your message...", text: $viewModel.userInput)
                .font(.body)
                .padding(.leading, 12)
                .padding(.vertical, 8)
                .background(Color.clear)
                .focused($isTextFieldFocused)
                .onTapGesture {
                    isTextFieldFocused = true
                }
            
            Button(action: {
                handleSendOrStop()
            }) {
                Image(systemName: viewModel.isLoading ? "stop.fill" : "paperplane.fill")
                    .foregroundColor(viewModel.isLoading ? .red : (viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue))
            }
            .padding(10)
            .background(Color.clear)
            .clipShape(Circle())
        }
        .padding(.horizontal, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }


    private var menuOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation { isMenuVisible = false }
                dismissKeyboard()
            }
            .zIndex(1)
    }

    private var sideMenu: some View {
        ConversationListView(viewModel: viewModel)
            .frame(width: UIScreen.main.bounds.width * 0.75)
            .background(Color(UIColor.systemBackground))
            .transition(.move(edge: .leading))
            .zIndex(2)
    }

    // MARK: - Helper Methods

    private func handleOnAppear() {
        if viewModel.conversations.isEmpty {
            viewModel.startNewConversation()
        } else if viewModel.selectedConversation == nil {
            viewModel.selectConversation(at: viewModel.conversations.count - 1)
        }
    }

    private func handleSendOrStop() {
        if viewModel.isLoading {
            Task {
                await viewModel.stopConversation()
            }
        } else if !viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                await viewModel.sendMessage()
                viewModel.userInput = ""
                dismissKeyboard()
            }
        }
    }

    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
}

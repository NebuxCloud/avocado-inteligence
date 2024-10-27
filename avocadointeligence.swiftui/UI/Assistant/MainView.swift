import SwiftUI
import Combine
import UIKit

struct AssistantView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var offset: CGFloat = -UIScreen.main.bounds.width * 0.75 // Initially hidden
    private let menuWidth = UIScreen.main.bounds.width * 0.75

    init(llamaState: LlamaState) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(llamaState: llamaState))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main content and overlay
                ZStack {
                    // Conversation screen, shifted by the menu offset
                    NavigationStack {
                        VStack {
                            // Main conversation display
                            MessageListView(messages: viewModel.selectedConversation?.messages ?? [], isLoading: viewModel.isLoading)
                            
                            Divider()
                            
                            HStack(spacing: 12) {
                                TextField("Type your message...", text: $viewModel.userInput)
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(25)
                                    .focused($isTextFieldFocused)
                                    .onTapGesture {
                                        isTextFieldFocused = true
                                    }
                                
                                if viewModel.isLoading {
                                    Button(action: {
                                        viewModel.stop()
                                    }) {
                                        Image(systemName: "stop.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                            .padding(10)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                            .frame(width: 40, height: 40)
                                    }
                                } else {
                                    Button(action: {
                                        Task {
                                            await viewModel.sendMessage()
                                        }
                                    }) {
                                        Image(systemName: "paperplane.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                            .padding(10)
                                            .background(viewModel.isLoading || viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                            .frame(width: 40, height: 40)
                                    }
                                    .disabled(viewModel.isLoading || viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        }
                        .navigationTitle(viewModel.selectedConversation?.title ?? "Assistant")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    toggleMenu()
                                }) {
                                    Image(systemName: "list.bullet")
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: { viewModel.startNewConversation() }) {
                                    Image(systemName: "plus")
                                }
                                .disabled(viewModel.selectedConversation?.messages.isEmpty ?? true)
                            }
                        }
                        .onAppear {
                            selectOrCreateConversation()
                        }
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .offset(x: offset + menuWidth) // Shifts the conversation screen
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.width > 0 {
                                        offset = max(-menuWidth + value.translation.width, 0)
                                    } else if value.translation.width < 0 && offset == 0 {
                                        offset = min(0 + value.translation.width, -menuWidth)
                                    }
                                }
                                .onEnded { _ in
                                    if offset > -menuWidth / 2 {
                                        showMenu()
                                    } else {
                                        hideMenu()
                                    }
                                }
                        )
                        .disabled(offset == 0) // Only disables main content when menu is open
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    
                    // Semi-transparent overlay when the menu is open
                    if offset == 0 {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                hideMenu()
                            }
                    }
                }
                
                // Conversation menu view, shown over the overlay
                ConversationListView(viewModel: viewModel)
                    .frame(width: menuWidth)
                    .offset(x: offset) // Controls menu position with offset
                    .transition(.move(edge: .leading))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: offset == 0 ? 5 : 0, y: 0)
                    .zIndex(10)
            }
        }
    }

    private func toggleMenu() {
        if offset == 0 {
            hideMenu()
        } else {
            showMenu()
        }
    }

    private func showMenu() {
        withAnimation {
            offset = 0
        }
    }

    private func hideMenu() {
        withAnimation {
            offset = -menuWidth
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Selects the last conversation if none is selected, or starts a new one if no conversations exist
    private func selectOrCreateConversation() {
        if viewModel.conversations.isEmpty {
            // No conversations exist, so create a new one
            viewModel.startNewConversation()
        } else if viewModel.selectedConversation == nil {
            // Select the last conversation if none is selected
            viewModel.selectConversation(at: viewModel.conversations.count - 1)
        }
    }
}

import SwiftUI
import Combine
import UIKit

class Message: Identifiable, ObservableObject {
    let id = UUID()
    @Published var text: String
    let role: Role

    init(text: String, role: Role) {
        self.text = text
        self.role = role
    }

    enum Role: String {
        case user
        case assistant
        case system
    }
}


@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [
        .init(text: "You are a helpful assistant", role: .system)
    ]
    @Published var isLoading: Bool = false
    @Published var userInput: String = ""
    @Published var stopGeneration: Bool = false // Added to stop generation

    private var llamaState: LlamaState
    private var chatCompletion: LlamaChatCompletion
    private let languageTranslation: String
    
    init(llamaState: LlamaState, languageTranslation: String = "English") {
        self.llamaState = llamaState
        self.languageTranslation = languageTranslation
        self.chatCompletion = LlamaChatCompletion(llamaState: llamaState)
    }
    
    func sendMessage() async {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        // Add user message
        let userMessage = Message(text: input, role: .user)
        messages.append(userMessage)
        userInput = ""
        isLoading = true
        stopGeneration = false // Reset stopGeneration
        
        // Create chat messages array for chatCompletion
        let chatMessages = messages.map { message in
            ChatMessage(
                content: message.text,
                role: message.role == .user ? .user :
                      message.role == .assistant ? .assistant :
                      .system
            )
        }
        // Add assistant message as a placeholder
        let assistantMessage = Message(text: "", role: .assistant)
        messages.append(assistantMessage)
        
        do {
            var assistantText = ""
            
            // Call chatCompletion's chatCompletion method
            try await chatCompletion.chatCompletion(
                messages: chatMessages,
                resultHandler: { [weak self] newResult in
                    guard let self = self else { return }
                    
                    // Check if stopGeneration is true
                    if self.stopGeneration {
                        self.isLoading = false
                        return
                    }
                    
                    assistantText += newResult
                    Task { @MainActor in
                        if let index = self.messages.lastIndex(where: { $0.role == .assistant }) {
                            self.messages[index].text += newResult
                        }
                    }
                },
                onComplete: { [weak self] in
                    // End loading once completed
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.isLoading = false
                    }
                }
            )
        } catch {
            let errorMessage = Message(text: "An error occurred: \(error.localizedDescription)", role: .assistant)
            messages.append(errorMessage)
            isLoading = false
        }
    }
    
    // Method to stop ongoing generation if needed
    func stop() {
        stopGeneration = true
    }
    
    // Clears all messages
    func clearMessages() {
        messages.removeAll()
    }
}

struct MessageView: View {
    @ObservedObject var message: Message
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack {
            if message.role == .assistant {
                // Assistant message styling
                VStack(alignment: .leading) {
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let attributedString = try? AttributedString(
                        markdown: message.text,
                        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    ) {
                        Text(attributedString)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .textSelection(.enabled)
                            .onChange(of: message.text) { newValue in
                                feedbackGenerator.impactOccurred()
                            }
                    } else {
                        Text(message.text)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .textSelection(.enabled)
                            .onChange(of: message.text) { newValue in
                                feedbackGenerator.impactOccurred()
                            }
                    }
                }
                Spacer()
            } else if message.role == .user {
                // User message styling
                Spacer()
                VStack(alignment: .trailing) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(15)
                }
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct AssistantView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    init(llamaState: LlamaState) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(llamaState: llamaState))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack {
                            ForEach(viewModel.messages) { message in
                                MessageView(message: message)
                            }
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
                                // Scroll to the last message automatically
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
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
            .navigationTitle("Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.clearMessages()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    // Hide keyboard helper function
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

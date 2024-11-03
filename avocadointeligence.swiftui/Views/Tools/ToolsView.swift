import SwiftUI
import UIKit

struct ToolsView: View {
    @State private var inputText: String = ""
    @State private var transformedText: String = ""
    @State private var showToolSelector: Bool = false
    @State private var isLoading: Bool = false
    @State private var showCopiedAlert: Bool = false
    @Binding var isMenuVisible: Bool
    @Binding var menuContent: AnyView?
    @EnvironmentObject var llamaState: LlamaState
    @EnvironmentObject var sharedData: SharedData
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    
    @State private var selectedTool: WriteTool?
    private var sharedDataCombined: String {
        "\(sharedData.text)-\(sharedData.tool)"
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack {
                Spacer()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack {
                            if !transformedText.isEmpty {
                                MessageView(message: ChatMessage(content: transformedText, role: .assistant, isLoading: isLoading), hideHeader: true)
                                    .padding(.horizontal)
                            }
                        }
                        .id("Bottom") // Identifier for scrolling to the bottom
                    }
                    .onChange(of: transformedText) { _ in
                        // Scroll to bottom when transformedText changes
                        withAnimation {
                            proxy.scrollTo("Bottom", anchor: .bottom)
                        }
                    }
                }
                
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation {
                            showToolSelector.toggle()
                        }
                        if showToolSelector {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedTool?.icon ?? "square.grid.2x2")
                            Text(selectedTool?.caption ?? NSLocalizedString("tool_select_style", comment: "Default tool selector text"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(selectedTool?.color ?? Color.gray)
                        .cornerRadius(16)
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    CustomTextField(input: $inputText, isLoading: $isLoading, send: {
                        Task {
                            await applyTransformation()
                        }
                    }, stopLoading: {
                        Task {
                            await llamaState.stop()
                            isLoading = false
                        }
                    })
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                .background(Color(UIColor.systemGray6))
            }
            .blur(radius: showToolSelector ? 5 : 0)

            if showToolSelector {
                BlurView(style: .dark)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showToolSelector = false
                        }
                    }
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(writeTools, id: \.caption) { tool in
                            Button(action: {
                                selectedTool = tool
                                showToolSelector = false
                            }) {
                                HStack {
                                    Image(systemName: tool.icon)
                                    Text(tool.caption)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(tool.color)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
                .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4)
                .position(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height - keyboardResponder.currentHeight) / 2)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3))
            }
        }
        .onAppear {
            inputText = sharedData.text
            if let tool = writeTools.first(where: { $0.caption == sharedData.tool }) {
                selectedTool = tool
            }
        }
        .onAppear {
            resetStateWithSharedData()
        }
        .onChange(of: sharedDataCombined) { _ in
            resetStateWithSharedData()
            Task {
                triggerAutomaticTransformation()
            }
        }
        .overlay(
            VStack {
                Spacer()
                if showCopiedAlert {
                    Text(NSLocalizedString("copied_alert", comment: "Alert when text is copied"))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedAlert = false
                                }
                            }
                        }
                }
            }
        )
    }
    
    private func resetStateWithSharedData() {
        inputText = sharedData.text
        transformedText = ""
        isLoading = false
        showToolSelector = false
        if let tool = writeTools.first(where: { $0.caption == sharedData.tool }) {
            selectedTool = tool
        }
    }
    
    private func triggerAutomaticTransformation() {
         Task {
             isLoading = true
             await applyTransformation()
             isLoading = false
         }
     }
    
    private func applyTransformation() async {
        guard let tool = selectedTool else { return }
        
        isLoading = true
        transformedText = ""
        var tmpUserInput = inputText

        if let url = URL(string: inputText), UIApplication.shared.canOpenURL(url) {
            tmpUserInput = await downloadHTML(from: url)
        }

        if tmpUserInput.count > 8192 {
            tmpUserInput = String(tmpUserInput.prefix(8192))
        }

        let chatCompletion = LlamaChatCompletion(llamaState: llamaState)
        let assistantMsg = ChatMessage(content: "", role: .assistant)
        assistantMsg.isLoading = true

        var conversationMessages = [
            ChatMessage(content: tool.systemPrompt, role: .system),
            ChatMessage(content: tmpUserInput, role: .user),
        ]
        conversationMessages.append(assistantMsg)

        await chatCompletion.chatCompletion(
            messages: conversationMessages,
            resultHandler: { token in
                if let assistantIndex = conversationMessages.firstIndex(where: { $0.id == assistantMsg.id }) {
                    conversationMessages.remove(at: assistantIndex)
                    assistantMsg.content += token
                    transformedText = assistantMsg.content
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    assistantMsg.isLoading = true
                    conversationMessages.insert(assistantMsg, at: assistantIndex)
                }
            },
            onComplete: {
                transformedText = assistantMsg.content
                isLoading = false
                assistantMsg.isLoading = false
            }
        )
    }
    
      func htmlToPlainText(_ html: String) -> String {
            guard let data = html.data(using: .utf8) else {
                print("Error: Could not convert HTML to UTF-8 data.")
                return ""
            }

            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            do {
                let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
                let plainText = attributedString.string

                let normalizedText = plainText
                    .replacingOccurrences(of: "\r\n", with: "\n")
                    .replacingOccurrences(of: "\r", with: "\n")

                let paragraphSeparator = "\n\n"
                let paragraphs = normalizedText.components(separatedBy: paragraphSeparator)

                let filteredParagraphs = paragraphs.filter { paragraph in
                    let wordCount = countWords(in: paragraph)
                    return wordCount > 20
                }

                return filteredParagraphs.joined(separator: "\n\n")

            } catch {
                print("Error processing HTML: \(error.localizedDescription)")
                return "Error processing HTML."
            }
        }
       
       func downloadHTML(from url: URL) async -> String {
           do {
               let (data, _) = try await URLSession.shared.data(from: url)
               if let htmlString = String(data: data, encoding: .utf8) {
                   return htmlToPlainText(htmlString)
               } else {
                   return "Error converting HTML to text."
               }
           } catch {
               return "Error downloading HTML: \(error.localizedDescription)"
           }
       }
      
      func countWords(in text: String) -> Int {
          let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
              .filter { !$0.isEmpty }
          return words.count
      }
    private func copyTransformedText() {
        UIPasteboard.general.string = transformedText
        showCopiedAlert = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

import SwiftUI
import Combine
import UIKit
import Splash

struct MessageView: View {
    @ObservedObject var message: Message
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var isPressed = false

    var body: some View {
        HStack {
            if message.role == .assistant {
                // Style for assistant messages
                VStack(alignment: .leading) {
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    let attributedString = attributedStringFromMessageText(message.text)
                    Text(attributedString)
                        .padding()
                        .background(
                            Color.gray.opacity(0.1)
                                .cornerRadius(15)
                        )
                        .scaleEffect(isPressed ? 1.05 : 1.0) // Scale effect for feedback
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.3), value: isPressed) // Spring animation
                        .textSelection(.enabled)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                        .onLongPressGesture(
                            minimumDuration: 0.1,
                            pressing: { pressing in
                                withAnimation {
                                    isPressed = pressing
                                    if pressing {
                                        feedbackGenerator.impactOccurred()
                                    }
                                }
                            },
                            perform: {}
                        )
                        .onChange(of: message.text) { newValue in
                            feedbackGenerator.impactOccurred()
                        }
                }
                Spacer()
            } else if message.role == .user {
                // Style for user messages
                Spacer()
                VStack(alignment: .trailing) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding()
                        .background(
                            Color.blue.opacity(0.2)
                                .cornerRadius(15)
                        )
                        .scaleEffect(isPressed ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.3), value: isPressed)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                        .onLongPressGesture(
                            minimumDuration: 0.1,
                            pressing: { pressing in
                                withAnimation {
                                    isPressed = pressing
                                    if pressing {
                                        feedbackGenerator.impactOccurred()
                                    }
                                }
                            },
                            perform: {}
                        )
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

func attributedStringFromMessageText(_ text: String) -> AttributedString {
    var attributedString = AttributedString()
    
    // Regular expression to detect code blocks in markdown
    let regexPattern = "(?s)```(\\w+)?\\n(.*?)```"
    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
    let nsText = text as NSString
    var lastIndex = 0
    
    let matches = regex.matches(in: text, options: [], range: NSMakeRange(0, nsText.length))
    
    if matches.isEmpty {
        // No code blocks, parse as regular markdown
        if let parsedAttributedString = try? AttributedString(markdown: text) {
            attributedString += parsedAttributedString
        } else {
            attributedString += AttributedString(text)
        }
    } else {
        // Process each segment of text and code
        for match in matches {
            let rangeBefore = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            let textBefore = nsText.substring(with: rangeBefore)
            if let parsedTextBefore = try? AttributedString(markdown: textBefore) {
                attributedString += parsedTextBefore
            } else {
                attributedString += AttributedString(textBefore)
            }
            
            // Extract optional language identifier
            let langRange = match.range(at: 1)
            var language: String?
            if langRange.location != NSNotFound {
                language = nsText.substring(with: langRange)
            }
            
            // Content of the code block
            let codeRange = match.range(at: 2)
            let codeContent = nsText.substring(with: codeRange)
            
            // Apply syntax highlighting with Splash
            let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: .sundellsColors(withFont: .init(size: 13))))
            let highlightedCodeNS = highlighter.highlight(codeContent)
            
            // Convert NSAttributedString to AttributedString
            if let highlightedCode = try? AttributedString(highlightedCodeNS) {
                attributedString += "\n\n" + highlightedCode + "\n\n"
            } else {
                // If conversion fails, add unformatted code
                attributedString += AttributedString(codeContent)
            }
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Add remaining text after the last code block
        if lastIndex < nsText.length {
            let rangeAfter = NSRange(location: lastIndex, length: nsText.length - lastIndex)
            let textAfter = nsText.substring(with: rangeAfter)
            if let parsedTextAfter = try? AttributedString(markdown: textAfter) {
                attributedString += parsedTextAfter
            } else {
                attributedString += AttributedString(textAfter)
            }
        }
    }
    
    return attributedString
}

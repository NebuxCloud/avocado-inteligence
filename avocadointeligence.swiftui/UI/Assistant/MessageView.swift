import SwiftUI
import Combine
import UIKit
import Splash

struct MessageView: View {
    @ObservedObject var message: Message
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var isLoading: Bool
    @State private var isPressed = false

    var body: some View {
        HStack {
            if message.role == .assistant {
                VStack(alignment: .leading) {
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    let attributedString = attributedStringFromMessageText(message.text)
                    
                    ZStack(alignment: .bottomTrailing) {
                        Text(attributedString)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .background(
                                Color.gray.opacity(0.1)
                                    .cornerRadius(15)
                            )
                            .scaleEffect(isPressed ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.3), value: isPressed)
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
                        
                        if isLoading {
                            LoadingDotsView()
                                .padding([.bottom, .trailing], 10)
                        }
                    }
                }
                Spacer()
                
            } else if message.role == .user {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
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
    
    // Expresión regular para detectar bloques de código en Markdown
    let regexPattern = "(?s)```(\\w+)?\\n(.*?)```"
    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
    let nsText = text as NSString
    var lastIndex = 0
    
    let matches = regex.matches(in: text, options: [], range: NSMakeRange(0, nsText.length))
    
    if matches.isEmpty {
        // Sin bloques de código, parseamos como Markdown normal
        if let parsedAttributedString = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            attributedString += parsedAttributedString
        } else {
            attributedString += AttributedString(text)
        }
    } else {
        // Procesamos cada segmento de texto y código
        for match in matches {
            let rangeBefore = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            let textBefore = nsText.substring(with: rangeBefore)
            if let parsedTextBefore = try? AttributedString(markdown: textBefore, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                attributedString += parsedTextBefore
            } else {
                attributedString += AttributedString(textBefore)
            }
            
            // Extraemos el identificador de lenguaje opcional
            let langRange = match.range(at: 1)
            var language: String?
            if langRange.location != NSNotFound {
                language = nsText.substring(with: langRange)
            }
            
            // Contenido del bloque de código
            let codeRange = match.range(at: 2)
            let codeContent = nsText.substring(with: codeRange)
            
            // Aplicamos resaltado de sintaxis con Splash
            let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: .sundellsColors(withFont: .init(size: 13))))
            let highlightedCodeNS = highlighter.highlight(codeContent)
            let highlightedCode = try? AttributedString(highlightedCodeNS)
            attributedString += "\n\n" + (highlightedCode ?? AttributedString(codeContent)) + "\n\n"
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Añadimos el texto restante después del último bloque de código
        if lastIndex < nsText.length {
            let rangeAfter = NSRange(location: lastIndex, length: nsText.length - lastIndex)
            let textAfter = nsText.substring(with: rangeAfter)
            if let parsedTextAfter = try? AttributedString(markdown: textAfter, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                attributedString += parsedTextAfter
            } else {
                attributedString += AttributedString(textAfter)
            }
        }
    }
    
    return attributedString
}

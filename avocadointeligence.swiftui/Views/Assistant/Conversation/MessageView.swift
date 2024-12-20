import SwiftUI
import Splash

struct MessageView: View {
    let message: ChatMessage
    var hideHeader: Bool = false

    @State private var showCopiedAlert = false
    @State private var ellipsis = ""
    
    var isUserMessage: Bool {
        message.role == .user
    }
    
    var roleTitle: String {
        isUserMessage ? NSLocalizedString("user_role", comment: "User role title") : NSLocalizedString("assistant_role", comment: "Assistant role title")
    }
    
    var body: some View {
        HStack {
            if isUserMessage {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if !hideHeader {
                    HStack {
                        Text(roleTitle)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Text(message.date, formatter: dateFormatter) // Display date and time
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 2)
                }
                // Display the message content with animated ellipsis if loading
                if let highlightedContent = processMarkdownWithCode(for: message.content + (message.isLoading ? ellipsis : "")) {
                    Text(highlightedContent)
                        .padding(16)
                        .foregroundColor(isUserMessage ? .white : .primary)
                        .background(isUserMessage ? Color.green : Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        .contextMenu {
                            Button(action: copyMessage) {
                                Label(NSLocalizedString("copy_message", comment: "Copy message action"), systemImage: "doc.on.doc")
                            }
                        }
                        .onAppear {
                            if message.isLoading {
                                startEllipsisAnimation()
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: highlightedContent) // Apply easeInOut animation
                }
            }
            .frame(maxWidth: isUserMessage ? 300 : .infinity, alignment: isUserMessage ? .trailing : .leading)
            
            if !isUserMessage {
                Spacer()
            }
        }
        .padding(isUserMessage ? .leading : .trailing, isUserMessage ? 50 : 0)
        .padding(.vertical, 3)
        .overlay(
            Text(NSLocalizedString("copied_alert", comment: "Alert when message is copied"))
                .font(.footnote)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .opacity(showCopiedAlert ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showCopiedAlert)
                .offset(y: -40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedAlert = false
                    }
                }
                .padding(.top, 8),
            alignment: .top
        )
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
        showCopiedAlert = true
    }
    
    private func startEllipsisAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if ellipsis.count >= 3 {
                        ellipsis = ""
                    } else {
                        ellipsis += "."
                    }
                }
            }
        }
    }
    
    private func processMarkdownWithCode(for content: String) -> AttributedString? {
        let theme = Theme.sunset(withFont: Splash.Font(size: 16))
        let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
        
        var attributedString = AttributedString()
        
        let components = content.components(separatedBy: "```")
        
        for (index, component) in components.enumerated() {
            if index % 2 == 0 {
                if let attributedText = try? AttributedString(markdown: component, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                    attributedString.append(attributedText)
                }
            } else {
                let highlightedCode = highlighter.highlight(component)
                if let attributedCode = try? AttributedString(highlightedCode) {
                    attributedString.append(attributedCode)
                }
            }
        }
        
        return attributedString
    }
    
    // Custom date formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

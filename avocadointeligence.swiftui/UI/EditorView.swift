import SwiftUI
import NaturalLanguage
import UIKit
struct EditorView: View {
    @State private var userInput: String = ""
    @State private var result: String = ""
    @State private var isKeyboardVisible: Bool = false
    @State private var showRewrittenText: Bool = false
    @State private var isGenerating: Bool = false
    @State private var stopGeneration: Bool = false
    @State private var selectedStyle: String = "rewrite"

    @ObservedObject var llamaState: LlamaState
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Binding var isLoading: Bool

    let textStyles = ["rewrite", "proofread", "professional", "romantic", "summary", "friendly", "keypoints"]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color(UIColor.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            hideKeyboard()
                        }
                    
                    VStack {
                        if showRewrittenText && !isKeyboardVisible {
                            RewrittenTextView(geometry: geometry)
                        }
                        
                        Spacer()
                        
                        InputSection()
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .onAppear {
                observeKeyboard()
                feedbackGenerator.prepare()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
            .navigationTitle("Text Editor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        userInput = ""
                        result = ""
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    

    @ViewBuilder
    private func RewrittenTextView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollView in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {

                    if let attributedString = try? AttributedString(
                        markdown: result,
                        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    ) {
                        Text(attributedString)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .font(.body)
                            .cornerRadius(15)
                            .textSelection(.enabled)
                            .onChange(of: result) { newValue in
                                feedbackGenerator.impactOccurred()
                            }
                    } else {
                        Text(result)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .font(.body)
                            .cornerRadius(15)
                            .textSelection(.enabled)
                            .onChange(of: result) { newValue in
                                feedbackGenerator.impactOccurred()
                            }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding()
            }
            .frame(maxHeight: geometry.size.height * 0.7)
            .onChange(of: result) { _ in
                withAnimation(.easeInOut) {
                    scrollView.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .transition(.move(edge: .top))
        .animation(.easeInOut, value: result)
    }

    @ViewBuilder
    private func InputSection() -> some View {
        VStack {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 150)

                TextEditor(text: $userInput)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .font(.body)

                if userInput.isEmpty {
                    Text("Introduce some text here, or URL to be processed")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .font(.body)

                }
            }
            .padding()

            if !isKeyboardVisible {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(textStyles, id: \.self) { style in
                            Button(action: {
                                selectedStyle = style
                            }) {
                                VStack {
                                    Image(systemName: getIconForStyle(style))
                                        .foregroundColor(selectedStyle == style ? .white : .primary)
                                    Text(style.capitalized)
                                        .foregroundColor(selectedStyle == style ? .white : .primary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedStyle == style ? getColorForStyle(style) : Color.secondary.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                HStack {
                    if isGenerating {
                        Button(action: {
                            stopGeneration = true
                        }) {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 5)
                                Text("Stop")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            rewriteText(style: selectedStyle)  // Ahora la acción solo se ejecuta aquí
                        }) {
                            Label("Execute", systemImage: "play.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isGenerating ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    func getIconForStyle(_ style: String) -> String {
        switch style {
        case "rewrite": return "pencil.circle.fill"
        case "proofread": return "checkmark.circle.fill"
        case "professional": return "briefcase.fill"
        case "romantic": return "heart.fill"
        case "summary": return "doc.text.fill"
        case "friendly": return "hand.thumbsup.fill"
        case "keypoints": return "list.bullet"
        default: return "pencil.circle"
        }
    }

    func getColorForStyle(_ style: String) -> Color {
        switch style {
        case "rewrite": return Color.green
        case "proofread": return Color.orange
        case "professional": return Color.blue
        case "romantic": return Color.pink
        case "summary": return Color.purple
        case "friendly": return Color.yellow
        case "keypoints": return Color.teal
        default: return Color.gray
        }
    }

    func rewriteText(style: String) {
        Task {
            withAnimation {
                showRewrittenText = true
                isGenerating = true
                stopGeneration = false
            }

            var tmpUserInput = self.userInput
            if let url = URL(string: self.userInput), UIApplication.shared.canOpenURL(url) {
                let htmlContent = await downloadHTML(from: url)
                tmpUserInput = htmlContent
            }

            if tmpUserInput.count > 8192 {
                tmpUserInput = String(tmpUserInput.prefix(8192))
            }

            let languageCode = detectLanguage(for: tmpUserInput)
            let languageTranslation = getPrompt(for: style, languageCode: languageCode)

            result = ""
            
            let chatCompletiom = LlamaChatCompletion(
                llamaState: llamaState
            )
            
            await chatCompletiom.chatCompletion(messages: [
                ChatMessage(content: languageTranslation, role: .system),
                ChatMessage(content: userInput, role: .user)
            ], resultHandler: { newResult in
                DispatchQueue.main.async {
                    if stopGeneration {
                        isGenerating = false
                        return
                    }
                    result += newResult
                }
            }, onComplete: {
                DispatchQueue.main.async {
                    isGenerating = false
                }
            })
        }
    }

    func getPrompt(for style: String, languageCode: String) -> String {
        textEditPrompts[style]?[languageCode] ?? textEditPrompts[style]?["en"] ?? ""
    }

    func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? "und"
    }

    func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                          .filter { !$0.isEmpty }
        return words.count
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

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                withAnimation { isKeyboardVisible = true }
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                withAnimation { isKeyboardVisible = false }
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

        let textEditPrompts: [String: [String: String]] = [
            "professional": [
                "es": "Reescribe el siguiente texto para que suene profesional y pulido. Corrige cualquier error gramatical u ortográfico y utiliza un lenguaje formal adecuado. **No incluyas introducciones ni encabezados en tu respuesta.** Mantén el texto en el idioma original.",
                "en": "Rewrite the following text to sound professional and polished. Correct any grammatical or spelling errors and use appropriate formal language. **Do not include introductions or headings in your response.** Keep the text in the original language."
            ],
            "romantic": [
                "es": "Reescribe el siguiente texto para que transmita sentimientos románticos y apasionados. Utiliza un lenguaje emotivo y expresivo, y corrige cualquier error gramatical u ortográfico. **No incluyas introducciones ni encabezados en tu respuesta.** Mantén el texto en el idioma original.",
                "en": "Rewrite the following text to convey romantic and passionate feelings. Use emotive and expressive language, and correct any grammatical or spelling errors. **Do not include introductions or headings in your response.** Keep it in the original language."
            ],
            "summary": [
                "es": "Lee el siguiente texto y elabora un resumen conciso que capture los puntos principales. **Proporciona el resumen directamente sin encabezados.** Asegúrate de mantener el resumen en el idioma original.",
                "en": "Read the following text and produce a concise summary that captures the main points. **Provide the summary directly without headings.** Ensure that you keep the summary in the original language."
            ],
            "keypoints": [
                "es": "Lee el siguiente texto y extrae los puntos clave más importantes. **Presenta estos puntos en una lista sin introducciones ni encabezados**, manteniendo el idioma original.",
                "en": "Read the following text and extract the most important key points. **Present these points in a list without introductions or headings**, keeping the original language."
            ],
            "anything": [
                "es": "Lee el siguiente texto y proporciona una respuesta adecuada o comentarios relevantes. **Responde directamente sin introducir tu respuesta.** Asegúrate de mantener tu respuesta en el idioma original.",
                "en": "Read the following text and provide an appropriate response or relevant comments. **Respond directly without introducing your response.** Make sure to keep your response in the original language."
            ],
            "rewrite": [
                "es": "Reescribe el siguiente texto para mejorar su claridad y fluidez. Corrige cualquier error gramatical u ortográfico y utiliza frases bien estructuradas. **No incluyas introducciones ni encabezados en tu respuesta.** Mantén el texto en el idioma original.",
                "en": "Rewrite the following text to improve its clarity and fluency. Correct any grammatical or spelling errors and use well-structured sentences. **Do not include introductions or headings in your response.** Keep the text in the original language."
            ],
            "proofread": [
                "es": "Revisa y corrige el siguiente texto para mejorar su claridad y precisión. Corrige errores gramaticales, ortográficos y de puntuación, y mejora la estructura de las oraciones si es necesario. **Proporciona el texto corregido directamente sin introducciones.** Mantén el texto en el idioma original.",
                "en": "Proofread and correct the following text to improve its clarity and accuracy. Correct grammatical, spelling, and punctuation errors, and improve sentence structure if necessary. **Provide the corrected text directly without introductions.** Keep it in the original language."
            ],
            "friendly": [
                "es": "Reescribe el siguiente texto para que tenga un tono amigable y cercano. Utiliza un lenguaje informal y cálido, y corrige cualquier error gramatical u ortográfico. **No incluyas introducciones ni encabezados en tu respuesta.** Mantén el texto en el idioma original.",
                "en": "Rewrite the following text to have a friendly and approachable tone. Use informal and warm language, and correct any grammatical or spelling errors. **Do not include introductions or headings in your response.** Keep it in the original language."
            ]
    ]
}

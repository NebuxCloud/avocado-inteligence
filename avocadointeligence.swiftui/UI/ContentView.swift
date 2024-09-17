import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var result: String = ""
    @State private var isKeyboardVisible: Bool = false
    @State private var showRewrittenText: Bool = false
    @State private var isLoading: Bool = true
    @State private var isGenerating: Bool = false
    @StateObject var llamaState = LlamaState()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    LoadingView()
                } else {
                    MainView(geometry: geometry)
                }
            }
        }
        .onAppear {
            Task {
                await llamaState.loadDefault()
                isLoading = false
                
                let sharedDefaults = UserDefaults(suiteName: "group.josecarlosgarcia95.mike")
                if let sharedSummary = sharedDefaults?.string(forKey: "sharedSummary") {
                    self.userInput = sharedSummary
                }
                
            }
            observeKeyboard()
            

        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
                .padding()
            Text("Preparing AI...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.8))
    }

    @ViewBuilder
    private func MainView(geometry: GeometryProxy) -> some View {
        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.blue.opacity(0.2)]),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
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

    @ViewBuilder
    private func RewrittenTextView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollView in
            ScrollView {
                GlassButton(text: "Copy", icon: "doc.on.doc") {
                    UIPasteboard.general.string = result
                }
                Text(.init(result))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.25))
                    .font(.system(size: 17))
                    .cornerRadius(15)
                    .onChange(of: result) { _ in
                        withAnimation {
                            scrollView.scrollTo(result, anchor: .bottom)
                        }
                    }
            }
            .frame(maxHeight: geometry.size.height * 0.7)
        }
        .transition(.move(edge: .top))
        .animation(.easeInOut)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func InputSection() -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 150)

                TransparentTextEditor(text: $userInput)
                    .padding()
                    .frame(height: 150)
            }
            .padding()

            if !isKeyboardVisible {
                TextOptions()
            }
        }
    }

    @ViewBuilder
    private func TextOptions() -> some View {
        VStack {
            
            GlassButton(text: "Ask me anything", icon: "cpu", action: {
                rewriteText(style: "anything")
            }, isDisabled: isGenerating)
            
            HStack {
                GlassButton(text: "Rewrite", icon: "pencil", action: {
                    rewriteText(style: "rewrite")
                }, isDisabled: isGenerating)
                
                GlassButton(text: "Proofread", icon: "checkmark", action: {
                    rewriteText(style: "proofread")
                }, isDisabled: isGenerating)
            }

            HStack {
                GlassButton(text: "Professional", icon: "case", action: {
                    rewriteText(style: "professional")
                }, isDisabled: isGenerating)
                
                GlassButton(text: "Romantic", icon: "heart", action: {
                    rewriteText(style: "romantic")
                }, isDisabled: isGenerating)
            }

            GlassButton(text: "Summary", icon: "note.text", action: {
                rewriteText(style: "summary")
            }, isDisabled: isGenerating)
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

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

    func rewriteText(style: String) {
        Task {
            withAnimation {
                showRewrittenText = true
                isGenerating = true
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

            let prompt = """
            <|start_of_turn|>system
            \(languageTranslation)
            Input: \(tmpUserInput)
            <end_of_turn><start_of_turn>model
            """

            result = ""

            await llamaState.complete(text: prompt) { newResult in
                result += newResult
            }
            isGenerating = false
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

    func htmlToPlainText(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return "" }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            let plainText = attributedString.string
            let lines = plainText.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let paragraphs = lines.filter { !$0.isEmpty && $0.split(separator: " ").count > 1 }
            return paragraphs.joined(separator: "\n\n")
        } else {
            return "Error stripping HTML tags."
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Data

    let textEditPrompts: [String: [String: String]] = [
        "professional": [
            "es": "Reescribe el siguiente texto para que suene profesional y pulido, manteniéndolo en el idioma original...",
            "en": "Rewrite the following text to sound professional and polished, keeping it in the original language..."
        ],
        "romantic": [
            "es": "Reescribe el siguiente texto para que suene romántico y apasionado, pero mantenlo en el idioma original...",
            "en": "Rewrite the following text to sound romantic and passionate, but keep it in the original language..."
        ],
        "summary": [
            "es": "Resume el siguiente texto de manera concisa, manteniéndolo en el idioma original...",
            "en": "Summarize the following text concisely, while keeping it in the original language..."
        ],
        "anything": [
            "es": "Responde al siguiente texto como lo consideres adecuado, manteniéndolo en el idioma original...",
            "en": "Respond to the following text as you see fit, keeping it in the original language..."
        ],
        "rewrite": [
            "es": "Reescribe el siguiente texto de manera clara y fluida, manteniéndolo en el idioma original...",
            "en": "Rewrite the following text clearly and fluently, keeping it in the original language..."
        ],
        "proofread": [
            "es": "Revisa y corrige el siguiente texto para mejorar su claridad y corrección, manteniéndolo en el idioma original...",
            "en": "Proofread and correct the following text to improve clarity and accuracy, keeping it in the original language..."
        ]
    ]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

// Wrapper para un TextEditor completamente transparente
struct TransparentTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isOpaque = false
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TransparentTextEditor

        init(_ parent: TransparentTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

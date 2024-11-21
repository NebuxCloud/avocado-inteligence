import UIKit
import SwiftUI

class ShareViewController: UIViewController {
    private var sharedContent: String = ""
    private var selectedTool: WriteTool?
    @State private var isToolSelectionVisible: Bool = true  // Control visibility

    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveSharedContent()
        setupSwiftUIView()
        
        // Add tap gesture recognizer to detect taps outside the content view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissExtension))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func retrieveSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            if let attachments = item.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.url") {
                        loadContent(from: attachment, as: "public.url")
                    } else if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        loadContent(from: attachment, as: "public.text")
                    }
                }
            }
        }
    }
    
    private func loadContent(from attachment: NSItemProvider, as type: String) {
        attachment.loadItem(forTypeIdentifier: type, options: nil) { [weak self] (data, error) in
            guard let self = self else { return }
            if type == "public.url", let url = data as? URL {
                self.sharedContent = url.absoluteString
            } else if type == "public.text", let text = data as? String {
                self.sharedContent = text
            }
            DispatchQueue.main.async {
                self.setupSwiftUIView() // Show tool selection after loading content
            }
        }
    }
    
    private func setupSwiftUIView() {
        let toolSelectionView = ToolSelectionContainerView(
            isVisible: .constant(isToolSelectionVisible),
            tools: writeTools.filter { $0.shareable },
            onToolSelected: { [weak self] selectedTool in
                self?.selectedTool = selectedTool
                self?.openMainApp()
            },
            onCancel: { [weak self] in
                self?.dismissExtension()  // Close extension without sharing
            }
        )

        let hostingController = UIHostingController(rootView: toolSelectionView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear  // Ensure transparent background
        view.backgroundColor = .clear  // Ensure background of the main view is clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Constraints to position the view at the bottom of the screen
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 400)  // Set desired height
        ])
        
        hostingController.didMove(toParent: self)
    }

    @objc private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func openMainApp() {
        guard let selectedTool = selectedTool else {
            showErrorAlert(message: "No tool selected.")
            return
        }

        let encodedContent = sharedContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedTool = selectedTool.caption.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Construct the custom URL
        guard let url = URL(string: "avocadointelligence://tools?text=\(encodedContent)&tool=\(encodedTool)") else {
            showErrorAlert(message: "Invalid URL format.")
            return
        }

        Task {
            if openURL(url) {
                dismissExtension() // Automatically close the extension after sharing
            } else {
                showErrorAlert(message: "Unable to open the main app.")
                dismissExtension()
            }
        }
    }
    
    @objc @discardableResult private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }
        
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancelRequestWithError(message: message)
        }
        alertController.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func cancelRequestWithError(message: String) {
        let error = NSError(domain: "com.nebuxcloud.avocadointelligence", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        extensionContext?.cancelRequest(withError: error)
    }
}

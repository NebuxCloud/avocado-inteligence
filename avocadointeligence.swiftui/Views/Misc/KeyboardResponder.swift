import SwiftUI
import UIKit

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var notificationCenter: NotificationCenter
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            currentHeight = keyboardFrame.height
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        currentHeight = 0
    }
}

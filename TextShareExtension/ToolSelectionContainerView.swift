import SwiftUI
import UIKit

struct ToolSelectionContainerView: View {
    @Binding var isVisible: Bool
    var tools: [WriteTool]
    var onToolSelected: (WriteTool) -> Void
    var onCancel: () -> Void  // Action to perform when canceling

    var body: some View {
        ZStack(alignment: .bottom) {
            if isVisible {
                // Background overlay that detects taps to close the view
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isVisible = false
                        onCancel()  // Trigger cancellation action
                    }
                
                // Tool selection view content at the bottom
                VStack(spacing: 15) {
                    ToolSelectionView(
                        tools: tools,
                        onToolSelected: { tool in
                            onToolSelected(tool)
                            isVisible = false  // Close when a tool is selected
                        },
                        onCancel: {  // Handle the cancel action
                            isVisible = false
                            onCancel()
                        }
                    )
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])  // Rounded corners at the top
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)  // Set height to match hosting controller
            }
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

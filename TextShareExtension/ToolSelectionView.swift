import SwiftUI

struct ToolSelectionView: View {
    var tools: [WriteTool]
    var onToolSelected: (WriteTool) -> Void
    var onCancel: () -> Void  // Action to perform when canceling

    var body: some View {
        VStack(spacing: 15) {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(tools, id: \.caption) { tool in
                        Button(action: {
                            onToolSelected(tool)
                        }) {
                            HStack {
                                Image(systemName: tool.icon)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(tool.color)
                                    .clipShape(Circle())

                                Text(tool.caption)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(tool.color)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.bottom, 10)
            
            // Cancel button
            Button(action: {
                onCancel()  // Call the onCancel action
            }) {
                Text("cancel_button") 
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .frame(width: UIScreen.main.bounds.width * 0.85, height: 280)
    }
}

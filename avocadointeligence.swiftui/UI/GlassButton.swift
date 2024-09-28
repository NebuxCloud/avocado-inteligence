import SwiftUI

struct GlassButton: View {
    var text: String
    var icon: String
    var action: () -> Void = {}
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDisabled ? .gray : .black)
                Text(text)
                    .foregroundColor(isDisabled ? .gray : .black)
                    .fontWeight(.light)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .disabled(isDisabled)
    }
}

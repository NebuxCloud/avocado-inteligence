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
            .background(Color.white.opacity(isDisabled ? 0.1 : 0.25))
            .cornerRadius(15)
        }
        .disabled(isDisabled)
    }
}

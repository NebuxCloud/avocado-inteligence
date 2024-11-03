import SwiftUI

struct CustomTextField: View {
    @Binding var input: String
    @Binding var isLoading: Bool
    var placeholder: String = NSLocalizedString("message_placeholder", comment: "Placeholder for message input")
    var send: () -> Void
    var stopLoading: () -> Void // Acción para parar el loading
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    TextField(placeholder, text: $input, axis: .vertical)
                        .lineLimit(...7)
                        .padding(.horizontal, 8)
                        .disabled(isLoading) // Deshabilita el campo si está en loading
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.leading, 4)
                }
                
                Button {
                    if isLoading {
                        stopLoading()
                    } else {
                        send()
                    }
                } label: {
                    Image(systemName: isLoading ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(isLoading ? .red : (input.isEmpty ? .gray : .blue))
                }
                .disabled(input.isEmpty && !isLoading)
                .padding(.bottom, 4)

            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4) // Ajustamos el padding vertical
            .background(Color(UIColor.systemBackground).opacity(isLoading ? 0.5 : 1.0)) // Fondo ajustable para modo oscuro
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.bottom, 0) // Eliminamos el padding inferior
        .frame(maxWidth: .infinity)
        .frame(minHeight: 55)
    }
}

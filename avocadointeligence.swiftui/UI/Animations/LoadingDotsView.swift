import SwiftUI

struct LoadingDotsView: View {
    @State private var animation = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.gray)
                    .opacity(animation ? 0.3 : 1)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .delay(Double(index) * 0.2)
                            .repeatForever(autoreverses: true),
                        value: animation
                    )
            }
        }
        .onAppear {
            animation = true
        }
    }
}

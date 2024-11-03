import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            ProgressView(NSLocalizedString("loading_model", comment: ""))
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

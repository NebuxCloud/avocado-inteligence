import SwiftUI

struct AboutView: View {
    @ObservedObject var llamaState: LlamaState
    @Binding var isLoading: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Title and subtitle with gradient overlay
                Text("Avocado Intelligence")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(gradient: Gradient(colors: [.green, .blue]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .padding(.bottom, 10)
                
                Text("Your local AI assistant for text editing and more!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Image or Logo with shadow effect
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)

                // Description of the app with a rounded background
                Text("""
                    Avocado Intelligence is your local AI-powered assistant that helps you edit texts and get responses without needing an internet connection. Everything is processed on your device, ensuring speed, privacy, and seamless interaction.
                    """)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .foregroundColor(.gray)

                Spacer()

                // Continue button with activity indicator if loading
                if isLoading {
                    ProgressView("Loading AI...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                
                // Button to Nebux Cloud website
                Button(action: {
                    if let url = URL(string: "https://nebux.cloud/?utm_source=avocado-intelligence&utm_medium=ios-app&utm_campaign=about-section&utm_content=button") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Do you need your own solution?")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)

                // Button for Open Source with link to GitHub repository
                Button(action: {
                    if let url = URL(string: "https://github.com/NebuxCloud/avocado-inteligence") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("We ❤️ Open Source")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top, 10)

            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

import SwiftUI

struct MainView: View {
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
            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Acción para el botón adicional, si es necesario
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.accentColor)
                            .imageScale(.large)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) 
    }
}

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .main
    @StateObject var llamaState = LlamaState() // Estado compartido
    @State private var isLoading: Bool = true // Indicador de carga

    enum Tab {
        case main, editor, assistant
    }

    var body: some View {
        ZStack {
            // Tab View principal
            TabView(selection: $selectedTab) {
                MainView(llamaState: llamaState, isLoading: $isLoading)
                    .tabItem {
                        Label("Main", systemImage: "house")
                    }
                    .tag(Tab.main)

                EditorView(llamaState: llamaState, isLoading: $isLoading)
                    .tabItem {
                        Label("Editor", systemImage: "pencil")
                    }
                    .tag(Tab.editor)

                AssistantView(llamaState: llamaState)
                    .tabItem {
                        Label("Assistant", systemImage: "cpu")
                    }
                    .tag(Tab.assistant)
            }
            .zIndex(0)

            // Capa de carga superpuesta
            if isLoading {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            Task {
                await llamaState.loadDefault()
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack(spacing: 20) {
            ProgressView("Loading AI...")
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
                .padding()

            Text("Preparing AI...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.6)  // Fondo semitransparente
                .ignoresSafeArea()
        )
        .transition(.opacity)  // Transición suave
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

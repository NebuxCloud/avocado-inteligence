import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .assistant
    @StateObject var llamaState = LlamaState() // Estado compartido
    @State private var isLoading: Bool = true // Indicador de carga

    enum Tab {
        case editor, assistant, about, settings
    }

    var body: some View {
        ZStack {
            // Tab View principal
            TabView(selection: $selectedTab) {
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
            
                
                SettingsView(llamaState: llamaState, isLoading: $isLoading)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(Tab.settings)
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
                llamaState.selectModel(llamaState.getSavedModel())
                try await llamaState.loadSelectedModel()
                isLoading = false
            }
        }
        .zIndex(0)
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

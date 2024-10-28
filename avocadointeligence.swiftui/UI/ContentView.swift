import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .assistant
    @StateObject var llamaState = LlamaState()
    @State private var isLoading: Bool = true
    @State private var isMenuVisible: Bool = false // Control de visibilidad del menú

    enum Tab {
        case editor, assistant, settings
    }

    var body: some View {
        ZStack(alignment: .leading) {
            TabView(selection: $selectedTab) {
                EditorView(llamaState: llamaState, isLoading: $isLoading)
                    .tabItem {
                        if !isMenuVisible {
                            Label("Editor", systemImage: "pencil")
                        } else  {
                            Label("", systemImage: "")
                        }
                    }
                    .tag(Tab.editor)
                
                AssistantView(isMenuVisible: $isMenuVisible, llamaState: llamaState) // Pasamos el binding de isMenuVisible
                    .tabItem {
                        if !isMenuVisible {
                            Label("Assistant", systemImage: "cpu")
                        }else  {
                            Label("", systemImage: "")
                        }
                    }
                    .tag(Tab.assistant)
                
                SettingsView(llamaState: llamaState, isLoading: $isLoading)
                    .tabItem {
                        if !isMenuVisible {
                            Label("Settings", systemImage: "gearshape")
                        }else  {
                            Label("", systemImage: "")
                        }
                    }
                    .tag(Tab.settings)
            }
            .zIndex(0)
        }
        .onAppear {
            Task {
                llamaState.selectModel(llamaState.getSavedModel())
                try await llamaState.loadSelectedModel()
                isLoading = false
            }
        }
        .animation(.easeInOut, value: isMenuVisible)
    }
}

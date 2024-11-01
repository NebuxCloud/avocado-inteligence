import SwiftUI

struct ContentView: View {
    @State private var loading = true
    @StateObject var llamaState = LlamaState()

    var body: some View {
        if loading {
            SplashView()
                .onAppear {
                    Task {
                        var savedModel = llamaState.getSavedModel()
                        llamaState.selectModel(savedModel)
                        try await llamaState.loadSelectedModel()
                        loading = false
                    }
                }
        } else {
            MainView()
                .environmentObject(llamaState)
        }
    }
}

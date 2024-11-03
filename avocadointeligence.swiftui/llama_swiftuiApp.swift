import SwiftUI

class SharedData: ObservableObject {
    @Published var text: String = ""
    @Published var tool: String = ""
    @Published var host: String = ""
}

@main
struct llama_swiftuiApp: App {
    @StateObject private var sharedData = SharedData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "avocadointelligence",
              url.host == "tools",
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return
        }

        // Extrae y actualiza los valores en sharedData
        sharedData.host = url.host ?? ""
        sharedData.text = queryItems.first(where: { $0.name == "text" })?.value ?? ""
        sharedData.tool = queryItems.first(where: { $0.name == "tool" })?.value ?? ""
    }
}

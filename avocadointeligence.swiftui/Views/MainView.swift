import SwiftUI

struct MainView: View {
    @State private var isMenuVisible = false
    @State private var menuContent: AnyView? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detecta el tipo de dispositivo

    var body: some View {
        ZStack {
            Color.clear // Fondo principal transparente

            TabView {
                AssistantView(isMenuVisible: $isMenuVisible, menuContent: $menuContent)
                    .tabItem {
                        Label(NSLocalizedString("tabitem.assistant", comment: ""), systemImage: "message")
                    }

                ToolsView(isMenuVisible: $isMenuVisible, menuContent: $menuContent)
                    .tabItem {
                        Label(NSLocalizedString("tabitem.tools", comment: ""), systemImage: "wand.and.stars")
                    }
            }
            .background(
                VStack {
                    Spacer()
                    Color(UIColor.systemGray5)
                        .frame(height: 50) // Ajusta la altura según prefieras
                }
                .edgesIgnoringSafeArea(.bottom)
            )
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemGray6
                
                appearance.shadowImage = UIImage()
                appearance.backgroundImage = UIImage()

                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }

            if isMenuVisible, let content = menuContent {
                SideMenuView(isMenuVisible: $isMenuVisible, content: content)
                    .transition(.move(edge: .leading))
                    .animation(.easeInOut, value: isMenuVisible)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isMenuVisible.toggle()
                }) {
                    Image(systemName: "line.horizontal.3")
                }
            }
        }
    }
}

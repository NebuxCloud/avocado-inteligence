import SwiftUI

struct MainView: View {
    @State private var isMenuVisible = false
    @State private var menuContent: AnyView? = AnyView(SideMenuContentView()) // Ensure it's not nil
    @EnvironmentObject var sharedData: SharedData // Access SharedData

    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $sharedData.host) { // Use host as TabView selection
                AssistantView(isMenuVisible: $isMenuVisible, menuContent: $menuContent)
                    .tabItem {
                        Label(NSLocalizedString("tabitem.assistant", comment: ""), systemImage: "message")
                    }
                    .tag("assistant") // Assign a tag to the tab

                ToolsView(isMenuVisible: $isMenuVisible, menuContent: $menuContent)
                    .tabItem {
                        Label(NSLocalizedString("tabitem.tools", comment: ""), systemImage: "wand.and.stars")
                    }
                    .tag("tools") // Assign a tag to ToolsView matching the host
                    

                SettingsView()
                    .tabItem {
                        Label(NSLocalizedString("tabitem.settings", comment: ""), systemImage: "gear")
                    }
                    .tag("settings")
            }
            .disabled(isMenuVisible) // Disable interactions when the menu is visible
            .blur(radius: isMenuVisible ? 5 : 0) // Apply blur when the menu is visible

            // Semi-transparent background
            if isMenuVisible {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isMenuVisible = false
                        }
                    }
            }

            // Side menu
            SideMenuView(isMenuVisible: $isMenuVisible, content: menuContent!)
                // Offset and animation handled inside SideMenuView
        }
        .onChange(of: sharedData.host) { newHost in // Observe changes to host
            if newHost == "tools" {
                withAnimation {
                    isMenuVisible = false // Close the menu if it was open
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isMenuVisible.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                }
            }
        }
    }
}

import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuVisible: Bool
    let content: AnyView

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    content
                        .padding(.top, geometry.safeAreaInsets.top + 40) // Adds extra padding at the top
                    Spacer()
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom) // Respect the safe area at the bottom
                .frame(width: geometry.size.width * 0.8) // Takes up 80% of the screen width
                .background(Color(.systemBackground))
                .offset(x: isMenuVisible ? 0 : -geometry.size.width * 0.8) // Adjusts position based on menu visibility
                .animation(.easeInOut(duration: 0.3), value: isMenuVisible) // Smooth animation
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

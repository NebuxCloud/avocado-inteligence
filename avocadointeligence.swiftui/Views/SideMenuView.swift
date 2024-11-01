import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuVisible: Bool
    let content: AnyView
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(isMenuVisible ? 0.3 : 0)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isMenuVisible = false
                }
            
            HStack {
                VStack(alignment: .leading) {
                    content
                    Spacer()
                }
                .frame(maxWidth: 350)
                .background(Color(.systemGray6))
                .edgesIgnoringSafeArea(.all)
                
                Spacer()
            }
            .offset(x: isMenuVisible ? 0 : -350)
        }
    }
}

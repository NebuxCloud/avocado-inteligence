import SwiftUI


struct ToolsView: View {
    @Binding var isMenuVisible: Bool
    @Binding var menuContent: AnyView?

    var body: some View {
        VStack {
            Text("Contenido de Herramientas")
                .padding()
            
            Button(action: {
                menuContent = AnyView(ToolsMenuContent()) // Establece el contenido del menú
                isMenuVisible = true
            }) {
                Text("Mostrar Menú de Herramientas")
            }
        }
    }
}

struct ToolsMenuContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Menú de Herramientas")
                .font(.headline)
                .padding(.top, 20)
            
            Button("Parafrasear") {
                print("Parafrasear seleccionado")
            }
            .padding(.leading, 10)
            
            Button("Resumir") {
                print("Resumir seleccionado")
            }
            .padding(.leading, 10)
            
            Button("Cambiar Estilo") {
                print("Cambiar Estilo seleccionado")
            }
            .padding(.leading, 10)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

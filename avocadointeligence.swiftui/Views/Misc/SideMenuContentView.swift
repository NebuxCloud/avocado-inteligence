import SwiftUI

struct SideMenuContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Menú")
                .font(.largeTitle)
                .padding(.top, 100)
                .padding(.leading, 20)

            // Agrega aquí las opciones del menú
            Button(action: {
                // Acción del botón
            }) {
                Text("Opción 1")
                    .padding(.leading, 20)
                    .padding(.top, 20)
            }

            Spacer()
        }
    }
}

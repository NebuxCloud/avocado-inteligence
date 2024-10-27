import SwiftUI

struct SettingsView: View {
    @ObservedObject var llamaState: LlamaState
    @Binding var isLoading: Bool
    @State private var showDownloadView = false
    @State private var showSelectModelView = false

    var body: some View {
        NavigationStack {
            Form {
                // Button to open the model selection view
                Section(header: Text("Model Selection")) {
                    Button(action: {
                        showSelectModelView.toggle()
                    }) {
                        HStack {
                            Text("Selected Model")
                            Spacer()
                            Text(llamaState.selectedModel?.name ?? "None")
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showSelectModelView) {
                        SelectModelView(llamaState: llamaState, isLoading: $isLoading)
                    }
                }
                
                // Button to open the model download view
                Section {
                    Button(action: {
                        showDownloadView.toggle()
                    }) {
                        Text("Download New Models")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showDownloadView) {
                        DownloadModelsView(llamaState: llamaState)
                    }
                }
                
                // Loading indicator
                if isLoading {
                    Section {
                        ProgressView("Loading AI...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                
                // About section at the bottom
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avocado Intelligence")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("""
                        Avocado Intelligence is your local AI-powered assistant for text editing and quick responses, all processed on your device for privacy and speed.
                        """)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 8)
                }
                
                // Buttons below the About section with zero padding
                Section {
                    HStack {
                        Button(action: {
                            if let url = URL(string: "https://nebux.cloud/?utm_source=avocado-intelligence&utm_medium=ios-app&utm_campaign=about-section&utm_content=link") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Need your own solution?")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 0) // Remove horizontal padding
                    
                    HStack {
                        Button(action: {
                            if let url = URL(string: "https://github.com/NebuxCloud/avocado-inteligence") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("We ❤️ Open Source")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 0) // Remove horizontal padding
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MemoryUsageView: View {
    var memoryPercentage: Float
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono que cambia según el porcentaje de uso de memoria
            Image(systemName: icon(for: memoryPercentage))
                .foregroundColor(color(for: memoryPercentage))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(memoryPercentage))% memory usage")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Descripción de rendimiento basada en el porcentaje de uso de memoria
                Text(performanceText(for: memoryPercentage))
                    .font(.caption)
                    .foregroundColor(color(for: memoryPercentage))
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ocupa el ancho completo
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func icon(for percentage: Float) -> String {
        switch percentage {
        case ..<50:
            return "speedometer"       // Icono para rendimiento óptimo
        case 50..<80:
            return "gauge"             // Icono para rendimiento moderado
        case 80..<100:
            return "tortoise.fill"     // Icono de tortuga para rendimiento lento
        default:
            return "exclamationmark.triangle.fill" // Icono de advertencia para rendimiento muy lento
        }
    }
    
    private func color(for percentage: Float) -> Color {
        switch percentage {
        case ..<50:
            return .green
        case 50..<80:
            return .yellow
        case 80..<100:
            return .orange
        default:
            return .red
        }
    }
    
    private func performanceText(for percentage: Float) -> String {
        switch percentage {
        case ..<50:
            return "Optimal performance"
        case 50..<80:
            return "Moderate performance"
        case 80..<100:
            return "Slow performance"
        default:
            return "Very slow performance!"
        }
    }
}

struct DownloadModelsView: View {
    @ObservedObject var llamaState: LlamaState
    @State private var downloadProgress: [UUID: Double] = [:]
    @State private var searchText: String = ""
    @State private var sortDescending: Bool = true // Track sorting order

    var body: some View {
        NavigationStack {
            VStack {
                Text("Larger models are more intelligent but slower; smaller models are faster but may be less accurate.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                HStack {
                    Text("Sort by Size:")
                    Spacer()
                    Button(action: { sortDescending.toggle() }) {
                        Text(sortDescending ? "Largest First" : "Smallest First")
                            .foregroundColor(.blue)
                    }
                }
                .padding([.leading, .trailing])

                List {
                    ForEach(sortedFilteredModels) { model in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(model.name)
                                Spacer()
                                if model.status == "downloading" {
                                    VStack {
                                        ProgressView(value: downloadProgress[model.id] ?? 0.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                        Text("\(Int((downloadProgress[model.id] ?? 0.0) * 100))%")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Button("Download") {
                                        let modelID = model.id
                                        Task {
                                            await llamaState.downloadModel(model) { progress in
                                                Task { @MainActor in
                                                    downloadProgress[modelID] = progress
                                                }
                                            }
                                        }
                                    }
                                    .foregroundColor(.blue)
                                }
                            }

                            MemoryUsageView(memoryPercentage: model.memoryPercentage)

                            if let description = model.description {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search models")
                .navigationTitle("Download Models")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var sortedFilteredModels: [Model] {
        llamaState.undownloadedModels
            .filter { model in
                !model.isLocal && (searchText.isEmpty || model.name.lowercased().contains(searchText.lowercased()))
            }
            .filter { model in
                !llamaState.downloadedModels.contains(where: { $0.name == model.name })
            }
            .sorted { sortDescending ? $0.size > $1.size : $0.size < $1.size }
    }
}

struct SelectModelView: View {
    @ObservedObject var llamaState: LlamaState
    @Binding var isLoading: Bool
    @State private var isEditing = false
    @State private var searchText: String = ""
    @State private var sortDescending: Bool = true // Track sorting order

    var body: some View {
        NavigationStack {
            VStack {
                // Info about model sizes
                Text("Larger models are more intelligent but slower; smaller models are faster but may be less accurate.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                // Toggle for sorting order
                HStack {
                    Text("Sort by Size:")
                    Spacer()
                    Button(action: { sortDescending.toggle() }) {
                        Text(sortDescending ? "Largest First" : "Smallest First")
                            .foregroundColor(.blue)
                    }
                }
                .padding([.leading, .trailing])

                List {
                    // Section for default local models
                    Section(header: Text("Default Local Models")) {
                        ForEach(sortedFilteredLocalModels) { model in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(model.name)
                                    Spacer()
                                    if model == llamaState.selectedModel {
                                        Text("(Selected)")
                                            .foregroundColor(.green)
                                            .font(.footnote)
                                    }
                                }
                                MemoryUsageView(memoryPercentage: model.memoryPercentage)

                                if let description = model.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isEditing && llamaState.selectedModel?.id != model.id {
                                    Task {
                                        isLoading = true
                                        llamaState.selectModel(model)
                                        try await llamaState.loadSelectedModel()
                                        isLoading = false
                                    }
                                }
                            }
                        }
                    }

                    // Section for downloaded models
                    Section(header: Text("Downloaded Models")) {
                        ForEach(sortedFilteredDownloadedModels) { model in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(model.name)
                                    Spacer()
                                    if model == llamaState.selectedModel {
                                        Text("(Selected)")
                                            .foregroundColor(.green)
                                            .font(.footnote)
                                    }
                                }
                                MemoryUsageView(memoryPercentage: model.memoryPercentage)

                                if let description = model.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isEditing && llamaState.selectedModel?.id != model.id {
                                    Task {
                                        isLoading = true
                                        llamaState.selectModel(model)
                                        try await llamaState.loadSelectedModel()
                                        isLoading = false
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let modelToDelete = sortedFilteredDownloadedModels[index]
                                print("Deleting \(modelToDelete.name), isLocal: \(modelToDelete.isLocal)")
                                
                                if let actualIndex = llamaState.downloadedModels.firstIndex(where: { $0.id == modelToDelete.id }), !modelToDelete.isLocal {
                                    llamaState.deleteModel(llamaState.downloadedModels[actualIndex])
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search models")
                .navigationTitle("Select Model")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isEditing.toggle() }) {
                            Text(isEditing ? "Done" : "Edit")
                        }
                    }
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            }
        }
    }

    // Filtered and sorted list of local models based on search text and size
    private var sortedFilteredLocalModels: [Model] {
        llamaState.availableModels
            .filter { $0.isLocal && (searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())) }
            .sorted { sortDescending ? $0.size > $1.size : $0.size < $1.size }
    }

    // Filtered and sorted list of downloaded models based on search text and size
    private var sortedFilteredDownloadedModels: [Model] {
        llamaState.downloadedModels
            .filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }
            .sorted { sortDescending ? $0.size > $1.size : $0.size < $1.size }
    }
}

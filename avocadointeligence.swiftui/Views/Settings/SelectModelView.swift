import SwiftUI

struct SelectModelView: View {
    @EnvironmentObject var llamaState: LlamaState
    @State private var isEditing = false
    @State private var searchText: String = ""
    @State private var sortDescending: Bool = true
    @Binding var refreshView: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Text(NSLocalizedString("model_info", comment: "Model size and performance info"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                HStack {
                    Text(NSLocalizedString("sort_by_size", comment: "Sort by size label"))
                    Spacer()
                    Button(action: { sortDescending.toggle() }) {
                        Text(sortDescending ? NSLocalizedString("largest_first", comment: "Largest first label") : NSLocalizedString("smallest_first", comment: "Smallest first label"))
                            .foregroundColor(.blue)
                    }
                }
                .padding([.leading, .trailing])

                List {
                    Section(header: Text(NSLocalizedString("default_models", comment: "Default local models section"))) {
                        ForEach(sortedFilteredLocalModels) { model in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(model.name)
                                    Spacer()
                                    if model == llamaState.selectedModel {
                                        Text(NSLocalizedString("selected", comment: "Selected model label"))
                                            .foregroundColor(.green)
                                            .font(.footnote)
                                    }
                                }
                                
                                ResourceUsageView(memoryPercentage: model.memoryPercentage, cpuPercentage: model.cpuUsage)

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
                                        llamaState.selectModel(model)
                                        try await llamaState.loadSelectedModel()
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text(NSLocalizedString("downloaded_models", comment: "Downloaded models section"))) {
                        ForEach(sortedFilteredDownloadedModels) { model in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(model.name)
                                    Spacer()
                                    if model == llamaState.selectedModel {
                                        Text(NSLocalizedString("selected", comment: "Selected model label"))
                                            .foregroundColor(.green)
                                            .font(.footnote)
                                    }
                                }
                                
                                ResourceUsageView(memoryPercentage: model.memoryPercentage, cpuPercentage: model.cpuUsage)

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
                                        llamaState.selectModel(model)
                                        try await llamaState.loadSelectedModel()
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let modelToDelete = sortedFilteredDownloadedModels[index]
                                if let actualIndex = llamaState.downloadedModels.firstIndex(where: { $0.id == modelToDelete.id }), !modelToDelete.isLocal {
                                    llamaState.deleteModel(llamaState.downloadedModels[actualIndex])
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: NSLocalizedString("search_models", comment: "Search models"))
                .navigationTitle(NSLocalizedString("select_model", comment: "Select Model view title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isEditing.toggle() }) {
                            Text(isEditing ? NSLocalizedString("done", comment: "Done button") : NSLocalizedString("edit", comment: "Edit button"))
                        }
                    }
                }
                .onAppear{
                    Task {
                        await llamaState.refreshModels()
                    }
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            }
        }
    }

    private var sortedFilteredLocalModels: [Model] {
        llamaState.availableModels
            .filter { $0.isLocal && (searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())) }
            .sorted { sortDescending ? $0.size > $1.size : $0.size < $1.size }
    }

    private var sortedFilteredDownloadedModels: [Model] {
        llamaState.downloadedModels
            .filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }
            .sorted { sortDescending ? $0.size > $1.size : $0.size < $1.size }
    }
}

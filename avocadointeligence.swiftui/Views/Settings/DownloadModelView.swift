import SwiftUI

struct DownloadModelsView: View {
    @EnvironmentObject var llamaState: LlamaState
    @State private var searchText: String = ""
    @State private var sortDescending: Bool = false
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
                    ForEach(sortedFilteredModels) { model in
                        ModelRow(model: model)
                            .environmentObject(llamaState)
                    }
                }
                .searchable(text: $searchText, prompt: NSLocalizedString("search_models", comment: "Search models"))
                .navigationTitle(NSLocalizedString("download_models", comment: "Download Models view title"))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .id(self.refreshView)
        .onChange(of: llamaState.downloadProgress) { progress in
            if progress.values.contains(1.0) {
                Task {
                    await llamaState.refreshModels()
                    refreshView.toggle()
                }
            }
        }
    }

    private var sortedFilteredModels: [Model] {
        let searchFilteredModels = llamaState.undownloadedModels.filter { model in
            searchText.isEmpty || model.name.lowercased().contains(searchText.lowercased())
        }
        
        let nonLocalModels = searchFilteredModels.filter { model in
            !model.isLocal && !llamaState.downloadedModels.contains(where: { $0.name == model.name })
        }
        
        let sortedModels = nonLocalModels.sorted {
            sortDescending ? $0.size > $1.size : $0.size < $1.size
        }
        
        return sortedModels
    }
}

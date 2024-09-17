import Foundation

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
}

@MainActor
class LlamaState: ObservableObject {
    @Published var cacheCleared = false
    @Published var downloadedModels: [Model] = []
    @Published var undownloadedModels: [Model] = []
    private let NS_PER_S: Double = 1_000_000_000.0
    
    private var llamaContext: LlamaContext?
    
    // Default model URL from the bundle
    private var defaultModelUrl: URL? {
        Bundle.main.url(forResource: "Phi-3.5-mini-instruct-IQ3_XS", withExtension: "gguf", subdirectory: "models")
    }

    init() {
        loadModelsFromDisk()
        loadDefaultModels()
    }

    // Loads models from the app's documents directory
    private func loadModelsFromDisk() {
        let documentsURL = getDocumentsDirectory()
        do {
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                let model = Model(name: modelName, url: "", filename: modelURL.lastPathComponent, status: "downloaded")
                downloadedModels.append(model)
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
    }

    // Loads default models and marks those that aren't downloaded
    private func loadDefaultModels() {
        for model in defaultModels {
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                var undownloadedModel = model
                undownloadedModel.status = "download"
                undownloadedModels.append(undownloadedModel)
            }
        }
    }
    
    // Loads the default model and downloads if necessary
    func loadDefault() async {
        for model in defaultModels {
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? loadModel(from: fileURL)
            } else {
                try? await downloadAndLoadModel(model)
            }
        }
    }
    
    // Downloads the model from the given URL
    private func downloadAndLoadModel(_ model: Model) async throws {
        guard let url = URL(string: model.url) else { throw URLError(.badURL) }
        let (tempFileURL, _) = try await URLSession.shared.download(from: url)
        let destinationURL = getDocumentsDirectory().appendingPathComponent(model.filename)
        try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)
        
        undownloadedModels.removeAll { $0.name == model.name }
        downloadedModels.append(model)
        try loadModel(from: destinationURL)
    }

    // Returns the app's documents directory URL
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Predefined models to be managed
    private let defaultModels: [Model] = [
        Model(
            name: "gemma-2b-it-q8_0.gguf",
            url: "https://huggingface.co/lmstudio-ai/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q8_0.gguf?download=true",
            filename: "gemma-2b-it-q8_0.gguf",
            status: "download"
        )
    ]
    
    // Loads a model from the given URL
    func loadModel(from url: URL?) throws {
        guard let url = url else { return }
        llamaContext = try LlamaContext.create_context(path: url.path)
        updateModelStatus(name: url.lastPathComponent, status: "downloaded")
    }

    // Updates the model's status to 'downloaded'
    private func updateModelStatus(name: String, status: String) {
        undownloadedModels.removeAll { $0.name == name }
    }

    // Completes text using the model's context and returns results asynchronously
    // Completes text using the model's context and returns results asynchronously
    func complete(text: String, resultHandler: @escaping (String) -> Void) async {
        guard let llamaContext = llamaContext else { return }

        let start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        
        Task {
            var generatedText = ""
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                generatedText += result
                
                if generatedText.contains("<end_of_turn>") {
                    await llamaContext.markAsDone()
                }
                
                await MainActor.run {
                    resultHandler(result)
                }
            }
        }
    }

    // Clears the model's context
    func clear() async {
        guard let llamaContext = llamaContext else { return }
        await llamaContext.clear()
    }
}

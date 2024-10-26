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
        Bundle.main.url(forResource: "gemma-2-2b-it-Q4_K_M", withExtension: "gguf")
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
    
    // Loads the default model from the bundle if available
    func loadDefault() async {
        if let bundleModelUrl = defaultModelUrl {
            do {
                try loadModel(from: bundleModelUrl)
                print("Loaded model from bundle.")
            } catch {
                print("Failed to load model from bundle: \(error)")
            }
        } else {
            print("No default model found in bundle.")
        }
    }
    
    // Returns the app's documents directory URL
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Predefined models to be managed
    private let defaultModels: [Model] = [
        Model(
            name: "qwen2.5-1.5b-instruct-q8_0.gguf",
            url: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q8_0.gguf?download",
            filename: "qwen2.5-1.5b-instruct-q8_0.gguf",
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
    func complete(text: String, resultHandler: @escaping (String) -> Void, onComplete: @escaping () -> Void) async {
        guard let llamaContext = llamaContext else { return }

        let start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        
        Task {
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await MainActor.run {
                    resultHandler(result)
                }
            }
            await MainActor.run {
                onComplete()
            }
        }
    }
    
    // Clears the model's context
    func clear() async {
        guard let llamaContext = llamaContext else { return }
        await llamaContext.clear()
    }
}

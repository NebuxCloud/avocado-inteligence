import SwiftUI
import Foundation

struct Model: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var url: URL?
    var filename: String
    var isLocal: Bool
    var status: String?
    var description: String?
    var size: Float  // Size in billions of parameters
    var chatTemplate: ([ChatMessage]) -> String
    var bytesInMemory: Float // Memory usage in bytes

    // Computed property to get memory usage percentage
    var memoryPercentage: Float {
        let deviceMemory = Float(ProcessInfo.processInfo.physicalMemory)
        return (bytesInMemory / deviceMemory) * 100
    }

    init(name: String, filename: String, size: Float, description: String? = nil, chatTemplate: @escaping ([ChatMessage]) -> String, bytesInMemory: Float? = nil) {
        self.name = name
        self.filename = filename
        self.isLocal = true
        self.status = "downloaded"
        self.size = size
        self.bytesInMemory = bytesInMemory ?? size * 1_000_000_000 * 4 // default 4 bytes per parameter
        self.url = Bundle.main.url(forResource: filename, withExtension: nil)
        self.description = description
        self.chatTemplate = chatTemplate
    }

    init(name: String, url: URL?, filename: String, size: Float, isLocal: Bool = false, status: String? = "downloaded", description: String? = nil, chatTemplate: @escaping ([ChatMessage]) -> String, bytesInMemory: Float? = nil) {
        self.name = name
        self.url = url
        self.filename = filename
        self.isLocal = isLocal
        self.status = status
        self.size = size
        self.bytesInMemory = bytesInMemory ?? size * 1_000_000_000 * 4 // default 4 bytes per parameter
        self.description = description
        self.chatTemplate = chatTemplate
    }

    // Manual implementation of Equatable
    static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.url == rhs.url && lhs.filename == rhs.filename && lhs.isLocal == rhs.isLocal && lhs.status == rhs.status
    }

    // Manual implementation of Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(url)
        hasher.combine(filename)
        hasher.combine(isLocal)
        hasher.combine(status)
        hasher.combine(size)
        hasher.combine(bytesInMemory)
    }
}

@MainActor
class LlamaState: ObservableObject {
    @Published var cacheCleared = false
    @Published var downloadedModels: [Model] = []
    @Published var undownloadedModels: [Model] = []
    @Published var selectedModel: Model?
    @Published var isLoading: Bool = false
    private let defaultModelName = "Llama-3.2-1B-Instruct-Q4_K_M"
    private let userDefaultsKey = "selectedModelName" // Key for UserDefaults

    private var llamaContext: LlamaContext?
    
    init() {
        refreshModels()
    }
    
    // Refreshes the list of downloaded and available models
    func refreshModels() {
        downloadedModels = loadModelsFromDisk()
        undownloadedModels = loadAvailableModels()
    }
    
    func getSavedModel() -> Model {
        let savedModelName = UserDefaults.standard.string(forKey: userDefaultsKey)
        
        if let savedModelName = savedModelName,
           let savedModel = availableModels.first(where: { $0.name == savedModelName }) {
            return savedModel
        } else {
            // Return the first model in the availableModels list if no saved model is found
            return availableModels[0]
        }
    }

    // Loads models from the documents directory as downloaded (not local)
    private func loadModelsFromDisk() -> [Model] {
        var models: [Model] = []
        let documentsURL = getDocumentsDirectory()
        
        do {
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs where modelURL.pathExtension == "gguf" {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                
                // Search for model in availableModels by name
                if let matchingModel = availableModels.first(where: { $0.name == modelName }) {
                    let model = Model(name: modelName, url: modelURL, filename: modelURL.lastPathComponent, size: matchingModel.size, isLocal: matchingModel.isLocal, status: "downloaded", description: matchingModel.description, chatTemplate: matchingModel.chatTemplate,
                                      bytesInMemory: matchingModel.bytesInMemory
                    )
                    models.append(model)
                } else {
                    print("No matching model found in availableModels for \(modelName)")
                }
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
        
        return models
    }
    
    // Loads available models and classifies them based on local availability
    private func loadAvailableModels() -> [Model] {
        var models: [Model] = []
        
        // Adds models that are not downloaded yet from availableModels
        for model in availableModels where !downloadedModels.contains(model) {
            var undownloadedModel = model
            if !undownloadedModel.isLocal {
                undownloadedModel.status = "download"
            }
            models.append(undownloadedModel)
        }
        
        return models
    }
    
    // Returns the name of the currently selected model
    func selectedModelName() -> String? {
        return selectedModel?.name
    }
    
    // Selects a model from the available models
    func selectModel(_ model: Model) {
        if downloadedModels.contains(where: { $0.name == model.name }) {
            // If the model is in downloadedModels, select it
            selectedModel = model
            saveSelectedModel(model)
        } else {
            selectedModel = availableModels[0]
            saveSelectedModel(availableModels[0])
        }
    }
    
    // Saves the name of the selected model to UserDefaults
    private func saveSelectedModel(_ model: Model) {
        UserDefaults.standard.set(model.name, forKey: userDefaultsKey)
    }
    
    var observation: NSKeyValueObservation?

    @MainActor
    func downloadModel(_ model: Model, onProgressUpdate: @escaping @Sendable (Double) -> Void) async {
        guard let modelURL = model.url else {
            print("Invalid URL for model \(model.name).")
            return
        }

        let modelID = model.id
        let modelFilename = model.filename

        Task { @MainActor in
            if let index = undownloadedModels.firstIndex(where: { $0.id == modelID }) {
                undownloadedModels[index].status = "downloading"
            }
            onProgressUpdate(0.0) // Initialize progress at 0%
        }

        let task = URLSession.shared.downloadTask(with: modelURL) { [weak self] tempURL, response, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.observation?.invalidate()

                if let error = error {
                    print("Error downloading model \(modelFilename): \(error)")
                    if let index = self.undownloadedModels.firstIndex(where: { $0.id == modelID }) {
                        self.undownloadedModels[index].status = "download"
                    }
                    onProgressUpdate(0.0) // Reset progress in case of error
                    return
                }

                guard let tempURL = tempURL, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid response downloading model \(modelFilename).")
                    if let index = self.undownloadedModels.firstIndex(where: { $0.id == modelID }) {
                        self.undownloadedModels[index].status = "download"
                    }
                    onProgressUpdate(0.0)
                    return
                }

                do {
                    let destinationURL = self.getDocumentsDirectory().appendingPathComponent(modelFilename)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                        print("Existing file removed: \(destinationURL)")
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    print("Model \(modelFilename) downloaded and saved at \(destinationURL).")
                    
                    onProgressUpdate(1.0) // Update to 100% upon download completion

                    if let index = self.undownloadedModels.firstIndex(where: { $0.id == modelID }) {
                        self.undownloadedModels[index].status = "downloaded"
                        self.downloadedModels.append(self.undownloadedModels[index])
                        self.undownloadedModels.remove(at: index)
                    }
                } catch {
                    print("Error moving model \(modelFilename): \(error)")
                }
            }
        }

        Task { @MainActor in
            self.observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                let progressValue = progress.fractionCompleted
                Task { @MainActor in
                    onProgressUpdate(progressValue)
                }
            }
        }

        task.resume()
    }
    
    // Deletes a model from the file system and updates the list
    func deleteModel(_ model: Model) {
        guard let index = downloadedModels.firstIndex(of: model) else {
            print("Cannot delete model \(model.name): bundled models cannot be deleted.")
            return
        }
        
        let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            downloadedModels.remove(at: index)
            print("Model \(model.name) deleted successfully.")
            
            // Check if the deleted model was the selected model
            if selectedModel == model {
                // Assign the default model if the selected model was deleted
                if let defaultModel = downloadedModels.first(where: { $0.name == defaultModelName }) {
                    selectedModel = defaultModel
                    saveSelectedModel(defaultModel)
                    print("The selected model was deleted. The default model has been assigned: \(defaultModel.name).")
                } else {
                    print("The default model was not found in downloaded models.")
                }
            }
        } catch {
            print("Failed to delete model \(model.name): \(error)")
        }
        
        self.refreshModels()
    }
    
    // Loads the selected model
    func loadSelectedModel() async throws {
        print("Loading model...")
        guard let selectedModel = selectedModel else { return }
        await self.clear()
        await self.llamaContext?.unload()
        
        let fileURL = selectedModel.isLocal ? selectedModel.url! : getDocumentsDirectory().appendingPathComponent(selectedModel.filename)

        llamaContext = try LlamaContext.create_context(path: fileURL.path)
        print("Loaded model: \(selectedModel.name)")
    }
    
    // Completes text using the selected model
    func complete(text: String, resultHandler: @escaping (String) -> Void, onComplete: @escaping () -> Void) async {
        guard let llamaContext = llamaContext else { return }
        
        await llamaContext.completion_init(text: text)
        
        await withCheckedContinuation { continuation in
            Task {
                // Bucle de completación
                while !(await llamaContext.is_done) {
                    let result = await llamaContext.completion_loop()
                    await MainActor.run {
                        resultHandler(result)
                    }
                }
                await MainActor.run {
                    onComplete()
                    continuation.resume()
                }
            }
        }
    }
    
    func stop() async {
        await self.llamaContext?.markAsDone()
    }

    // Clears the model context
    func clear() async {
        await llamaContext?.clear()
        cacheCleared = true
    }
    
    // Loads a model from a given URL
    func loadModel(from url: URL) throws {
        llamaContext = try LlamaContext.create_context(path: url.path)
    }

    // Gets the app's documents directory
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Updates the undownloaded models list
    private func updateUndownloadedModels(with model: Model) {
        undownloadedModels.removeAll { $0.id == model.id }
        undownloadedModels.append(model)
    }
    
    // Removes a model from the undownloaded list
    private func removeUndownloadedModel(_ model: Model) {
        undownloadedModels.removeAll { $0.id == model.id }
    }
    
    // List of available models, with local models directly pointing to bundle URL
    public let availableModels: [Model] = [
        Model(
            name: "Llama-3.2-1B-Instruct-Q4_K_M",
            filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            size: 1.0,
            description: "Selected as the default model by Avocado Intelligence due to its optimal fit for most applications. Developed by Meta, this model is well-suited for general-purpose tasks, balancing accuracy and speed across all compatible devices.",
            chatTemplate: llamaChatTemplate,
            bytesInMemory: 400 * 1024 * 1024
        ),
        Model(
            name: "Llama-3.2-3B-Instruct-Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"),
            filename: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            size: 3.0,
            isLocal: false,
            status: "download",
            description: "Larger model chosen by Avocado Intelligence for applications needing higher accuracy. Created by Meta, it is ideal for more complex tasks, maintaining compatibility with all devices.",
            chatTemplate: llamaChatTemplate,
            bytesInMemory: 1200 * 1024 * 1024
        ),
        Model(
            name: "gemma-2-2b-it-Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"),
            filename: "gemma-2-2b-it-Q4_K_M.gguf",
            size: 2.0,
            isLocal: false,
            status: "download",
            description: "Previously the default model chosen by Avocado Intelligence. Developed by Google, this model is compatible with all devices and suitable for standard applications requiring reliable performance.",
            chatTemplate: gemmaChatTemplate,
            bytesInMemory: 1130 * 1024 * 1024
        ),
        Model(
            name: "qwen2.5-1.5b-instruct-q4_k_m",
            url: URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"),
            filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            size: 1.5,
            isLocal: false,
            status: "download",
            description: "Compact model by Alibaba, selected by Avocado Intelligence for applications where speed is prioritized over precision. Compatible with all devices and suitable for basic tasks.",
            chatTemplate: qwenChatTemplate,
            bytesInMemory: 350 * 1024 * 1024
        ),
        Model(
            name: "qwen2.5-coder-1.5b-instruct-q4_k_m",
            url: URL(string: "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"),
            filename: "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            size: 1.5,
            isLocal: false,
            status: "download",
            description: "Model optimized for coding applications by Alibaba, selected by Avocado Intelligence for efficient, device-compatible coding tasks with moderate precision.",
            chatTemplate: qwenChatTemplate,
            bytesInMemory: 350 * 1024 * 1024
        ),
        Model(
            name: "Meta-Llama-3.1-8B-Instruct-IQ3_XS",
            url: URL(string: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-IQ3_XS.gguf"),
            filename: "Meta-Llama-3.1-8B-Instruct-IQ3_XS.gguf",
            size: 8.0,
            isLocal: false,
            status: "download",
            description: "High-performance model selected by Avocado Intelligence for applications demanding advanced accuracy and complexity. Created by Meta, this model is ideal for intensive tasks and compatible across multiple devices.",
            chatTemplate: llamaChatTemplate,
            bytesInMemory: 4294 * 1024 * 1024
        )
    ]
}

func llamaChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<|start_header_id|>\($0.role)<|end_header_id|>\($0.content)<|eot_id|>" }.joined() + "<|start_header_id|>assistant<|end_header_id|>\n"
}

func gemmaChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<start_of_turn>\($0.role)\n\($0.content)\n<end_of_turn>" }.joined() + "<start_of_turn>model\n"
}

func qwenChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<|im_start|>\($0.role)\n>\($0.content)<|im_end|>" }.joined() + "<|im_start|>assistant"
}

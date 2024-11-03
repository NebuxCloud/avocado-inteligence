import SwiftUI
import Foundation
import Combine

struct Model: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var url: URL?
    var filename: String
    var isLocal: Bool
    var status: String?
    var description: String?
    var size: Float  // Tamaño en miles de millones de parámetros
    var quantization: String  // Tipo de cuantización
    var chatTemplate: ([ChatMessage]) -> String
    var bytesInMemory: Float // Uso de memoria en bytes
    var cpuUsage: Float // Estimación de uso de CPU en función de núcleos disponibles
    
    // Propiedad computada para obtener el porcentaje de uso de memoria
    var memoryPercentage: Float {
        let deviceMemory = Float(ProcessInfo.processInfo.physicalMemory)
        return (bytesInMemory / deviceMemory) * 100
    }
    
    init(name: String, filename: String, size: Float, quantization: String, description: String? = nil, chatTemplate: @escaping ([ChatMessage]) -> String) {
        self.name = name
        self.filename = filename
        self.isLocal = true
        self.status = "downloaded"
        self.size = size
        self.quantization = quantization
        self.bytesInMemory = Model.calculateBytesInMemory(size: size, quantization: quantization)
        
        let cpuCores = ProcessInfo.processInfo.processorCount
        self.cpuUsage = Model.calculateCpuUsage(size: size, quantization: quantization, cpuCores: cpuCores)
        
        self.url = Bundle.main.url(forResource: filename, withExtension: nil)
        self.description = description
        self.chatTemplate = chatTemplate
    }
    
    init(name: String, url: URL?, filename: String, size: Float, quantization: String, isLocal: Bool = false, status: String? = "downloaded", description: String? = nil, chatTemplate: @escaping ([ChatMessage]) -> String) {
        self.name = name
        self.url = url
        self.filename = filename
        self.isLocal = isLocal
        self.status = status
        self.size = size
        self.quantization = quantization
        self.bytesInMemory = Model.calculateBytesInMemory(size: size, quantization: quantization)
        
        let cpuCores = ProcessInfo.processInfo.processorCount
        self.cpuUsage = Model.calculateCpuUsage(size: size, quantization: quantization, cpuCores: cpuCores)
        
        self.description = description
        self.chatTemplate = chatTemplate
    }
    
    // Método estático para calcular bytesInMemory basado en cuantización
    static func calculateBytesInMemory(size: Float, quantization: String) -> Float {
        let bitsPerParameter = Model.bitsPerParameter(quantization: quantization)
        let bytesPerParameter = bitsPerParameter / 8.0
        let baseMemoryUsage = size * 1_000_000_000 * bytesPerParameter
        
        // Añadimos un factor adicional para buffers y sobrecargas
        let bufferFactor: Float = 1.2 // Factor de sobrecarga (20%)
        return baseMemoryUsage * bufferFactor
    }
    
    // Método estático para estimar el uso de CPU basado en tamaño, cuantización y núcleos de CPU disponibles
    static func calculateCpuUsage(size: Float, quantization: String, cpuCores: Int) -> Float {
        let referenceSize: Float = 3.0  // Tamaño de referencia en miles de millones de parámetros
        let referenceCores = 6
        let targetCpuUsage: Float = 90.0 // Objetivo de uso de CPU para el modelo de referencia

        // Eficiencia computacional específica para el modelo y tipo de cuantización actual
        let modelEfficiency = Model.computationalEfficiency(quantization: quantization)
        
        // Eficiencia computacional de referencia para Q4_K_M
        let referenceEfficiency = Model.computationalEfficiency(quantization: "Q4_K_M")
        
        // Escalado del uso de CPU basado en el modelo de referencia, ajustado al objetivo y a la eficiencia
        let usageScaleFactor = (size / referenceSize) * (Float(referenceCores) / Float(cpuCores)) * (referenceEfficiency / modelEfficiency)
        return usageScaleFactor * targetCpuUsage
    }
    
    // Método estático para obtener bits por parámetro basado en cuantización
    static func bitsPerParameter(quantization: String) -> Float {
        switch quantization {
        case "Q4_K_M", "Q4_K_S":
            return 4.0
        case "Q5_K_M", "Q5_K_S":
            return 5.0
        case "IQ3_XS":
            return 3.0
        case "Q8_0":
            return 8.0
        default:
            return 32.0  // Por defecto 32 bits (4 bytes) por parámetro
        }
    }
    
    // Método estático para calcular la eficiencia computacional basada en la cuantización
    static func computationalEfficiency(quantization: String) -> Float {
        switch quantization {
        case "IQ3_XS":
            return 3.0  // Mayor eficiencia (menos bits)
        case "Q4_K_M", "Q4_K_S":
            return 4.0
        case "Q5_K_M", "Q5_K_S":
            return 5.0
        case "Q8_0":
            return 8.0  // Menor eficiencia (más bits)
        default:
            return 1.0  // Valor por defecto para cuantizaciones desconocidas
        }
    }
    
    // Implementación manual de Equatable
    static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.url == rhs.url && lhs.filename == rhs.filename && lhs.isLocal == rhs.isLocal && lhs.status == rhs.status
    }
    
    // Implementación manual de Hashable
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
    
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var downloadStatus: [UUID: String] = [:]
    
    private var llamaContext: LlamaContext?
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        refreshModels()
        DownloadManager.shared.$downloadProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$downloadProgress)
        
        DownloadManager.shared.$downloadStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$downloadStatus)
    }
    
    init(norefresh: Bool) {
        
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
            return availableModels[0]
        }
    }
    
    private func loadModelsFromDisk() -> [Model] {
        var models: [Model] = []
        let documentsURL = getDocumentsDirectory()
        do {
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs where modelURL.pathExtension == "gguf" {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                if let matchingModel = availableModels.first(where: { $0.name == modelName }) {
                    let model = Model(name: modelName, url: modelURL, filename: modelURL.lastPathComponent, size: matchingModel.size,  quantization: matchingModel.quantization, isLocal: matchingModel.isLocal, status: "downloaded", description: matchingModel.description, chatTemplate: matchingModel.chatTemplate
                                       
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
    func downloadModel(_ model: Model) async {
        DownloadManager.shared.startDownload(for: model)
    }
    
    @MainActor
    func cancelDownload(_ model: Model) {
        DownloadManager.shared.cancelDownload(for: model)
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
    
    func loadDefaultModelFromBundle() async throws {
        guard let defaultModel = availableModels.first(where: { $0.name == defaultModelName }) else {
            fatalError("NOT_AVAILABLE")
        }
        
        let fileURL = Bundle.main.url(forResource: defaultModel.filename, withExtension: nil)
        
        // Verifica que el archivo existe en el bundle
        guard let fileURL = fileURL else {
            fatalError("NOT_FOUND")
        }
        
        // Borra el contexto previo y carga el nuevo modelo en el contexto
        await clear()
        llamaContext = try LlamaContext.create_context(path: fileURL.path)
        print("Sucessful: \(defaultModel.name)")
    }
    
    // Gets the app's documents directory
    private func getDocumentsDirectory() -> URL {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nebuxcloud.avocadointelligence") else {
            fatalError("Could not access shared App Group container.")
        }
        return sharedContainerURL
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
            quantization: "Q4_K_M",
            description: "Selected as the default model by Avocado Intelligence due to its optimal fit for most applications. Developed by Meta, this model is well-suited for general-purpose tasks, balancing accuracy and speed across all compatible devices.",
            chatTemplate: llamaChatTemplate
        ),
        Model(
            name: "Llama-3.2-3B-Instruct-Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"),
            filename: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            size: 3.0,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Larger model chosen by Avocado Intelligence for applications needing higher accuracy. Created by Meta, it is ideal for more complex tasks, maintaining compatibility with all devices.",
            chatTemplate: llamaChatTemplate
        ),
        Model(
            name: "gemma-2-2b-it-Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"),
            filename: "gemma-2-2b-it-Q4_K_M.gguf",
            size: 2.0,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Previously the default model chosen by Avocado Intelligence. Developed by Google, this model is compatible with all devices and suitable for standard applications requiring reliable performance.",
            chatTemplate: gemmaChatTemplate
        ),
        Model(
            name: "qwen2.5-1.5b-instruct-q4_k_m",
            url: URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"),
            filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            size: 1.5,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Compact model by Alibaba, selected by Avocado Intelligence for applications where speed is prioritized over precision. Compatible with all devices and suitable for basic tasks.",
            chatTemplate: qwenChatTemplate
        ),
        Model(
            name: "qwen2.5-coder-1.5b-instruct-q4_k_m",
            url: URL(string: "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"),
            filename: "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            size: 1.5,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Model optimized for coding applications by Alibaba, selected by Avocado Intelligence for efficient, device-compatible coding tasks with moderate precision.",
            chatTemplate: qwenChatTemplate
        ),
        Model(
            name: "Meta-Llama-3.1-8B-Instruct-IQ3_XS",
            url: URL(string: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-IQ3_XS.gguf"),
            filename: "Meta-Llama-3.1-8B-Instruct-IQ3_XS.gguf",
            size: 8.0,
            quantization: "IQ3_XS",
            isLocal: false,
            status: "download",
            description: "High-performance model selected by Avocado Intelligence for applications demanding advanced accuracy and complexity. Created by Meta, this model is ideal for intensive tasks and compatible across multiple devices.",
            chatTemplate: llamaChatTemplate
        ),
        Model(
            name: "smollm2-1.7b-instruct-q4_k_m",
            url: URL(string: "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf"),
            filename: "smollm2-1.7b-instruct-q4_k_m.gguf",
            size: 1.7,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "SmolLM2-1.7B optimized for instruction following with a quantized Q4_K_M precision. Designed for efficient usage on edge devices, balancing model performance and resource constraints.",
            chatTemplate: qwenChatTemplate
        ),
        Model(
            name: "smollm2-360m-instruct-q8_0",
            url: URL(string: "https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q8_0.gguf"),
            filename: "smollm2-360m-instruct-q8_0.gguf",
            size: 0.36,  // Size in billions of parameters
            quantization: "Q8_0",
            isLocal: false,
            status: "download",
            description: "SmolLM2-360M optimized for instruction following with quantized Q8_0 precision. Ideal for lightweight deployment on edge devices with limited resources, maintaining efficient performance.",
            chatTemplate: qwenChatTemplate
        ),
        Model(
            name: "granite-3.0-2b-instruct-Q4_K_M",
            url: URL(string: "https://huggingface.co/lmstudio-community/granite-3.0-2b-instruct-GGUF/resolve/main/granite-3.0-2b-instruct-Q4_K_M.gguf"),
            filename: "granite-3.0-2b-instruct-Q4_K_M.gguf",
            size: 2.0,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Granite 3.0 by IBM, a 2B parameter model optimized for instruction-following tasks with Q4_K_M quantization, providing efficient performance for high-quality responses on edge devices.",
            chatTemplate: graniteChatTemplate
        ),
        Model(
            name: "granite-3.0-3b-a800m-instruct-Q4_K_M",
            url: URL(string: "https://huggingface.co/lmstudio-community/granite-3.0-3b-a800m-instruct-GGUF/resolve/main/granite-3.0-3b-a800m-instruct-Q4_K_M.gguf"),
            filename: "granite-3.0-3b-a800m-instruct-Q4_K_M.gguf",
            size: 3.0,
            quantization: "Q4_K_M",
            isLocal: false,
            status: "download",
            description: "Granite 3.0 by IBM, a 3B parameter model with A800M optimization for instruction-following tasks, quantized with Q4_K_M for efficient inference on edge devices.",
            chatTemplate: graniteChatTemplate
        )
    ]
}

func llamaChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<|start_header_id|>\($0.role)<|end_header_id|>\($0.content)<|eot_id|>" }.joined() + "<|start_header_id|>assistant<|end_header_id|>\n"
}

func gemmaChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<start_of_turn>\($0.role)\n\($0.content)\n<end_of_turn>" }.joined() + "<start_of_turn>model\n"
}

func graniteChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<|start_of_role|>\($0.role)<|end_of_role|>\($0.content)<|end_of_text|>" }.joined() + "<|start_of_role|>assistant<|end_of_role|>"
}


func qwenChatTemplate(messages: [ChatMessage]) -> String {
    return messages.map { "<|im_start|>\($0.role)\n\($0.content)<|im_end|>" }.joined() + "<|im_start|>assistant\n"
}

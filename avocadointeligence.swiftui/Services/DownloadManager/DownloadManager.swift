import Foundation
import Combine

@MainActor
class DownloadManager: NSObject, URLSessionDownloadDelegate, ObservableObject {
    static let shared = DownloadManager()
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var downloadStatus: [UUID: String] = [:] // To manage download status

    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func startDownload(for model: Model) {
        guard let url = model.url else { return }
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.taskDescription = model.id.uuidString // Store modelID
        downloadTasks[model.id] = downloadTask
        downloadProgress[model.id] = 0.0
        downloadStatus[model.id] = "downloading"
        downloadTask.resume()
    }

    func cancelDownload(for model: Model) {
        guard let downloadTask = downloadTasks[model.id] else { return }
        downloadTask.cancel()
        downloadProgress[model.id] = 0.0
        downloadStatus[model.id] = "canceled"
        downloadTasks[model.id] = nil
    }

    // Nonisolated delegate methods
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Retrieve modelID from taskDescription
        guard let modelIDString = downloadTask.taskDescription, let modelID = UUID(uuidString: modelIDString) else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        // Update progress on the main actor
        Task { @MainActor in
            self.downloadProgress[modelID] = progress
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Retrieve modelID from taskDescription
        guard let modelIDString = downloadTask.taskDescription, let modelID = UUID(uuidString: modelIDString) else { return }

        // Move the file synchronously before the method returns
        let destinationURL = DownloadManager.getDocumentsDirectory().appendingPathComponent(
            downloadTask.originalRequest?.url?.lastPathComponent ?? "DownloadedModel"
        )
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("Model saved at \(destinationURL)")
        } catch {
            print("Error saving the file: \(error)")
            return
        }

        // Update state on the main actor
        Task { @MainActor in
            self.downloadProgress[modelID] = 1.0
            self.downloadStatus[modelID] = "downloaded"
            self.downloadTasks[modelID] = nil
        }
    }

    // Make getDocumentsDirectory() a static method
    nonisolated static func getDocumentsDirectory() -> URL {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nebuxcloud.avocadointelligence") else {
            fatalError("Could not access shared App Group container.")
        }
        return sharedContainerURL
    }
}

// Extension to conform to Sendable
extension DownloadManager: @unchecked Sendable {}

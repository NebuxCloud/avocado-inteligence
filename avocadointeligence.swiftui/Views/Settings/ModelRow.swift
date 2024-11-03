import SwiftUI

struct ModelRow: View {
    @EnvironmentObject var llamaState: LlamaState
    var model: Model
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(model.name)
                    .font(.headline)
                Spacer()
                if let progress = llamaState.downloadProgress[model.id], progress < 1.0 {
                    Button(NSLocalizedString("cancel_download", comment: "Cancel download button")) {
                        Task {
                            await llamaState.cancelDownload(model)
                        }
                    }
                    .foregroundColor(.red)
                } else {
                    Button(NSLocalizedString("download", comment: "Download button")) {
                        Task {
                            await llamaState.downloadModel(model)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if let progress = llamaState.downloadProgress[model.id], progress < 1.0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.vertical, 4)
                
                Text("\(Int(progress * 100))%")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            ResourceUsageView(memoryPercentage: model.memoryPercentage, cpuPercentage: model.cpuUsage)
            
            if let description = model.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

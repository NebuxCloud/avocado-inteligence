import SwiftUI

struct MemoryUsageView: View {
    var memoryPercentage: Float
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: memoryPercentage))
                .foregroundColor(color(for: memoryPercentage))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("memory_usage", comment: "Memory usage label"), Int(memoryPercentage)))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(performanceText(for: memoryPercentage))
                    .font(.caption)
                    .foregroundColor(color(for: memoryPercentage))
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func icon(for percentage: Float) -> String {
        switch percentage {
        case ..<50: return "speedometer"
        case 50...80: return "tortoise.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    private func color(for percentage: Float) -> Color {
        switch percentage {
        case ..<50: return .green
        case 50...80: return .orange
        default: return .red
        }
    }
    
    private func performanceText(for percentage: Float) -> String {
        switch percentage {
        case ..<50: return NSLocalizedString("optimal_performance", comment: "Optimal performance text")
        case 50...80: return NSLocalizedString("slow_performance", comment: "Slow performance text")
        default: return NSLocalizedString("very_slow_performance", comment: "Very slow performance text")
        }
    }
}

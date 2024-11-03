import SwiftUI

struct ResourceUsageView: View {
    var memoryPercentage: Float
    var cpuPercentage: Float
    
    private var maxUsage: Float {
        max(memoryPercentage, cpuPercentage)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: maxUsage))
                .foregroundColor(color(for: memoryPercentage, cpuPercentage: cpuPercentage))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("memory_usage", comment: "Memory usage label"), Int(memoryPercentage)))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(String(format: NSLocalizedString("cpu_usage", comment: "CPU usage label"), Int(cpuPercentage)))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(performanceText(for: maxUsage, memoryPercentage: memoryPercentage, cpuPercentage: cpuPercentage))
                    .font(.caption)
                    .foregroundColor(color(for: memoryPercentage, cpuPercentage: cpuPercentage))
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func icon(for percentage: Float) -> String {
        if cpuPercentage > 100 || memoryPercentage > 100 {
            return "exclamationmark.octagon.fill" // Crítico
        } else if cpuPercentage > 95 || memoryPercentage > 95 {
            return "exclamationmark.triangle.fill" // Lento
        } else {
            switch percentage {
            case ..<50: return "speedometer"
            case 50...80: return "tortoise.fill"
            default: return "tortoise.fill" // Solo se muestra como lento si >95%
            }
        }
    }
    
    private func color(for memoryPercentage: Float, cpuPercentage: Float) -> Color {
        if cpuPercentage > 100 || memoryPercentage > 100 {
            return .red // Crítico
        } else if cpuPercentage > 95 || memoryPercentage > 95 {
            return .orange // Lento
        } else {
            switch max(memoryPercentage, cpuPercentage) {
            case ..<50: return .green
            case 50...80: return .orange
            default: return .yellow // Moderado si no es lento
            }
        }
    }
    
    private func performanceText(for percentage: Float, memoryPercentage: Float, cpuPercentage: Float) -> String {
        if cpuPercentage > 100 || memoryPercentage > 100 {
            return NSLocalizedString("critical_performance", comment: "Critical performance text")
        } else if cpuPercentage > 95 || memoryPercentage > 95 {
            return NSLocalizedString("slow_performance", comment: "Slow performance text")
        } else {
            switch percentage {
            case ..<50: return NSLocalizedString("optimal_performance", comment: "Optimal performance text")
            case 50...80: return NSLocalizedString("moderate_performance", comment: "Moderate performance text")
            default: return NSLocalizedString("optimal_performance", comment: "Optimal performance text") // No debe indicar lento si <=95%
            }
        }
    }
}

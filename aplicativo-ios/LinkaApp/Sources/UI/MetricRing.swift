import SwiftUI

struct MetricRing: View {
    var progress: Double
    var isTesting: Bool
    var phase: SpeedTestUIPhase
    var displaySpeed: Double
    
    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.linkaSurface, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                .rotationEffect(Angle(degrees: 135))
            
            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(progress * 0.75, 0.75)))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.linkaSecondary, Color.linkaPrimary]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: 135))
                .animation(.linear(duration: 0.1), value: progress)
            
            VStack(spacing: 8) {
                Text(phaseText)
                    .font(.linkaCaption)
                    .foregroundColor(.linkaTextSecondary)
                    .animation(.none, value: phaseText)
                
                if phase == .downloading || phase == .uploading || phase == .done {
                    Text(String(format: "%.1f", displaySpeed))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.linkaText)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 40)
                    
                    Text("Mbps")
                        .font(.linkaHeadline)
                        .foregroundColor(.linkaTextSecondary)
                } else if phase == .idle {
                    Text("READY")
                        .font(.linkaTitle)
                        .foregroundColor(.linkaText)
                } else if phase == .connecting {
                    Text("Ping")
                        .font(.linkaTitle)
                        .foregroundColor(.linkaText)
                }
            }
        }
        .frame(width: 300, height: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isTesting ? "Testando velocidade, \(phaseText)" : "Pronto para testar")
        .accessibilityValue(String(format: "%.0f porcento", progress * 100))
    }
    
    private var phaseText: String {
        switch phase {
        case .idle: return "Linka Speedtest"
        case .connecting: return "Connecting..."
        case .downloading: return "Download"
        case .uploading: return "Upload"
        case .done: return "Result"
        }
    }
}

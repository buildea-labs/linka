import SwiftUI

struct MetricRing: View {
    var connecting: Bool
    var progress: Double
    var value: String
    var unit: String?
    var size: CGFloat = 168
    var animation: Namespace.ID? = nil
    var matchedId: String? = nil
    
    var body: some View {
        ZStack {
            // Background arc (full circle in the prototype)
            Circle()
                .stroke(Color.borderDefault, lineWidth: 3)
                .frame(width: size, height: size)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(Color.brandSurface, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.linear(duration: 0.15), value: progress)
            
            VStack(spacing: 4) {
                if connecting {
                    Text(value)
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                } else {
                    Group {
                        if let id = matchedId, let ns = animation {
                            Text(value)
                                .matchedGeometryEffect(id: id, in: ns)
                        } else {
                            Text(value)
                        }
                    }
                    .font(size > 200 ? .displayHuge : .displayLarge)
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .tracking(-1)
                    
                    if let u = unit {
                        Text(u)
                            .font(.monoCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(connecting ? value : "\(value) \(unit ?? "")")
        .accessibilityValue(String(format: "%.0f porcento", progress * 100))
    }
}

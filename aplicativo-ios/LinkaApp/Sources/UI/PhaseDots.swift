import SwiftUI

struct PhaseDots: View {
    var phases: [(key: String, label: String)]
    var activeKey: String
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(phases, id: \.key) { phase in
                let isActive = phase.key == activeKey
                HStack(spacing: 6) {
                    Circle()
                        .fill(isActive ? Color.brandSurface : Color.textSecondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .animation(reduceMotion ? nil : LinkaMotion.fade, value: activeKey)
                    
                    Text(phase.label)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                        .foregroundColor(isActive ? .textPrimary : .textSecondary)
                        .animation(reduceMotion ? nil : LinkaMotion.fade, value: activeKey)
                }
            }
        }
    }
}

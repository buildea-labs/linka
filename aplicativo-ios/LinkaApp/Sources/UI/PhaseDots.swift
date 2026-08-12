import SwiftUI

struct PhaseDots: View {
    var phases: [(key: String, label: String)]
    var activeKey: String
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(phases, id: \.key) { phase in
                HStack(spacing: 6) {
                    Circle()
                        .fill(phase.key == activeKey ? Color.brandSurface : Color.textSecondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .animation(LinkaMotion.fade, value: activeKey)
                    
                    Text(phase.label)
                        .font(.bodySmall)
                        .foregroundColor(phase.key == activeKey ? .textPrimary : .textSecondary)
                        .animation(LinkaMotion.fade, value: activeKey)
                }
            }
        }
    }
}

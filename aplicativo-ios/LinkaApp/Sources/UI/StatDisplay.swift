import SwiftUI

struct StatDisplay: View {
    var label: String
    var value: String
    var unit: String
    var accent: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.monoEyebrow)
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.displayTitle)
                    .foregroundColor(accent ? .brandAccentWarm : .textPrimary)
                    .lineLimit(1)
                
                Text(unit)
                    .font(.monoCaption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

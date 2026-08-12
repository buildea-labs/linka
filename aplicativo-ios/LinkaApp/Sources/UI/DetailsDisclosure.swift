import SwiftUI

struct DetailsDisclosure: View {
    var operatorName: String
    var provider: String
    var duration: String
    var ping: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("Operadora **\(operatorName)** · Provedor **\(provider)**")
            Text("Duração **\(duration)s** · Ping **\(ping) ms**")
        }
        .font(.bodySmall)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
    }
}

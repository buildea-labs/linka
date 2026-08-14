import SwiftUI

struct DetailsDisclosure: View {
    var operatorName: String
    var provider: String
    var duration: String
    var ping: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("Rede **\(operatorName)** · Provedor **\(provider)**")
            Text("Duração **\(duration)**")
        }
        .font(.bodySmall)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
    }
}

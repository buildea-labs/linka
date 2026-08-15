import SwiftUI

struct DetailsDisclosure: View {
    var operatorName: String
    var provider: String
    var duration: String
    var ping: Int
    /// Banda Wi-Fi confirmada pelo sistema, em GHz (issue #51) — só
    /// aparece quando a plataforma realmente informa. `nil` é estado
    /// normal (sempre no iPhone; no Mac quando `CoreWLAN` não confirma
    /// nada, ou quando a rede não é Wi-Fi) e não altera o texto.
    var wifiBandGHz: Double? = nil

    private var networkLabel: String {
        guard let wifiBandGHz else { return operatorName }
        let band = wifiBandGHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", wifiBandGHz)
            : String(format: "%.1f", wifiBandGHz)
        return "\(operatorName) · \(band)GHz"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("Rede **\(networkLabel)** · Provedor **\(provider)**")
            Text("Duração **\(duration)**")
        }
        .font(.bodySmall)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
    }
}

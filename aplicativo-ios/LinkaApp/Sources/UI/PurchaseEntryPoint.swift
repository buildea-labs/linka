import Foundation

enum PurchaseEntryPoint: Equatable {
    case settings
    case assist
    case historyInsights
    case advancedWiFi

    var title: String {
        switch self {
        case .settings: "Linka Plus"
        case .assist: "Entenda esta medição"
        case .historyInsights: "Veja o que se repete"
        case .advancedWiFi: "Veja além da velocidade"
        }
    }

    var subtitle: String {
        switch self {
        case .settings:
            "Entenda sua conexão, não apenas a velocidade."
        case .assist:
            "O Linka Plus interpreta o resultado e mostra o que merece atenção."
        case .historyInsights:
            "Compare suas medições e descubra padrões por rede e horário."
        case .advancedWiFi:
            "Use informações extras do Wi-Fi para entender melhor a conexão."
        }
    }
}

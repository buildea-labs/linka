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
            "Entenda suas medições e acompanhe o que muda."
        case .assist:
            "O Linka mostra o que merece atenção com base no que foi medido."
        case .historyInsights:
            "Compare suas medições e encontre padrões por rede e horário."
        case .advancedWiFi:
            "Use sinal, canal e taxa Wi-Fi para dar contexto à análise."
        }
    }
}

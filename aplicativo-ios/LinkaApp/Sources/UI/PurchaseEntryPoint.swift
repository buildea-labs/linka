import Foundation

enum PurchaseEntryPoint: Equatable {
    case settings
    case assist
    case historyInsights
    case advancedWiFi
    case shortcut
    case appIntent

    var title: String {
        switch self {
        case .settings: "Linka Plus"
        case .assist: "Entenda esta medição"
        case .historyInsights: "Veja o que se repete"
        case .advancedWiFi: "Veja além da velocidade"
        case .shortcut, .appIntent: "Automação e Atalhos"
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
        case .shortcut, .appIntent:
            "Automatize testes e acompanhe resultados usando a Siri e os Atalhos."
        }
    }
}

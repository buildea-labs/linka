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
        case .settings: String(localized: "purchase.entry.settings.title", defaultValue: "Linka Plus")
        case .assist: String(localized: "purchase.entry.assist.title", defaultValue: "Entenda esta medição")
        case .historyInsights: String(localized: "purchase.entry.history.title", defaultValue: "Veja o que se repete")
        case .advancedWiFi: String(localized: "purchase.entry.wifi.title", defaultValue: "Veja além da velocidade")
        case .shortcut, .appIntent: String(localized: "purchase.entry.shortcuts.title", defaultValue: "Automação e Atalhos")
        }
    }

    var subtitle: String {
        switch self {
        case .settings:
            String(localized: "purchase.entry.settings.subtitle", defaultValue: "Entenda sua conexão, não apenas a velocidade.")
        case .assist:
            String(localized: "purchase.entry.assist.subtitle", defaultValue: "O Linka Plus interpreta o resultado e mostra o que merece atenção.")
        case .historyInsights:
            String(localized: "purchase.entry.history.subtitle", defaultValue: "Compare suas medições e descubra padrões por rede e horário.")
        case .advancedWiFi:
            String(localized: "purchase.entry.wifi.subtitle", defaultValue: "Use informações extras do Wi-Fi para entender melhor a conexão.")
        case .shortcut, .appIntent:
            String(localized: "purchase.entry.shortcuts.subtitle", defaultValue: "Automatize testes e acompanhe resultados usando a Siri e os Atalhos.")
        }
    }
}

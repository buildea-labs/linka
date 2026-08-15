import Foundation
import NetworkAssist
import NetworkDiagnostics

/// Constrói o `NetworkAssistProviding` que a UI usa. Substitui a antiga
/// resposta algorítmica (if/else PT-BR) por um transport HTTP real que fala
/// com os workers do SignallQ.
///
/// A flag `assistUsesRemoteDiagnostic` (via `Info.plist` ou `UserDefaults`)
/// controla se o Assist responde de verdade ou permanece "não configurado".
/// Default: debug true, release false até validação de campo.
enum AssistContainer {
    static let assistFlagKey = "assistUsesRemoteDiagnostic"

    static func isRemoteAssistEnabled() -> Bool {
        if let override = UserDefaults.standard.object(forKey: assistFlagKey) as? Bool {
            return override
        }
        if let info = Bundle.main.object(forInfoDictionaryKey: assistFlagKey) as? Bool {
            return info
        }
        return true
    }

    static func configuration() -> NetworkDiagnosticsConfiguration {
        let bundle = Bundle.main
        let rulesURL = URL(string: bundle.object(forInfoDictionaryKey: "NDRulesEndpoint") as? String ?? "")
            ?? NetworkDiagnosticsConfiguration.defaultRulesEndpoint
        let aiURL = URL(string: bundle.object(forInfoDictionaryKey: "NDAiEndpoint") as? String ?? "")
            ?? NetworkDiagnosticsConfiguration.defaultAiEndpoint
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String

        #if os(macOS)
        let platformID = "macos"
        #else
        let platformID = "ios"
        #endif

        return NetworkDiagnosticsConfiguration(
            rulesEndpoint: rulesURL,
            aiEndpoint: aiURL,
            requestTimeout: 8,
            appVersion: appVersion,
            platformIdentifier: platformID
        )
    }

    /// Provider para responder pergunta do usuário (conversacional → AI worker).
    static func makeAssistProvider() -> any NetworkAssistProviding {
        guard isRemoteAssistEnabled() else {
            return NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }
        let transport = SignallqAiDiagnosticTransport(
            configuration: configuration(),
            platformProvider: ApplePlatformSignalProvider()
        )
        return NetworkAssistService(transport: transport)
    }

    /// Provider para diagnóstico estruturado (Insight, "como está minha rede?").
    /// Não usado no v1 além do AssistSheet; deixamos exposto para futuro uso.
    static func makeRulesProvider() -> any NetworkAssistProviding {
        guard isRemoteAssistEnabled() else {
            return NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }
        let transport = SignallqDiagnosticTransport(
            configuration: configuration(),
            platformProvider: ApplePlatformSignalProvider()
        )
        return NetworkAssistService(transport: transport)
    }
}

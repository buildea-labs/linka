import Foundation
import LinkaEngine
import NetworkAssist
import NetworkCore
import NetworkDiagnostics
import LinkaEntitlements
import LinkaModules

#if canImport(UIKit)
import UIKit
#endif

/// Constrói o `NetworkAssistProviding` que a UI usa. Substitui a antiga
/// resposta algorítmica (if/else PT-BR) por um transport HTTP real que fala
/// com os workers do SignallQ.
///
/// A flag `assistUsesRemoteDiagnostic` (via `Info.plist` ou `UserDefaults`)
/// controla se o Assist responde de verdade ou permanece "não configurado".
/// Default: debug true, release false até validação de campo.
///
/// Esse flag é ortogonal ao entitlement de plano aplicado por
/// `makeAssistProvider(entitlements:)`: um controla se o transport remoto
/// está configurado neste build; o outro controla se o usuário tem direito
/// ao Assist. O gate de entitlement roda primeiro — um usuário free nunca
/// chega a observar se o transport remoto está ou não configurado.
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
            requestTimeout: 30,
            appVersion: appVersion,
            platformIdentifier: platformID
        )
    }

    /// Provider para responder pergunta do usuário (conversacional → AI worker).
    ///
    /// Envolve o provider real com `EntitlementGatedNetworkAssistProvider`:
    /// o Assist consulta a mesma `LinkaEntitlementPolicy` usada pelo resto
    /// do app antes de responder, em vez de ficar completamente aberto.
    ///
    /// O provider devolvido também responde a `streamAnswer` (issue #69) —
    /// `AssistSheet` usa esse único call-site independente de o transport
    /// remoto de hoje (`SignallqAiDiagnosticTransport`) saber streamar de
    /// verdade ou não; sem streaming real no transport, a resposta revela
    /// de uma vez via o bridge não-streaming de `NetworkAssistService`.
    static func makeAssistProvider(
        entitlements: StoreKitEntitlementProvider
    ) -> any NetworkAssistProviding {
        EntitlementGatedNetworkAssistProvider(
            wrapping: makeRawAssistProvider(),
            snapshot: { await entitlements.snapshot }
        )
    }

    /// Provider para diagnóstico estruturado (Insight, "como está minha rede?").
    /// Não usado no v1 além do AssistSheet; deixamos exposto para futuro uso.
    static func makeRulesProvider(
        entitlements: StoreKitEntitlementProvider
    ) -> any NetworkAssistProviding {
        EntitlementGatedNetworkAssistProvider(
            wrapping: makeRawRulesProvider(),
            snapshot: { await entitlements.snapshot }
        )
    }

    private static func makeRawAssistProvider() -> any NetworkAssistProviding {
        guard isRemoteAssistEnabled() else {
            return NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }
        let api = BuildeaDiagnosticAPI(
            configuration: configuration(),
            platformProvider: ApplePlatformSignalProvider()
        )
        let localTransport = AppleIntelligenceDiagnosticTransport(api: api)
        let remoteTransport = BuildeaDiagnosticTransport(api: api)
        let transport = HybridDiagnosticTransport(localTransport: localTransport, remoteTransport: remoteTransport)
        return NetworkAssistService(transport: transport)
    }

    private static func makeRawRulesProvider() -> any NetworkAssistProviding {
        guard isRemoteAssistEnabled() else {
            return NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }
        let api = BuildeaDiagnosticAPI(
            configuration: configuration(),
            platformProvider: ApplePlatformSignalProvider()
        )
        // Regras não geram texto via IA, então sempre usam fallback desabilitando requestAI (que é default)
        // Neste caso, para reuso e compatibilidade pura, o BuildeaDiagnosticTransport com requestAI = false
        // atuaria como o antigo SignallqDiagnosticTransport, mas como o BuildeaDiagnosticTransport.answer()
        // sempre chama evaluate(requestAI: true), vamos fazer um transport simples inline para regras.
        // Ou melhor, expomos o uso puro do rules. Para manter simples:
        
        struct RulesTransport: NetworkAssistTransport {
            let api: BuildeaDiagnosticAPI
            func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
                let ndsResponse = try await api.evaluate(request.currentMeasurement, requestAI: false)
                guard let rec = ndsResponse.recommendation else {
                    return NetworkAssistResponse(text: "Diagnóstico inconclusivo.", disposition: .insufficientEvidence, evidenceIDs: [])
                }
                return NetworkAssistResponse(text: rec.title, longText: rec.description, disposition: .answered, evidenceIDs: [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)])
            }
        }
        
        return NetworkAssistService(transport: RulesTransport(api: api))
    }

    /// Constrói a investigação local determinística (issue #56) a partir do
    /// fato de falha do motor. 100% on-device: não usa `configuration()`
    /// nem `isRemoteAssistEnabled()` — a investigação nunca depende do
    /// transport remoto do Assist, então indisponibilidade dele nunca a
    /// bloqueia nem impede início de nova medição.
    ///
    /// `reason` mapeia via `AssistFailureSignalMapping` — a única ponte
    /// entre `LinkaEngine` e `NetworkAssist`; o pacote `NetworkAssist`
    /// continua sem importar `LinkaEngine` (AGENTS.md §8). Retorna `nil`
    /// quando não há falha para investigar, preservando divulgação
    /// progressiva: sem falha, não há seção de investigação no `AssistSheet`.
    static func investigateFailure(
        _ reason: EngineFailureReason?,
        recentMeasurements: [NetworkMeasurement]
    ) -> NetworkAssistInvestigationResult? {
        guard let signal = AssistFailureSignalMapping.map(reason) else { return nil }
        return NetworkAssistInvestigationEngine.investigate(
            NetworkAssistInvestigationInput(
                failureSignal: signal,
                recentMeasurements: recentMeasurements
            )
        )
    }

    /// Decide a próxima ação sugerida (issue #58) a partir do resultado da
    /// investigação local (issue #56) — puro repasse para
    /// `NetworkAssistActionEngine.suggest(for:)`, mesma forma de
    /// `investigateFailure`. Retorna `nil` sem nenhuma investigação ou sem
    /// gatilho objetivo suficiente, preservando divulgação progressiva:
    /// sem sugestão, `AssistSheet` não mostra nenhum botão de ação.
    static func suggestedAction(
        for investigation: NetworkAssistInvestigationResult?
    ) -> NetworkAssistActionSuggestion? {
        NetworkAssistActionEngine.suggest(for: investigation)
    }

    /// Executa `.openAppSettings` — a única sugestão de ação que este
    /// adapter sabe executar diretamente. Usa
    /// `UIApplication.openSettingsURLString`, a única forma pública e
    /// documentada pela Apple de deep-linkar em Ajustes a partir de um app
    /// iOS/iPadOS/macOS (Catalyst): abre a página do próprio app dentro de
    /// Ajustes, nunca uma tela interna específica de Wi-Fi ou DNS (não
    /// existe API pública para isso — ver `NetworkAssistManualGuidanceTopic`
    /// em `NetworkAssist`). `.retryMeasurement` é deliberadamente ausente
    /// aqui: quem dispara reteste é o closure do chamador (`AssistSheet`),
    /// nunca este adapter reimplementando o caminho de início de teste.
    ///
    /// No macOS nativo (issue #75) não existe `UIApplication`/
    /// `openSettingsURLString` — `NetworkAssistManualGuidanceTopic` já cobre
    /// a orientação textual equivalente; este adapter só perde o atalho
    /// direto de deep-link, sem inventar um caminho novo no Mac.
    @MainActor
    static func openAppSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

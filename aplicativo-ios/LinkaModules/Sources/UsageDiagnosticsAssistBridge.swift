import NetworkInsights

/// Ponte entre o classificador puro de adequação por uso (`NetworkInsights`)
/// e o Assist (`NetworkAssist`) — issue Expert Mode/diagnóstico de uso.
///
/// `NetworkInsights` não conhece Assist nem copy de produto (AGENTS.md
/// §8/§9); esta ponte vive na camada de agregação (`LinkaModules`), mesmo
/// lugar dos gates de entitlement em `Entitlements.swift`. Produz texto
/// estritamente factual, fundamentado nos veredictos já calculados — nunca
/// cita marca, jogo, app ou serviço específico, mesma restrição de
/// `UsageSuitabilityCopy` na UI (`LinkaApp/Sources/UI/DetailsDisclosure.swift`).
public enum UsageDiagnosticsAssistBridge {
    private static let caseLabels: [UsageCase: String] = [
        .videoCall: "Chamada em vídeo",
        .streamingHD: "Streaming em HD",
        .streaming4K: "Streaming em 4K",
        .onlineGaming: "Jogo online",
        .workUpload: "Envio de arquivos e trabalho"
    ]

    private static let levelLabels: [SuitabilityLevel: String] = [
        .adequate: "adequada",
        .limited: "limitada",
        .notAssessed: "não avaliada (faltam métricas)"
    ]

    /// Resumo compacto e factual de um `UsageSuitabilityReport`, adequado
    /// para `NetworkAssistContext.usageContext` — o Assist usa isto como
    /// evidência grounded, nunca como opinião a repetir literalmente.
    public static func assistSummary(for report: UsageSuitabilityReport) -> String {
        report.verdicts
            .map { verdict in
                let label = caseLabels[verdict.usageCase] ?? verdict.usageCase.rawValue
                let level = levelLabels[verdict.level] ?? verdict.level.rawValue
                return "\(label): \(level)."
            }
            .joined(separator: " ")
    }
}

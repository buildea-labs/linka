import Foundation

/// Constantes e tipos compartilhados entre `LinkaApp` e a extensão de
/// Widget (`LinkaWidget`) — issue #55. `MeasurementHistory` continua a
/// única fonte de verdade do histórico de medições; este pacote carrega
/// só um espelho read-only e derivado do último resultado, porque o
/// processo da extensão de widget não acessa o container de arquivos do
/// app (`FileMeasurementHistoryRepository`).
///
/// Sem UIKit/SwiftUI de propósito — importável tanto pelo app host quanto
/// pela extensão sem arrastar framework de UI para um pacote de dados,
/// mesmo padrão de `NetworkCore`/`MeasurementHistory` (ver
/// `escreverAdaptadorNativo` em `.agents/skills`).
public enum LinkaWidgetShared {
    /// App Group compartilhado entre `LinkaApp` e `LinkaWidget`.
    ///
    /// PENDÊNCIA: como o container iCloud em `LinkaApp.entitlements`
    /// (issue #71), este App Group precisa ser criado e provisionado no
    /// Apple Developer Portal por Luiz/Giam antes de funcionar em
    /// dispositivo real/TestFlight. Sem provisionamento,
    /// `UserDefaults(suiteName:)` volta `nil` (ou um domínio não
    /// compartilhado) e `readLatestSummary`/`writeLatestSummary` falham em
    /// silêncio — o widget cai no estado "sem medição anterior" em vez de
    /// quebrar.
    public static let appGroupIdentifier = "group.com.linka.speedtest"

    /// `kind` do `WidgetConfiguration` declarado em `LinkaSpeedTestWidget`
    /// (target `LinkaWidget`, fora do grafo de build de `LinkaApp`) — usado
    /// pelo app host para `WidgetCenter.shared.reloadTimelines(ofKind:)`
    /// depois de um teste concluído. Vive aqui, e não duplicado como dois
    /// literais de string em targets que não se enxergam.
    public static let widgetKind = "LinkaSpeedTestWidget"

    private static let latestSummaryKey = "com.linka.speedtest.widget.latestSummary"

    /// Espelho read-only do último resultado salvo em `MeasurementHistory`
    /// (fonte de verdade). Escrito pela camada de app (`SpeedTestViewModel`)
    /// logo após `MeasurementHistoryRepository.save()` ter sucesso; lido
    /// pelo `TimelineProvider` da extensão de widget. A extensão nunca
    /// escreve aqui.
    public struct LatestMeasurementSummary: Codable, Equatable, Sendable {
        public let downloadMbps: Double
        public let uploadMbps: Double
        public let latencyMs: Double
        public let measuredAt: Date

        public init(
            downloadMbps: Double,
            uploadMbps: Double,
            latencyMs: Double,
            measuredAt: Date
        ) {
            self.downloadMbps = downloadMbps
            self.uploadMbps = uploadMbps
            self.latencyMs = latencyMs
            self.measuredAt = measuredAt
        }
    }

    /// Escreve o resumo mais recente no App Group. `userDefaults` é
    /// injetável só para teste (evita depender do App Group real, que não
    /// existe em `swift test`); em produção o parâmetro default já resolve
    /// para o suite do App Group.
    ///
    /// Falha silenciosa por design: `nil` (App Group ainda não
    /// provisionado, ou falha de encode) nunca deve derrubar o fluxo de
    /// medição por conta de um espelho best-effort para o widget — o motor
    /// e o histórico continuam a fonte de verdade independentemente disto.
    public static func writeLatestSummary(
        _ summary: LatestMeasurementSummary,
        userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)
    ) {
        guard let defaults = userDefaults,
              let data = try? JSONEncoder().encode(summary) else { return }
        defaults.set(data, forKey: latestSummaryKey)
    }

    /// Lê o último resumo espelhado. `nil` tanto quando o App Group não
    /// está disponível quanto quando nenhum teste foi salvo ainda — o
    /// chamador (o widget) trata os dois casos como "sem medição anterior",
    /// nunca como erro (requisito de aceite da issue #55: estado próprio
    /// para "sem medição anterior", não widget vazio/quebrado).
    public static func readLatestSummary(
        userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)
    ) -> LatestMeasurementSummary? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: latestSummaryKey) else { return nil }
        return try? JSONDecoder().decode(LatestMeasurementSummary.self, from: data)
    }
}

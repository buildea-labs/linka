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
    /// Variação do ping entre as amostras (issue #53). O motor já mede
    /// jitter na fase de ping, antes do `DetailsDisclosure` poder abrir
    /// (`uiPhase == .done`) — mesmo padrão de `ping`, sempre presente aqui.
    var jitter: Double
    /// Percentual de pacotes perdidos (issue #53) — `nil` quando o motor
    /// não reportou perda para este teste; a métrica some, sem "--".
    var packetLossPercent: Double? = nil
    /// Latência medida com a conexão sob carga de download/upload (issue
    /// #53/#52) — `nil` quando o motor não conseguiu calcular para este
    /// teste; a métrica some, sem "--".
    var loadedLatencyMs: Double? = nil

    private var networkLabel: String {
        guard let wifiBandGHz else { return operatorName }
        let band = wifiBandGHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", wifiBandGHz)
            : String(format: "%.1f", wifiBandGHz)
        return "\(operatorName) · \(band)GHz"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            VStack(alignment: .center, spacing: 6) {
                Text("Rede **\(networkLabel)** · Provedor **\(provider)**")
                Text("Duração **\(duration)**")
            }
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                MetricExplanationRow(
                    label: "Ping",
                    valueText: "\(ping) ms",
                    accessibleValue: "\(ping) milissegundos",
                    explanation: MetricExplanation.ping
                )

                MetricExplanationRow(
                    label: "Jitter",
                    valueText: String(format: "%.0f ms", jitter),
                    accessibleValue: String(format: "%.0f milissegundos", jitter),
                    explanation: MetricExplanation.jitter
                )

                if let packetLossPercent {
                    MetricExplanationRow(
                        label: "Perda de pacotes",
                        valueText: "\(Int(packetLossPercent))%",
                        accessibleValue: "\(Int(packetLossPercent)) por cento",
                        explanation: MetricExplanation.packetLoss
                    )
                }

                if let loadedLatencyMs {
                    MetricExplanationRow(
                        label: "Latência sob carga",
                        valueText: String(format: "%.0f ms", loadedLatencyMs),
                        accessibleValue: String(format: "%.0f milissegundos", loadedLatencyMs),
                        explanation: MetricExplanation.loadedLatency
                    )
                }
            }
        }
    }
}

/// Copy curta em linguagem comum para cada métrica (issue #53) — vive só na
/// UI (sem módulo novo), compartilhada com `DetailItem` em `HistoryView`
/// (mesmo target) para os dois lugares falarem a mesma língua. Não é
/// diagnóstico nem tutorial de rede, só o que a métrica significa. Não
/// repete o número que já está na tela.
enum MetricExplanation {
    static let ping = "Tempo de resposta entre o aparelho e o servidor."
    static let jitter = "Variação no tempo de resposta de uma medição para outra."
    static let packetLoss = "Parte dos dados que não chegou ao destino."
    static let loadedLatency = "Quanto o tempo de resposta piora com a conexão ocupada."
}

/// Uma métrica com valor técnico + explicação curta, agrupada como um único
/// elemento de acessibilidade (issue #53) para o VoiceOver ler de forma
/// compreensível em vez de rótulo, valor e explicação como três leituras
/// soltas.
private struct MetricExplanationRow: View {
    let label: String
    let valueText: String
    let accessibleValue: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.bodySmall.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(valueText)
                    .font(.bodySmall.weight(.semibold))
                    .foregroundColor(.textPrimary)
            }
            Text(explanation)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(accessibleValue). \(explanation)")
    }
}

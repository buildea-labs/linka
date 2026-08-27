import SwiftUI
import NetworkCore
import NetworkInsights

struct DetailsDisclosure: View {
    @Environment(\.dismiss) var dismiss
    
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
    /// Velocidades medidas nesta execução (issue #57) — alimentam só a
    /// frase de "para que serve" abaixo; o resultado principal (MetricRing)
    /// já mostra os mesmos números em `MainView`, este parâmetro não
    /// duplica exibição, só entra como insumo do classificador.
    var downloadMbps: Double
    var uploadMbps: Double

    private var networkLabel: String {
        guard let wifiBandGHz else { return operatorName }
        let band = wifiBandGHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", wifiBandGHz)
            : String(format: "%.1f", wifiBandGHz)
        return "\(operatorName) · \(band)GHz"
    }

    /// Medição reconstruída só com o que já chegou até aqui, para alimentar
    /// `UsageSuitabilityEvaluator` (issue #57). Não é uma segunda fonte de
    /// verdade: os mesmos valores que `MainView` já mostra no resultado
    /// principal, reempacotados no contrato canônico que o classificador
    /// puro de `NetworkInsights` espera (AGENTS.md §8 — sem duplicar
    /// lógica de medição na UI, só remontar o dado já medido).
    private var usageSuitabilityMeasurement: NetworkMeasurement {
        NetworkMeasurement(
            outcome: .complete,
            downloadMbps: downloadMbps,
            uploadMbps: uploadMbps,
            latencyMs: Double(ping),
            jitterMs: jitter,
            packetLossPercent: packetLossPercent,
            loadedLatencyMs: loadedLatencyMs
        )
    }

    /// Frase única de "para que serve" a conexão agora (issue #57) — só
    /// existe aqui dentro de "Ver detalhes", nunca no primeiro frame do
    /// resultado (AGENTS.md §6/§9).
    private var usageSuitabilitySentence: String {
        UsageSuitabilityCopy.sentence(
            for: UsageSuitabilityEvaluator().evaluate(usageSuitabilityMeasurement)
        )
    }

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Close Button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.bodySmallStrong)
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.textSecondary.opacity(0.14))
                            .clipShape(Circle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Fechar")
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .center, spacing: 6) {
                            Text("Rede **\(networkLabel)** · Provedor **\(provider)**")
                            Text("Duração **\(duration)**")
                        }
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                        Text(usageSuitabilitySentence)
                            .font(.bodySmallStrong)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel(usageSuitabilitySentence)

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
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
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
    /// issue #128 — paridade de `loadedLatency` para a fase de upload.
    static let loadedLatencyUpload = "Quanto o tempo de resposta piora com a conexão ocupada enviando dados."
}

/// Copy da categoria de responsividade sob carga (issue #128) — vive na UI,
/// mesmo padrão de `MetricExplanation`/`UsageSuitabilityCopy`: o pacote de
/// cálculo (`NetworkInsights`) não conhece texto. Nomeia o fenômeno
/// (fila cheia no roteador / bufferbloat) sem apontar causa não medida
/// (ex.: nunca culpa um aparelho, provedor ou vizinho específico).
enum LoadResponsivenessCopy {
    static func label(for category: LoadResponsivenessCategory) -> String {
        switch category {
        case .high: return "Alta"
        case .medium: return "Média"
        case .low: return "Baixa"
        case .notAssessed: return "Não avaliada"
        }
    }

    static let explanation = "Quanto o tempo de resposta piora quando a conexão está ocupada baixando ou enviando dados — sinal de fila cheia no roteador, mesmo com a velocidade medida normal."
}

/// Traduz o veredito puro de `UsageSuitabilityReport` (NetworkInsights) numa
/// única frase PT-BR de "para que serve" a conexão agora (issue #57).
///
/// Mesmo padrão de `MetricExplanation`: copy de produto vive só na UI, o
/// pacote de interpretação (`NetworkInsights`) não conhece texto nem marca
/// (AGENTS.md §8/§9). Nunca cita jogo, app ou serviço específico e nunca
/// promete desempenho de título algum — só descreve, em linguagem comum, o
/// que as métricas medidas hoje sustentam.
enum UsageSuitabilityCopy {
    /// Ordem de apresentação quando mais de um caso de uso está adequado —
    /// decisão de produto (issue #57), não uma hierarquia técnica entre
    /// unidades incomparáveis (Mbps vs. ms). Representa o "teto" da conexão
    /// do mais ao menos exigente aos olhos de quem está lendo o resultado.
    private static let priorityOrder: [UsageCase] = [.streaming4K, .onlineGaming, .streamingHD, .videoCall]

    private static let positiveSentences: [UsageCase: String] = [
        .videoCall: "Sua conexão sustenta bem chamada em vídeo agora.",
        .streamingHD: "Sua conexão sustenta bem streaming de vídeo agora.",
        .streaming4K: "Sua conexão sustenta bem streaming em 4K agora.",
        .onlineGaming: "Sua conexão sustenta bem jogo online agora."
    ]

    private static let limitingMetricLabels: [NetworkMetric: String] = [
        .downloadMbps: "a velocidade de download",
        .uploadMbps: "a velocidade de upload",
        .latencyMs: "o tempo de resposta",
        .jitterMs: "a variação no tempo de resposta",
        .packetLossPercent: "a perda de pacotes",
        .loadedLatencyMs: "o tempo de resposta com a conexão ocupada"
    ]

    /// Escolhe uma única frase: o caso de uso mais exigente com veredito
    /// `.adequate` (o "teto real" da conexão hoje). Quando nenhum caso
    /// está `.adequate`, cita a métrica mais limitante em vez de uma frase
    /// vazia tipo "conexão limitada" sem explicação — requisito explícito
    /// da issue #57.
    static func sentence(for report: UsageSuitabilityReport) -> String {
        for usageCase in priorityOrder {
            guard let verdict = report.verdict(for: usageCase), verdict.level == .adequate else { continue }
            return positiveSentences[usageCase] ?? ""
        }

        for usageCase in priorityOrder {
            guard let verdict = report.verdict(for: usageCase),
                  let limitingMetric = verdict.limitingMetric,
                  let label = limitingMetricLabels[limitingMetric] else { continue }
            return "Hoje, \(label) é o que mais limita o uso desta conexão."
        }

        return "Ainda não há dados suficientes para avaliar o uso desta conexão."
    }
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
                    .font(.bodySmallStrong)
                    .foregroundColor(.textPrimary)
                Text(valueText)
                    .font(.bodySmallStrong)
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

import SwiftUI
import NetworkCore
import NetworkInsights

/// Copy curta em linguagem comum para cada métrica (issue #53) — vive só na
/// UI, compartilhada por `HistoryView` (`DetailItem`) e `MainView`
/// (`InlineResultDetails`) para os dois lugares falarem a mesma língua. Não
/// é diagnóstico nem tutorial de rede, só o que a métrica significa. Não
/// repete o número que já está na tela.
enum MetricExplanation {
    static var ping: String { String(localized: "metric.explanation.ping", defaultValue: "Tempo de resposta entre o aparelho e o servidor.") }
    static var jitter: String { String(localized: "metric.explanation.jitter", defaultValue: "Variação no tempo de resposta de uma medição para outra.") }
    static var packetLoss: String { String(localized: "metric.explanation.packetLoss", defaultValue: "Parte dos dados que não chegou ao destino.") }
    static var loadedLatency: String { String(localized: "metric.explanation.loadedLatency", defaultValue: "Quanto o tempo de resposta piora com a conexão ocupada.") }
    /// issue #128 — paridade de `loadedLatency` para a fase de upload.
    static var loadedLatencyUpload: String { String(localized: "metric.explanation.loadedLatencyUpload", defaultValue: "Quanto o tempo de resposta piora com a conexão ocupada enviando dados.") }
    static var dnsResolution: String { String(localized: "metric.explanation.dns", defaultValue: "Tempo para traduzir o endereço do servidor em um número de IP.") }
}

/// Copy da categoria de responsividade sob carga (issue #128) — vive na UI,
/// mesmo padrão de `MetricExplanation`/`UsageSuitabilityCopy`: o pacote de
/// cálculo (`NetworkInsights`) não conhece texto. Nomeia o fenômeno
/// (fila cheia no roteador / bufferbloat) sem apontar causa não medida
/// (ex.: nunca culpa um aparelho, provedor ou vizinho específico).
enum LoadResponsivenessCopy {
    static func label(for category: LoadResponsivenessCategory) -> String {
        switch category {
        case .high: return String(localized: "loadResponsiveness.high", defaultValue: "Alta")
        case .medium: return String(localized: "loadResponsiveness.medium", defaultValue: "Média")
        case .low: return String(localized: "loadResponsiveness.low", defaultValue: "Baixa")
        case .notAssessed: return String(localized: "loadResponsiveness.notAssessed", defaultValue: "Não avaliada")
        }
    }

    static func explanation(for category: LoadResponsivenessCategory) -> String {
        switch category {
        case .high:
            return String(localized: "loadResponsiveness.high.explanation", defaultValue: "A conexão continua respondendo bem mesmo durante uso intenso.")
        case .medium, .low:
            return String(localized: "loadResponsiveness.limited.explanation", defaultValue: "A conexão demora mais para responder quando está ocupada.")
        case .notAssessed:
            return String(localized: "loadResponsiveness.notAssessed.explanation", defaultValue: "Não foi possível avaliar a responsividade nesta medição.")
        }
    }
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

    private static func positiveSentence(for usageCase: UsageCase) -> String {
        switch usageCase {
        case .videoCall: return String(localized: "usage.case.videoCall.positive", defaultValue: "Sua conexão sustenta bem chamada em vídeo agora.")
        case .streamingHD: return String(localized: "usage.case.streamingHD.positive", defaultValue: "Sua conexão sustenta bem streaming de vídeo agora.")
        case .streaming4K: return String(localized: "usage.case.streaming4K.positive", defaultValue: "Sua conexão sustenta bem streaming em 4K agora.")
        case .onlineGaming: return String(localized: "usage.case.onlineGaming.positive", defaultValue: "Sua conexão sustenta bem jogo online agora.")
        case .workUpload: return String(localized: "usage.case.workUpload.positive", defaultValue: "Sua conexão sustenta bem envio de arquivos e trabalho agora.")
        }
    }

    private static func limitingMetricLabel(_ metric: NetworkMetric) -> String {
        switch metric {
        case .downloadMbps: return String(localized: "usage.metric.download", defaultValue: "a velocidade de download")
        case .uploadMbps: return String(localized: "usage.metric.upload", defaultValue: "a velocidade de upload")
        case .latencyMs: return String(localized: "usage.metric.latency", defaultValue: "o tempo de resposta")
        case .jitterMs: return String(localized: "usage.metric.jitter", defaultValue: "a variação no tempo de resposta")
        case .packetLossPercent: return String(localized: "usage.metric.packetLoss", defaultValue: "a perda de pacotes")
        case .loadedLatencyMs: return String(localized: "usage.metric.loadedLatency", defaultValue: "o tempo de resposta com a conexão ocupada")
        case .loadedLatencyUploadMs: return String(localized: "usage.metric.loadedLatencyUpload", defaultValue: "o tempo de resposta com a conexão ocupada enviando dados")
        }
    }

    /// Escolhe uma única frase: o caso de uso mais exigente com veredito
    /// `.adequate` (o "teto real" da conexão hoje). Quando nenhum caso
    /// está `.adequate`, cita a métrica mais limitante em vez de uma frase
    /// vazia tipo "conexão limitada" sem explicação — requisito explícito
    /// da issue #57.
    static func sentence(for report: UsageSuitabilityReport) -> String {
        for usageCase in priorityOrder {
            guard let verdict = report.verdict(for: usageCase), verdict.level == .adequate else { continue }
            return positiveSentence(for: usageCase)
        }

        for usageCase in priorityOrder {
            guard let verdict = report.verdict(for: usageCase),
                  let limitingMetric = verdict.limitingMetric else { continue }
            let label = limitingMetricLabel(limitingMetric)
            return String(format: String(localized: "usage.limiting.sentence", defaultValue: "Hoje, %@ é o que mais limita o uso desta conexão."), locale: LinkaLanguagePreference.currentLocale, label)
        }

        return String(localized: "usage.insufficient", defaultValue: "Ainda não há dados suficientes para avaliar o uso desta conexão.")
    }

    /// Título curto de cada `UsageCase`, para a listagem completa de
    /// veredictos (`UsageDiagnosticsView`) — distinto de `positiveSentences`,
    /// que é a frase única de resultado.
    static func title(for usageCase: UsageCase) -> String {
        switch usageCase {
        case .videoCall: return String(localized: "usage.case.videoCall.title", defaultValue: "Chamada em vídeo")
        case .streamingHD: return String(localized: "usage.case.streamingHD.title", defaultValue: "Streaming em HD")
        case .streaming4K: return String(localized: "usage.case.streaming4K.title", defaultValue: "Streaming em 4K")
        case .onlineGaming: return String(localized: "usage.case.onlineGaming.title", defaultValue: "Jogo online")
        case .workUpload: return String(localized: "usage.case.workUpload.title", defaultValue: "Envio de arquivos e trabalho")
        }
    }

    /// Descrição curta de um veredito individual — usada quando cada
    /// `UsageCase` tem sua própria linha (`UsageDiagnosticsView`), diferente
    /// de `sentence(for:)` que escolhe só um caso para uma frase única.
    static func detail(for verdict: UsageCaseVerdict) -> String {
        switch verdict.level {
        case .adequate:
            return positiveSentence(for: verdict.usageCase)
        case .limited:
            if let limitingMetric = verdict.limitingMetric {
                let label = limitingMetricLabel(limitingMetric)
                return String(format: String(localized: "usage.limiting.detail", defaultValue: "Hoje, %@ é o que mais limita esse uso."), locale: LinkaLanguagePreference.currentLocale, label)
            }
            return String(localized: "usage.limited", defaultValue: "Sua conexão está limitada para esse uso agora.")
        case .notAssessed:
            return String(localized: "usage.insufficient.case", defaultValue: "Ainda não há dados suficientes para avaliar esse uso.")
        }
    }

    /// Nível agregado (Boa/Média/Ruim) exibido como resumo de uma linha na
    /// tela de resultado (issue "qualidade de uso Boa/Média/Ruim",
    /// 2026-08-29) — não substitui os veredictos por caso de
    /// `UsageDiagnosticsView`, é só um resumo de leitura rápida.
    /// `.notAssessed` fica fora da proporção: falta de dado não deve
    /// puxar o nível pra baixo nem pra cima, mesmo princípio de
    /// `ConnectionPathStageStatus.unavailable`.
    static func qualityLevel(for report: UsageSuitabilityReport) -> UsageQualityLevel? {
        let assessed = report.verdicts.filter { $0.level != .notAssessed }
        guard !assessed.isEmpty else { return nil }
        let adequateRatio = Double(assessed.filter { $0.level == .adequate }.count) / Double(assessed.count)
        if adequateRatio >= 0.75 { return .good }
        if adequateRatio >= 0.4 { return .medium }
        return .poor
    }
}

/// Três níveis de leitura rápida para a linha "Qualidade de uso" — issue
/// 2026-08-29. Não é um quarto sistema de classificação paralelo aos
/// `SuitabilityLevel`/`ConnectionPathStageStatus`; é só a tradução deles
/// pra um resumo de uma palavra, calculada em `UsageSuitabilityCopy.
/// qualityLevel(for:)`.
enum UsageQualityLevel: Equatable {
    case good
    case medium
    case poor

    var label: String {
        switch self {
        case .good: return String(localized: "usage.quality.good", defaultValue: "Boa")
        case .medium: return String(localized: "usage.quality.medium", defaultValue: "Média")
        case .poor: return String(localized: "usage.quality.poor", defaultValue: "Ruim")
        }
    }

    var color: Color {
        switch self {
        case .good: return .statusGood
        case .medium: return .statusAttention
        case .poor: return .statusCritical
        }
    }
}

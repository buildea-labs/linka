import SwiftUI
import NetworkCore
import NetworkInsights

/// Copy curta em linguagem comum para cada métrica (issue #53) — vive só na
/// UI, compartilhada por `HistoryView` (`DetailItem`) e `MainView`
/// (`InlineResultDetails`) para os dois lugares falarem a mesma língua. Não
/// é diagnóstico nem tutorial de rede, só o que a métrica significa. Não
/// repete o número que já está na tela.
enum MetricExplanation {
    static let ping = "Tempo de resposta entre o aparelho e o servidor."
    static let jitter = "Variação no tempo de resposta de uma medição para outra."
    static let packetLoss = "Parte dos dados que não chegou ao destino."
    static let loadedLatency = "Quanto o tempo de resposta piora com a conexão ocupada."
    /// issue #128 — paridade de `loadedLatency` para a fase de upload.
    static let loadedLatencyUpload = "Quanto o tempo de resposta piora com a conexão ocupada enviando dados."
    static let dnsResolution = "Tempo para traduzir o endereço do servidor em um número de IP."
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

    static func explanation(for category: LoadResponsivenessCategory) -> String {
        switch category {
        case .high:
            return "A conexão continua respondendo bem mesmo durante uso intenso."
        case .medium, .low:
            return "A conexão demora mais para responder quando está ocupada."
        case .notAssessed:
            return "Não foi possível avaliar a responsividade nesta medição."
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

    private static let positiveSentences: [UsageCase: String] = [
        .videoCall: "Sua conexão sustenta bem chamada em vídeo agora.",
        .streamingHD: "Sua conexão sustenta bem streaming de vídeo agora.",
        .streaming4K: "Sua conexão sustenta bem streaming em 4K agora.",
        .onlineGaming: "Sua conexão sustenta bem jogo online agora.",
        .workUpload: "Sua conexão sustenta bem envio de arquivos e trabalho agora."
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

    /// Título curto de cada `UsageCase`, para a listagem completa de
    /// veredictos (`UsageDiagnosticsView`) — distinto de `positiveSentences`,
    /// que é a frase única de resultado.
    private static let caseTitles: [UsageCase: String] = [
        .videoCall: "Chamada em vídeo",
        .streamingHD: "Streaming em HD",
        .streaming4K: "Streaming em 4K",
        .onlineGaming: "Jogo online",
        .workUpload: "Envio de arquivos e trabalho"
    ]

    static func title(for usageCase: UsageCase) -> String {
        caseTitles[usageCase] ?? ""
    }

    /// Descrição curta de um veredito individual — usada quando cada
    /// `UsageCase` tem sua própria linha (`UsageDiagnosticsView`), diferente
    /// de `sentence(for:)` que escolhe só um caso para uma frase única.
    static func detail(for verdict: UsageCaseVerdict) -> String {
        switch verdict.level {
        case .adequate:
            return positiveSentences[verdict.usageCase] ?? "Sua conexão sustenta bem esse uso agora."
        case .limited:
            if let limitingMetric = verdict.limitingMetric,
               let label = limitingMetricLabels[limitingMetric] {
                return "Hoje, \(label) é o que mais limita esse uso."
            }
            return "Sua conexão está limitada para esse uso agora."
        case .notAssessed:
            return "Ainda não há dados suficientes para avaliar esse uso."
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
        case .good: return "Boa"
        case .medium: return "Média"
        case .poor: return "Ruim"
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

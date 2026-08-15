import Foundation

/// Resposta do endpoint `POST /diagnostic/evaluate` do `signallq-diagnostic-worker`.
/// Decoder tolerante: usamos apenas os campos que a UI do Assist consome.
/// Fonte: `signallq-web/src/lib/diagnosticContract.ts` (DiagnosticReportPayload).
public struct DiagnosticReport: Codable, Equatable, Sendable {
    public var evaluationSource: String?
    public var decisao: DiagnosticCard?
    public var recomendacoes: [DiagnosticCard]?
    public var achadosSecundarios: [DiagnosticCard]?
    public var dadosAusentes: [String]?
    public var scoreEngineResultado: ScoreEngineResult?

    public init(
        evaluationSource: String? = nil,
        decisao: DiagnosticCard? = nil,
        recomendacoes: [DiagnosticCard]? = nil,
        achadosSecundarios: [DiagnosticCard]? = nil,
        dadosAusentes: [String]? = nil,
        scoreEngineResultado: ScoreEngineResult? = nil
    ) {
        self.evaluationSource = evaluationSource
        self.decisao = decisao
        self.recomendacoes = recomendacoes
        self.achadosSecundarios = achadosSecundarios
        self.dadosAusentes = dadosAusentes
        self.scoreEngineResultado = scoreEngineResultado
    }
}

public struct DiagnosticCard: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var titulo: String
    public var status: String
    public var evidencia: String?
    public var mensagemUsuario: String
    public var recomendacao: String?
    public var categoria: String?
    public var podeConcluir: Bool?

    public init(
        id: String,
        titulo: String,
        status: String,
        evidencia: String? = nil,
        mensagemUsuario: String,
        recomendacao: String? = nil,
        categoria: String? = nil,
        podeConcluir: Bool? = nil
    ) {
        self.id = id
        self.titulo = titulo
        self.status = status
        self.evidencia = evidencia
        self.mensagemUsuario = mensagemUsuario
        self.recomendacao = recomendacao
        self.categoria = categoria
        self.podeConcluir = podeConcluir
    }
}

public struct ScoreEngineResult: Codable, Equatable, Sendable {
    public var score: Double?
    public var veredictoHumano: String?

    public init(score: Double? = nil, veredictoHumano: String? = nil) {
        self.score = score
        self.veredictoHumano = veredictoHumano
    }
}

import Foundation

public struct NDSRequest: Codable, Equatable, Sendable {
    public var schemaVersion: String?
    public var request_id: String?
    public var sessionId: String?
    public var platform: String?
    public var locale: String?
    public var profile: String?
    public var app: AppInfo?
    public var capabilities: [String]
    public var requestedOutputs: [String]?
    public var context: DiagnosticContext?
    public var connection: Connection?
    public var wifi: Wifi?
    public var speed: Speed?
    public var quality: Quality?
    public var historical: Historical?

    public enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case request_id
        case sessionId
        case platform
        case locale
        case profile
        case app
        case capabilities
        case requestedOutputs = "requested_outputs"
        case context
        case connection
        case wifi
        case speed
        case quality
        case historical
    }

    public init(
        schemaVersion: String? = "1.0",
        request_id: String? = nil,
        sessionId: String? = nil,
        platform: String? = nil,
        locale: String? = nil,
        profile: String? = nil,
        app: AppInfo? = nil,
        capabilities: [String] = [],
        requestedOutputs: [String]? = nil,
        context: DiagnosticContext? = nil,
        connection: Connection? = nil,
        wifi: Wifi? = nil,
        speed: Speed? = nil,
        quality: Quality? = nil,
        historical: Historical? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.request_id = request_id
        self.sessionId = sessionId
        self.platform = platform
        self.locale = locale
        self.profile = profile
        self.app = app
        self.capabilities = capabilities
        self.requestedOutputs = requestedOutputs
        self.context = context
        self.connection = connection
        self.wifi = wifi
        self.speed = speed
        self.quality = quality
        self.historical = historical
    }

    public struct DiagnosticContext: Codable, Equatable, Sendable {
        public var reportedProblem: String?
        public var objective: String?
        public var symptoms: [String]?
        public var answers: [String: String]?

        public enum CodingKeys: String, CodingKey {
            case reportedProblem = "reported_problem"
            case objective
            case symptoms
            case answers
        }

        public init(
            reportedProblem: String? = nil,
            objective: String? = nil,
            symptoms: [String]? = nil,
            answers: [String: String]? = nil
        ) {
            self.reportedProblem = reportedProblem
            self.objective = objective
            self.symptoms = symptoms
            self.answers = answers
        }
    }

    public struct AppInfo: Codable, Equatable, Sendable {
        public var id: String?
        public var version: String?
        public init(id: String? = nil, version: String? = nil) {
            self.id = id
            self.version = version
        }
    }

    public struct Connection: Codable, Equatable, Sendable {
        public var type: String?
        public var hasInternet: Bool?
        public init(type: String? = nil, hasInternet: Bool? = nil) {
            self.type = type
            self.hasInternet = hasInternet
        }
    }

    public struct Wifi: Codable, Equatable, Sendable {
        public var rssiDbm: Double?
        public var linkSpeedMbps: Double?
        public var band: String?
        public init(rssiDbm: Double? = nil, linkSpeedMbps: Double? = nil, band: String? = nil) {
            self.rssiDbm = rssiDbm
            self.linkSpeedMbps = linkSpeedMbps
            self.band = band
        }
    }

    public struct Speed: Codable, Equatable, Sendable {
        public var downloadMbps: Double?
        public var uploadMbps: Double?
        public init(downloadMbps: Double? = nil, uploadMbps: Double? = nil) {
            self.downloadMbps = downloadMbps
            self.uploadMbps = uploadMbps
        }
    }

    public struct Quality: Codable, Equatable, Sendable {
        public var latencyMs: Double?
        public var loadedLatencyMs: Double?
        public var jitterMs: Double?
        public var packetLossPercent: Double?
        public init(latencyMs: Double? = nil, loadedLatencyMs: Double? = nil, jitterMs: Double? = nil, packetLossPercent: Double? = nil) {
            self.latencyMs = latencyMs
            self.loadedLatencyMs = loadedLatencyMs
            self.jitterMs = jitterMs
            self.packetLossPercent = packetLossPercent
        }
    }

    public struct Historical: Codable, Equatable, Sendable {
        public var avgDownload30d: Double?
        public var avgDownload7d: Double?
        public var avgUpload30d: Double?
        public var avgUpload7d: Double?
        public var avgPing30d: Double?
        public var avgPing7d: Double?
        public var tests30d: Int?
        public var tests7d: Int?

        public init(
            avgDownload30d: Double? = nil,
            avgDownload7d: Double? = nil,
            avgUpload30d: Double? = nil,
            avgUpload7d: Double? = nil,
            avgPing30d: Double? = nil,
            avgPing7d: Double? = nil,
            tests30d: Int? = nil,
            tests7d: Int? = nil
        ) {
            self.avgDownload30d = avgDownload30d
            self.avgDownload7d = avgDownload7d
            self.avgUpload30d = avgUpload30d
            self.avgUpload7d = avgUpload7d
            self.avgPing30d = avgPing30d
            self.avgPing7d = avgPing7d
            self.tests30d = tests30d
            self.tests7d = tests7d
        }
    }
}

public struct NDSResponse: Codable, Equatable, Sendable {
    public var results: [NDSResult]?
    public var traces: [NDSTrace]?
    public var recommendation: NDSRecommendation?
    
    public init(results: [NDSResult]? = nil, traces: [NDSTrace]? = nil, recommendation: NDSRecommendation? = nil) {
        self.results = results
        self.traces = traces
        self.recommendation = recommendation
    }
}

public struct NDSErrorEnvelope: Codable, Equatable, Sendable {
    public struct Detail: Codable, Equatable, Sendable {
        public let code: String
        public let message: String
        public let retryable: Bool
    }

    public let error: Detail
    public let requestID: String?

    enum CodingKeys: String, CodingKey {
        case error
        case requestID = "request_id"
    }
}

public struct NDSTrace: Codable, Equatable, Sendable {
    public var module: String
    public var durationMs: Int?
    public var status: String?
    public var error: String?
    public var source: String?

    enum CodingKeys: String, CodingKey {
        case module
        case durationMs = "duration_ms"
        case status
        case error
        case source
    }

    public init(module: String, durationMs: Int? = nil, status: String? = nil, error: String? = nil, source: String? = nil) {
        self.module = module
        self.durationMs = durationMs
        self.status = status
        self.error = error
        self.source = source
    }
}

public struct NDSDimensao: Codable, Equatable, Sendable {
    public var nome: String
    public var status: String

    public init(nome: String, status: String) {
        self.nome = nome
        self.status = status
    }
}

public struct NDSModuleData: Codable, Equatable, Sendable {
    public var score: Int?
    public var explanation: NDSExplanation?
    public var veredicto: String?
    public var observedDimensions: Int?
    public var dimensoes: [NDSDimensao]?
    /// IDs dos achados que sustentam `explanation`, quando o módulo é `ai`
    /// (issue #129). Antes deste campo, o Codable descartava
    /// `source_finding_ids` do módulo `ai` silenciosamente — o Linka não
    /// tinha como saber se uma explicação de IA tinha evidência por trás.
    public var sourceFindingIds: [String]?

    enum CodingKeys: String, CodingKey {
        case score
        case explanation
        case veredicto
        case observedDimensions = "observed_dimensions"
        case dimensoes
        case sourceFindingIds = "source_finding_ids"
    }

    public init(score: Int? = nil, explanation: NDSExplanation? = nil, veredicto: String? = nil, observedDimensions: Int? = nil, dimensoes: [NDSDimensao]? = nil, sourceFindingIds: [String]? = nil) {
        self.score = score
        self.explanation = explanation
        self.veredicto = veredicto
        self.observedDimensions = observedDimensions
        self.dimensoes = dimensoes
        self.sourceFindingIds = sourceFindingIds
    }
}

public struct NDSResult: Codable, Equatable, Sendable {
    public var module: String?
    public var result: NDSModuleData?
    public var cards: [NDSCard]?
    public var warnings: [String]?
    public var missingInputs: [String]?

    enum CodingKeys: String, CodingKey {
        case module
        case result
        case cards
        case warnings
        case missingInputs = "missing_inputs"
    }

    public init(module: String? = nil, result: NDSModuleData? = nil, cards: [NDSCard]? = nil, warnings: [String]? = nil, missingInputs: [String]? = nil) {
        self.module = module
        self.result = result
        self.cards = cards
        self.warnings = warnings
        self.missingInputs = missingInputs
    }
}

public struct NDSRecommendation: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var title: String
    public var description: String
    public var steps: [String]
    public var sourceFindingIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case steps
        case sourceFindingIds = "source_finding_ids"
    }

    public init(id: String, type: String, title: String, description: String, steps: [String] = [], sourceFindingIds: [String]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.steps = steps
        self.sourceFindingIds = sourceFindingIds
    }
}

public struct NDSCard: Codable, Equatable, Sendable {
    public var id: String
    public var titulo: String
    public var status: String
    public var evidencia: String?
    public var mensagemUsuario: String
    public var recomendacao: String?
    public var categoria: String
    public var podeConcluir: Bool
    public var categoriaOrigem: String?

    public init(id: String, titulo: String, status: String, evidencia: String? = nil, mensagemUsuario: String, recomendacao: String? = nil, categoria: String, podeConcluir: Bool, categoriaOrigem: String? = nil) {
        self.id = id
        self.titulo = titulo
        self.status = status
        self.evidencia = evidencia
        self.mensagemUsuario = mensagemUsuario
        self.recomendacao = recomendacao
        self.categoria = categoria
        self.podeConcluir = podeConcluir
        self.categoriaOrigem = categoriaOrigem
    }
}


public struct NDSExplanation: Codable, Equatable, Sendable {
    public var summary: String?
    public var audience: String?
    public var tituloAmigavel: String?
    public var resumoTecnicoTraduzido: String?

    public enum CodingKeys: String, CodingKey {
        case summary
        case audience
        case tituloAmigavel = "titulo_amigavel"
        case resumoTecnicoTraduzido = "resumo_tecnico_traduzido"
    }

    public init(summary: String? = nil, audience: String? = nil, tituloAmigavel: String? = nil, resumoTecnicoTraduzido: String? = nil) {
        self.summary = summary
        self.audience = audience
        self.tituloAmigavel = tituloAmigavel
        self.resumoTecnicoTraduzido = resumoTecnicoTraduzido
    }
}

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
    public var connection: Connection?
    public var wifi: Wifi?
    public var speed: Speed?
    public var quality: Quality?

    public enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case request_id
        case sessionId
        case platform
        case locale
        case profile
        case app
        case capabilities
        case connection
        case wifi
        case speed
        case quality
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
        connection: Connection? = nil,
        wifi: Wifi? = nil,
        speed: Speed? = nil,
        quality: Quality? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.request_id = request_id
        self.sessionId = sessionId
        self.platform = platform
        self.locale = locale
        self.profile = profile
        self.app = app
        self.capabilities = capabilities
        self.connection = connection
        self.wifi = wifi
        self.speed = speed
        self.quality = quality
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
}

public struct NDSResponse: Codable, Equatable, Sendable {
    public var results: [NDSResult]?
    public var recommendation: NDSRecommendation?
    
    public init(results: [NDSResult]? = nil, recommendation: NDSRecommendation? = nil) {
        self.results = results
        self.recommendation = recommendation
    }
}

public struct NDSModuleData: Codable, Equatable, Sendable {
    public var score: Int?
    public var findings: [NDSFinding]?
    public var explanation: NDSExplanation?

    public init(score: Int? = nil, findings: [NDSFinding]? = nil, explanation: NDSExplanation? = nil) {
        self.score = score
        self.findings = findings
        self.explanation = explanation
    }
}

public struct NDSResult: Codable, Equatable, Sendable {
    public var module: String?
    public var result: NDSModuleData?

    public init(module: String? = nil, result: NDSModuleData? = nil) {
        self.module = module
        self.result = result
    }
}

public struct NDSRecommendation: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var title: String
    public var description: String

    public init(id: String, type: String, title: String, description: String) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
    }
}

public struct NDSFinding: Codable, Equatable, Sendable {
    public var type: String
    public var severity: String
    public var value: Double?
    public var message: String

    public init(type: String, severity: String, value: Double? = nil, message: String) {
        self.type = type
        self.severity = severity
        self.value = value
        self.message = message
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

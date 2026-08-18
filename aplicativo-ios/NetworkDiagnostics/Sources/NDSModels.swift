import Foundation

public struct NDSRequest: Codable, Equatable, Sendable {
    public var sessionId: String?
    public var request_id: String?
    public var platform: String?
    public var app: AppInfo?
    public var capabilities: [String]
    public var connection: Connection?
    public var wifi: Wifi?
    public var speed: Speed?
    public var quality: Quality?

    public init(
        sessionId: String? = nil,
        request_id: String? = nil,
        platform: String? = nil,
        app: AppInfo? = nil,
        capabilities: [String] = [],
        connection: Connection? = nil,
        wifi: Wifi? = nil,
        speed: Speed? = nil,
        quality: Quality? = nil
    ) {
        self.sessionId = sessionId
        self.request_id = request_id
        self.platform = platform
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
        public var status: String?
        public init(type: String? = nil, status: String? = nil) {
            self.type = type
            self.status = status
        }
    }

    public struct Wifi: Codable, Equatable, Sendable {
        public var rssi: Double?
        public var frequency: Double?
        public var standard: String?
        public var linkSpeed: Double?
        public init(rssi: Double? = nil, frequency: Double? = nil, standard: String? = nil, linkSpeed: Double? = nil) {
            self.rssi = rssi
            self.frequency = frequency
            self.standard = standard
            self.linkSpeed = linkSpeed
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
        public var packetLossPercent: Double?
        public init(latencyMs: Double? = nil, loadedLatencyMs: Double? = nil, packetLossPercent: Double? = nil) {
            self.latencyMs = latencyMs
            self.loadedLatencyMs = loadedLatencyMs
            self.packetLossPercent = packetLossPercent
        }
    }
}

public struct NDSResponse: Codable, Equatable, Sendable {
    public var recommendation: NDSRecommendation?
    public var explanation: NDSExplanation?
    
    public init(recommendation: NDSRecommendation? = nil, explanation: NDSExplanation? = nil) {
        self.recommendation = recommendation
        self.explanation = explanation
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

public struct NDSExplanation: Codable, Equatable, Sendable {
    public var titulo_amigavel: String?
    public var resumo_tecnico_traduzido: String?

    public init(titulo_amigavel: String? = nil, resumo_tecnico_traduzido: String? = nil) {
        self.titulo_amigavel = titulo_amigavel
        self.resumo_tecnico_traduzido = resumo_tecnico_traduzido
    }
}

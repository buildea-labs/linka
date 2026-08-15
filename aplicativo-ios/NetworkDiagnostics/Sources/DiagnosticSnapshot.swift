import Foundation

/// Espelho estrutural do `DiagnosticSnapshot` schemaVersion 6 aceito pelo
/// `signallq-diagnostic-worker`. Só carregamos os campos que o Apple público
/// consegue preencher — o worker aceita campos ausentes e reporta em
/// `dadosAusentes`.
///
/// Fonte canônica do shape: `integrations/cloudflare/signallq-diagnostic-worker/src/contracts.ts`
/// no repositório SignallQ e `docs_ai/CONTRATOS/openapi/signallq-diagnostic-worker.yaml`.
public struct DiagnosticSnapshot: Codable, Equatable, Sendable {
    public static let schemaVersion: Int = 6

    public var schemaVersion: Int
    public var sessionId: String?
    public var appVersion: String?
    public var platform: String?
    public var connection: Connection?
    public var wifi: Wifi?
    public var speed: Speed?
    public var quality: Quality?
    public var mobile: Mobile?
    public var historical: Historical?

    public init(
        schemaVersion: Int = DiagnosticSnapshot.schemaVersion,
        sessionId: String? = nil,
        appVersion: String? = nil,
        platform: String? = nil,
        connection: Connection? = nil,
        wifi: Wifi? = nil,
        speed: Speed? = nil,
        quality: Quality? = nil,
        mobile: Mobile? = nil,
        historical: Historical? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.sessionId = sessionId
        self.appVersion = appVersion
        self.platform = platform
        self.connection = connection
        self.wifi = wifi
        self.speed = speed
        self.quality = quality
        self.mobile = mobile
        self.historical = historical
    }

    public struct Connection: Codable, Equatable, Sendable {
        public var type: String?
        public var hasInternet: Bool?
        public var ipv6Available: Bool?

        public init(type: String? = nil, hasInternet: Bool? = nil, ipv6Available: Bool? = nil) {
            self.type = type
            self.hasInternet = hasInternet
            self.ipv6Available = ipv6Available
        }
    }

    public struct Wifi: Codable, Equatable, Sendable {
        public var band: String?
        public var rssiDbm: Double?
        public var frequencyMhz: Double?
        public var linkSpeedMbps: Double?

        public init(
            band: String? = nil,
            rssiDbm: Double? = nil,
            frequencyMhz: Double? = nil,
            linkSpeedMbps: Double? = nil
        ) {
            self.band = band
            self.rssiDbm = rssiDbm
            self.frequencyMhz = frequencyMhz
            self.linkSpeedMbps = linkSpeedMbps
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
        public var jitterMs: Double?
        public var packetLossPercent: Double?
        public var loadedLatencyMs: Double?

        public init(
            latencyMs: Double? = nil,
            jitterMs: Double? = nil,
            packetLossPercent: Double? = nil,
            loadedLatencyMs: Double? = nil
        ) {
            self.latencyMs = latencyMs
            self.jitterMs = jitterMs
            self.packetLossPercent = packetLossPercent
            self.loadedLatencyMs = loadedLatencyMs
        }
    }

    public struct Mobile: Codable, Equatable, Sendable {
        public var technology: String?
        public var operatorName: String?

        public init(technology: String? = nil, operatorName: String? = nil) {
            self.technology = technology
            self.operatorName = operatorName
        }
    }

    public struct Historical: Codable, Equatable, Sendable {
        public var testsCount7d: Int?
        public var testsCount30d: Int?
        public var avgDownload7d: Double?
        public var avgDownload30d: Double?
        public var avgUpload7d: Double?
        public var avgUpload30d: Double?
        public var avgPing7d: Double?
        public var avgPing30d: Double?

        public init(
            testsCount7d: Int? = nil,
            testsCount30d: Int? = nil,
            avgDownload7d: Double? = nil,
            avgDownload30d: Double? = nil,
            avgUpload7d: Double? = nil,
            avgUpload30d: Double? = nil,
            avgPing7d: Double? = nil,
            avgPing30d: Double? = nil
        ) {
            self.testsCount7d = testsCount7d
            self.testsCount30d = testsCount30d
            self.avgDownload7d = avgDownload7d
            self.avgDownload30d = avgDownload30d
            self.avgUpload7d = avgUpload7d
            self.avgUpload30d = avgUpload30d
            self.avgPing7d = avgPing7d
            self.avgPing30d = avgPing30d
        }
    }
}

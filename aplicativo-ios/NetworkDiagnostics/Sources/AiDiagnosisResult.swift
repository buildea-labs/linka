import Foundation

/// Resposta do `ai-diagnosis-worker` (`POST /api/ai/diagnostico-conexao`).
/// Schema v2 — o worker sobrescreve `schemaVersion`, `source`, `generatedAt`,
/// `modeloIa` no pós-parse, então esses campos podem chegar como o worker
/// definir. Só declaramos os campos que a UI do Assist consome.
public struct AiDiagnosisResult: Codable, Equatable, Sendable {
    public var schemaVersion: String?
    public var status: String?
    public var titulo: String?
    public var resumo: String?
    public var textoLaudo: String?

    public init(
        schemaVersion: String? = nil,
        status: String? = nil,
        titulo: String? = nil,
        resumo: String? = nil,
        textoLaudo: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.status = status
        self.titulo = titulo
        self.resumo = resumo
        self.textoLaudo = textoLaudo
    }
}

/// Payload que o cliente Linka envia ao `ai-diagnosis-worker`. Formato PT-BR
/// espelha o que o app SignallQ Android envia, para reaproveitar o mesmo
/// prompt e mesmo comportamento do modelo.
public struct AiDiagnosisPayload: Codable, Equatable, Sendable {
    public var connectionType: String?
    public var appVersion: String?
    public var plataforma: String?
    public var metricasAtuais: Metricas?
    public var historico: Historico?
    public var wifi: Wifi?
    public var movel: Movel?
    public var feedbackUsuario: String?

    public init(
        connectionType: String? = nil,
        appVersion: String? = nil,
        plataforma: String? = nil,
        metricasAtuais: Metricas? = nil,
        historico: Historico? = nil,
        wifi: Wifi? = nil,
        movel: Movel? = nil,
        feedbackUsuario: String? = nil
    ) {
        self.connectionType = connectionType
        self.appVersion = appVersion
        self.plataforma = plataforma
        self.metricasAtuais = metricasAtuais
        self.historico = historico
        self.wifi = wifi
        self.movel = movel
        self.feedbackUsuario = feedbackUsuario
    }

    public struct Metricas: Codable, Equatable, Sendable {
        public var downloadMbps: Double?
        public var uploadMbps: Double?
        public var latenciaMs: Double?
        public var jitterMs: Double?
        public var perdaPacotes: Double?
        public var bufferbloatMs: Double?

        public init(
            downloadMbps: Double? = nil,
            uploadMbps: Double? = nil,
            latenciaMs: Double? = nil,
            jitterMs: Double? = nil,
            perdaPacotes: Double? = nil,
            bufferbloatMs: Double? = nil
        ) {
            self.downloadMbps = downloadMbps
            self.uploadMbps = uploadMbps
            self.latenciaMs = latenciaMs
            self.jitterMs = jitterMs
            self.perdaPacotes = perdaPacotes
            self.bufferbloatMs = bufferbloatMs
        }
    }

    public struct Historico: Codable, Equatable, Sendable {
        public var qtdTestes7d: Int?
        public var qtdTestes30d: Int?
        public var mediaDownload7d: Double?
        public var mediaUpload7d: Double?
        public var mediaLatencia7d: Double?

        public init(
            qtdTestes7d: Int? = nil,
            qtdTestes30d: Int? = nil,
            mediaDownload7d: Double? = nil,
            mediaUpload7d: Double? = nil,
            mediaLatencia7d: Double? = nil
        ) {
            self.qtdTestes7d = qtdTestes7d
            self.qtdTestes30d = qtdTestes30d
            self.mediaDownload7d = mediaDownload7d
            self.mediaUpload7d = mediaUpload7d
            self.mediaLatencia7d = mediaLatencia7d
        }
    }

    public struct Wifi: Codable, Equatable, Sendable {
        public var ssid: String?
        public var bssid: String?
        public var rssiDbm: Double?
        public var banda: String?

        public init(ssid: String? = nil, bssid: String? = nil, rssiDbm: Double? = nil, banda: String? = nil) {
            self.ssid = ssid
            self.bssid = bssid
            self.rssiDbm = rssiDbm
            self.banda = banda
        }
    }

    public struct Movel: Codable, Equatable, Sendable {
        public var tecnologia: String?
        public var operadora: String?

        public init(tecnologia: String? = nil, operadora: String? = nil) {
            self.tecnologia = tecnologia
            self.operadora = operadora
        }
    }
}

import Foundation

/// Contrato canônico de uma medição concluída ou parcialmente aproveitável.
///
/// Contém somente fatos medidos e metadados técnicos mínimos. Diagnóstico,
/// assinatura, UI, perguntas do usuário e regras de produto ficam fora daqui.
public struct NetworkMeasurement: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let schemaVersion: Int
    public let id: UUID
    public let measuredAt: Date
    public let outcome: MeasurementOutcome
    public let downloadMbps: Double?
    public let uploadMbps: Double?
    public let latencyMs: Double?
    public let jitterMs: Double?
    public let packetLossPercent: Double?
    public let loadedLatencyMs: Double?
    /// Latência sob carga (ms) durante a fase de upload — issue #128,
    /// paridade com `loadedLatencyMs` (que hoje só cobre download). Campo
    /// aditivo: opcional, `nil` por padrão, não muda `schemaVersion`. Uma
    /// medição antiga (persistida antes desta issue) simplesmente não tem
    /// esta chave no JSON e decodifica com `nil` — mesmo padrão já usado
    /// por `wifiBandGHz` (issue #51) e `durationMs` (issue #50), cobertos
    /// pelos testes `testDecodesLegacyJSONWithout*Field` em
    /// `NetworkCoreTests`. Não reaproveita `loadedLatencyMs` para as duas
    /// fases porque download e upload sob carga são fatos independentes: um
    /// pode existir sem o outro (ex.: sondagem de upload falhou mas a de
    /// download não), e a comparação parada-vs-carga por fase
    /// (`NetworkInsights.LoadResponsivenessEvaluator`) precisa dos dois
    /// valores separadamente, não de um único campo ambíguo.
    public let loadedLatencyUploadMs: Double?
    public let durationMs: Int?
    public let connectionKind: NetworkConnectionKind?
    /// Banda Wi-Fi confirmada pelo sistema, em GHz (ex.: `2.4`, `5`) —
    /// issue #51. Só é preenchida quando a plataforma realmente informa a
    /// banda (hoje, `CoreWLAN` no Mac); nunca inferida por SSID/BSSID. `nil`
    /// é o estado normal quando a plataforma não expõe essa informação
    /// (sempre o caso no iPhone) ou quando `connectionKind` não é `.wifi`.
    public let wifiBandGHz: Double?
    public let networkIdentifier: String?
    public let serverIdentifier: String?
    public let engineVersion: String?
    public let location: MeasurementLocation?

    public init(
        schemaVersion: Int = NetworkMeasurementContract.currentSchemaVersion,
        id: UUID = UUID(),
        measuredAt: Date = Date(),
        outcome: MeasurementOutcome = .partial,
        downloadMbps: Double? = nil,
        uploadMbps: Double? = nil,
        latencyMs: Double? = nil,
        jitterMs: Double? = nil,
        packetLossPercent: Double? = nil,
        loadedLatencyMs: Double? = nil,
        loadedLatencyUploadMs: Double? = nil,
        durationMs: Int? = nil,
        connectionKind: NetworkConnectionKind? = nil,
        wifiBandGHz: Double? = nil,
        networkIdentifier: String? = nil,
        serverIdentifier: String? = nil,
        engineVersion: String? = nil,
        location: MeasurementLocation? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.measuredAt = measuredAt
        self.outcome = outcome
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.latencyMs = latencyMs
        self.jitterMs = jitterMs
        self.packetLossPercent = packetLossPercent
        self.loadedLatencyMs = loadedLatencyMs
        self.loadedLatencyUploadMs = loadedLatencyUploadMs
        self.durationMs = durationMs
        self.connectionKind = connectionKind
        self.wifiBandGHz = wifiBandGHz
        self.networkIdentifier = networkIdentifier
        self.serverIdentifier = serverIdentifier
        self.engineVersion = engineVersion
        self.location = location
    }
}

public enum MeasurementOutcome: String, Codable, Equatable, Hashable, Sendable {
    case complete
    case partial
}

public enum NetworkConnectionKind: String, Codable, Equatable, Hashable, Sendable {
    case wifi
    case cellular
    case ethernet
    case other
}

public struct MeasurementLocation: Codable, Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension NetworkConnectionKind {
    /// Reconcilia amostras de início e fim de uma medição.
    ///
    /// Retorna o tipo comum quando início e fim concordam; `nil` quando
    /// divergem ou quando qualquer uma das amostras está ausente — trocar
    /// de rede (ou não conseguir amostrar) no meio do teste torna o
    /// metadado de interface enganoso, então o estado neutro é preferível
    /// a afirmar um tipo que não valeu para o teste inteiro (issue #51).
    static func resolve(start: NetworkConnectionKind?, end: NetworkConnectionKind?) -> NetworkConnectionKind? {
        guard let start, let end else { return nil }
        return start == end ? start : nil
    }
}

public enum NetworkMeasurementContract {
    public static let currentSchemaVersion = 1

    public static func isValid(_ measurement: NetworkMeasurement) -> Bool {
        violations(for: measurement).isEmpty
    }

    public static func violations(for measurement: NetworkMeasurement) -> [String] {
        var result: [String] = []

        if measurement.schemaVersion != currentSchemaVersion {
            result.append("schemaVersion")
        }

        let metrics: [(String, Double?)] = [
            ("downloadMbps", measurement.downloadMbps),
            ("uploadMbps", measurement.uploadMbps),
            ("latencyMs", measurement.latencyMs),
            ("jitterMs", measurement.jitterMs),
            ("packetLossPercent", measurement.packetLossPercent),
            ("loadedLatencyMs", measurement.loadedLatencyMs),
            ("loadedLatencyUploadMs", measurement.loadedLatencyUploadMs)
        ]

        for (name, value) in metrics {
            if let value, (!value.isFinite || value < 0) {
                result.append(name)
            }
        }

        if let packetLossPercent = measurement.packetLossPercent,
           packetLossPercent > 100 {
            result.append("packetLossPercent")
        }

        if let durationMs = measurement.durationMs, durationMs < 0 {
            result.append("durationMs")
        }

        if let wifiBandGHz = measurement.wifiBandGHz {
            if !wifiBandGHz.isFinite || wifiBandGHz <= 0 {
                result.append("wifiBandGHz")
            }
            // Banda Wi-Fi só faz sentido junto de `connectionKind == .wifi` —
            // caso contrário seria um metadado enganoso (issue #51).
            if measurement.connectionKind != .wifi {
                result.append("wifiBandGHz")
            }
        }

        switch measurement.outcome {
        case .complete:
            if measurement.downloadMbps == nil { result.append("downloadMbps") }
            if measurement.uploadMbps == nil { result.append("uploadMbps") }
            if measurement.latencyMs == nil { result.append("latencyMs") }
        case .partial:
            let hasMeasuredMetric = metrics.contains { $0.1 != nil }
            if !hasMeasuredMetric { result.append("metrics") }
        }

        return Array(Set(result)).sorted()
    }
}

import Foundation

/// Contrato canônico de uma medição concluída ou parcialmente aproveitável do Linka.
///
/// O tipo descreve somente fatos medidos e metadados técnicos mínimos. Diagnóstico,
/// opinião, assinatura, UI e contexto declarado pelo usuário pertencem a outras camadas.
public struct NetworkMeasurement: Identifiable, Codable, Equatable, Sendable {
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
    public let durationMs: Int?
    public let connectionKind: NetworkConnectionKind?
    public let networkIdentifier: String?
    public let serverIdentifier: String?
    public let engineVersion: String?

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
        durationMs: Int? = nil,
        connectionKind: NetworkConnectionKind? = nil,
        networkIdentifier: String? = nil,
        serverIdentifier: String? = nil,
        engineVersion: String? = nil
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
        self.durationMs = durationMs
        self.connectionKind = connectionKind
        self.networkIdentifier = networkIdentifier
        self.serverIdentifier = serverIdentifier
        self.engineVersion = engineVersion
    }
}

public enum MeasurementOutcome: String, Codable, Equatable, Sendable {
    case complete
    case partial
}

public enum NetworkConnectionKind: String, Codable, Equatable, Sendable {
    case wifi
    case cellular
    case ethernet
    case other
}

/// Regras mínimas que qualquer adapter ou repositório deve respeitar antes de
/// considerar uma `NetworkMeasurement` persistível.
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
            ("loadedLatencyMs", measurement.loadedLatencyMs)
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

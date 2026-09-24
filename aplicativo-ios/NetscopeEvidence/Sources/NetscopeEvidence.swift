import Foundation
import NetworkCore

/// Fatos estritamente allowlisted de uma medição local para uma leitura futura
/// do Netscope. Não contém identificadores de rede, localização, servidor,
/// dados de conta ou inferências sobre a causa/qualidade da conexão.
public struct NetscopeMeasurementEvidence: Codable, Equatable, Sendable {
    public enum ConnectionKind: String, Codable, Equatable, Sendable {
        case wifi
        case cellular
        case ethernet
        case other
        /// A rota não foi observada durante toda a medição. Não representa um
        /// quinto tipo de rede e nunca é substituída por uma estimativa.
        case unknown
    }

    /// Detalhes factuais de Wi-Fi que não identificam a rede. Todos permanecem
    /// opcionais porque as APIs públicas variam entre plataformas.
    public struct WiFiDetails: Codable, Equatable, Sendable {
        public let bandGHz: Double?
        public let rssiDbm: Double?
        public let linkSpeedMbps: Double?

        public init(bandGHz: Double?, rssiDbm: Double?, linkSpeedMbps: Double?) {
            self.bandGHz = bandGHz
            self.rssiDbm = rssiDbm
            self.linkSpeedMbps = linkSpeedMbps
        }

        fileprivate var hasObservedValue: Bool {
            bandGHz != nil || rssiDbm != nil || linkSpeedMbps != nil
        }
    }

    public let downloadMbps: Double?
    public let uploadMbps: Double?
    public let latencyMs: Double?
    public let jitterMs: Double?
    public let packetLossPercent: Double?
    public let connectionKind: ConnectionKind
    public let wifiDetails: WiFiDetails?

    public init(
        downloadMbps: Double?,
        uploadMbps: Double?,
        latencyMs: Double?,
        jitterMs: Double?,
        packetLossPercent: Double?,
        connectionKind: ConnectionKind,
        wifiDetails: WiFiDetails?
    ) {
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.latencyMs = latencyMs
        self.jitterMs = jitterMs
        self.packetLossPercent = packetLossPercent
        self.connectionKind = connectionKind
        // Detalhes Wi-Fi não descrevem uma rota celular, Ethernet, outra ou
        // indeterminada. A ausência não é preenchida com um valor neutro.
        self.wifiDetails = connectionKind == .wifi ? wifiDetails : nil
    }
}

/// Contexto opcional declarado pela pessoa. Ele é intencionalmente separado
/// da evidência observada para não ser interpretado como propriedade da rede.
public struct NetscopeDeclaredContext: Codable, Equatable, Sendable {
    public enum Objective: String, Codable, Equatable, Sendable {
        case videoCall
        case gaming
        case streaming
        case general
    }

    public let objective: Objective?

    public init(objective: Objective? = nil) {
        self.objective = objective
    }
}

/// Entrada local tipada conectada ao sheet L-03 somente como preparação local.
/// Nesta fatia ela não é enviada pela rede: o reader padrão permanece
/// indisponível e não transmite a evidência.
public struct NetscopeLocalAnalysisInput: Codable, Equatable, Sendable {
    public let observedEvidence: NetscopeMeasurementEvidence
    public let declaredContext: NetscopeDeclaredContext

    public init(
        observedEvidence: NetscopeMeasurementEvidence,
        declaredContext: NetscopeDeclaredContext = .init()
    ) {
        self.observedEvidence = observedEvidence
        self.declaredContext = declaredContext
    }
}

/// Projeta o contrato canônico para a allowlist do Netscope. A projeção é
/// deliberadamente tolerante a registros parciais: descarta cada valor inválido
/// individualmente, preservando os demais fatos válidos sem transformar
/// ausência, `NaN`, infinito ou valor fora da faixa em zero.
public enum NetscopeMeasurementEvidenceProjector {
    public static func project(_ measurement: NetworkMeasurement) -> NetscopeMeasurementEvidence {
        let connectionKind = projectedConnectionKind(measurement.connectionKind)
        let wifiDetails = connectionKind == .wifi
            ? projectedWiFiDetails(measurement)
            : nil

        return NetscopeMeasurementEvidence(
            downloadMbps: nonNegativeFinite(measurement.downloadMbps),
            uploadMbps: nonNegativeFinite(measurement.uploadMbps),
            latencyMs: nonNegativeFinite(measurement.latencyMs),
            jitterMs: nonNegativeFinite(measurement.jitterMs),
            packetLossPercent: percentage(measurement.packetLossPercent),
            connectionKind: connectionKind,
            wifiDetails: wifiDetails
        )
    }

    private static func projectedConnectionKind(_ kind: NetworkConnectionKind?) -> NetscopeMeasurementEvidence.ConnectionKind {
        switch kind {
        case .wifi: .wifi
        case .cellular: .cellular
        case .ethernet: .ethernet
        case .other: .other
        case nil: .unknown
        }
    }

    private static func projectedWiFiDetails(_ measurement: NetworkMeasurement) -> NetscopeMeasurementEvidence.WiFiDetails? {
        // `wifiBandGHz`, RSSI e taxa de enlace são fatos expostos pela
        // plataforma. Não usa SSID, BSSID/AP, gateway ou diagnósticos
        // importados para inferir detalhes ausentes.
        let details = NetscopeMeasurementEvidence.WiFiDetails(
            bandGHz: positiveFinite(measurement.wifiBandGHz),
            rssiDbm: finite(measurement.wifiContext?.rssiDbm),
            linkSpeedMbps: nonNegativeFinite(measurement.wifiContext?.linkSpeedMbps)
        )
        return details.hasObservedValue ? details : nil
    }

    private static func finite(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private static func nonNegativeFinite(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    private static func positiveFinite(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return value
    }

    private static func percentage(_ value: Double?) -> Double? {
        guard let value, value.isFinite, (0...100).contains(value) else { return nil }
        return value
    }
}

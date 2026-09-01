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
    /// Tempo de resolução DNS (ms) do host usado no teste — issue Expert
    /// Mode. Campo aditivo: opcional, `nil` por padrão, não muda
    /// `schemaVersion`. Uma medição antiga decodifica com `nil`, mesmo
    /// padrão de `loadedLatencyUploadMs`/`wifiBandGHz`/`durationMs`. `nil`
    /// representa falha ou timeout de resolução — nunca é normalizado para
    /// `0` (AGENTS.md §8: ausência não é zero).
    public let dnsResolutionMs: Double?
    public let durationMs: Int?
    public let connectionKind: NetworkConnectionKind?
    /// Banda Wi-Fi confirmada pelo sistema, em GHz (ex.: `2.4`, `5`) —
    /// issue #51. Só é preenchida quando a plataforma realmente informa a
    /// banda (hoje, `CoreWLAN` no Mac); nunca inferida por SSID/BSSID. `nil`
    /// é o estado normal quando a plataforma não expõe essa informação
    /// (sempre o caso no iPhone) ou quando `connectionKind` não é `.wifi`.
    public let wifiBandGHz: Double?
    /// Contexto factual da rede Wi-Fi usado nesta medição. É opcional para
    /// preservar registros antigos e medições sem autorização da plataforma.
    /// Não contém BSSID cru: `accessPointIdentifier`, quando existir, é um
    /// identificador local derivado (issue #133).
    public let wifiContext: WiFiNetworkContext?
    /// Telemetria Wi-Fi avançada importada conscientemente pelo app Atalhos.
    /// É separada de `wifiContext`, que é a leitura nativa da plataforma.
    /// Nunca contém BSSID ou MAC crus (issue #134).
    public let advancedWiFiDiagnostics: AdvancedWiFiDiagnostics?
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
        dnsResolutionMs: Double? = nil,
        durationMs: Int? = nil,
        connectionKind: NetworkConnectionKind? = nil,
        wifiBandGHz: Double? = nil,
        wifiContext: WiFiNetworkContext? = nil,
        advancedWiFiDiagnostics: AdvancedWiFiDiagnostics? = nil,
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
        self.dnsResolutionMs = dnsResolutionMs
        self.durationMs = durationMs
        self.connectionKind = connectionKind
        self.wifiBandGHz = wifiBandGHz
        self.wifiContext = wifiContext
        self.advancedWiFiDiagnostics = advancedWiFiDiagnostics
        self.networkIdentifier = networkIdentifier
        self.serverIdentifier = serverIdentifier
        self.engineVersion = engineVersion
        self.location = location
    }
}

/// Fatos sobre a rede Wi-Fi expostos publicamente pela plataforma. Campos
/// indisponíveis continuam `nil`; o contrato não infere banda, sinal ou taxa
/// de link a partir do nome da rede.
public struct WiFiNetworkContext: Codable, Equatable, Hashable, Sendable {
    public let ssid: String?
    public let accessPointIdentifier: String?
    public let securityType: WiFiSecurityType?
    public let bandGHz: Double?
    public let rssiDbm: Double?
    public let linkSpeedMbps: Double?
    public let gatewayIP: String?
    public let gatewayVendor: String?
    public let gatewayAdminURL: String?

    public init(
        ssid: String? = nil,
        accessPointIdentifier: String? = nil,
        securityType: WiFiSecurityType? = nil,
        bandGHz: Double? = nil,
        rssiDbm: Double? = nil,
        linkSpeedMbps: Double? = nil,
        gatewayIP: String? = nil,
        gatewayVendor: String? = nil,
        gatewayAdminURL: String? = nil
    ) {
        self.ssid = ssid
        self.accessPointIdentifier = accessPointIdentifier
        self.securityType = securityType
        self.bandGHz = bandGHz
        self.rssiDbm = rssiDbm
        self.linkSpeedMbps = linkSpeedMbps
        self.gatewayIP = gatewayIP
        self.gatewayVendor = gatewayVendor
        self.gatewayAdminURL = gatewayAdminURL
    }

    /// Só associa uma identidade quando o teste começou e terminou no mesmo
    /// SSID. Roaming no mesmo SSID conserva o contexto, mas marca a troca do
    /// ponto de acesso pelo identificador ausente para não escolher um deles.
    public static func resolve(
        start: WiFiNetworkContext?,
        end: WiFiNetworkContext?,
        connectionKind: NetworkConnectionKind?
    ) -> WiFiNetworkContext? {
        guard connectionKind == .wifi,
              let start,
              let end,
              let startSSID = start.ssid,
              let endSSID = end.ssid,
              startSSID == endSSID else {
            return nil
        }

        return WiFiNetworkContext(
            ssid: startSSID,
            accessPointIdentifier: start.accessPointIdentifier == end.accessPointIdentifier
                ? start.accessPointIdentifier
                : nil,
            securityType: start.securityType == end.securityType ? start.securityType : nil,
            bandGHz: start.bandGHz == end.bandGHz ? start.bandGHz : nil,
            rssiDbm: end.rssiDbm,
            linkSpeedMbps: end.linkSpeedMbps,
            gatewayIP: end.gatewayIP ?? start.gatewayIP,
            gatewayVendor: end.gatewayVendor ?? start.gatewayVendor,
            gatewayAdminURL: end.gatewayAdminURL ?? start.gatewayAdminURL
        )
    }
}

public enum WiFiSecurityType: String, Codable, Equatable, Hashable, Sendable {
    case open
    case wep
    case personal
    case enterprise
    case unknown
}

/// Fatos de Wi-Fi que o usuário escolheu importar por um atalho oficial.
/// O contrato não representa capacidade privada: campos que o Atalhos não
/// expõe permanecem ausentes, e nenhuma métrica ausente vira zero.
public struct AdvancedWiFiDiagnostics: Codable, Equatable, Hashable, Sendable {
    public static let currentSchemaVersion = 1
    public static let currentShortcutVersion = 1

    public let schemaVersion: Int
    public let shortcutVersion: Int
    public let captureIdentifier: UUID
    public let capturedAt: Date
    public let ssid: String?
    public let accessPointIdentifier: String?
    public let wifiStandard: String?
    public let rxRateMbps: Double?
    public let txRateMbps: Double?
    public let rssiDbm: Double?
    public let noiseDbm: Double?
    public let channelNumber: Int?
    public let bandGHz: Double?
    public let snrDb: Double?

    public init(
        schemaVersion: Int = AdvancedWiFiDiagnostics.currentSchemaVersion,
        shortcutVersion: Int = AdvancedWiFiDiagnostics.currentShortcutVersion,
        captureIdentifier: UUID = UUID(),
        capturedAt: Date,
        ssid: String? = nil,
        accessPointIdentifier: String? = nil,
        wifiStandard: String? = nil,
        rxRateMbps: Double? = nil,
        txRateMbps: Double? = nil,
        rssiDbm: Double? = nil,
        noiseDbm: Double? = nil,
        channelNumber: Int? = nil,
        bandGHz: Double? = nil,
        snrDb: Double? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.shortcutVersion = shortcutVersion
        self.captureIdentifier = captureIdentifier
        self.capturedAt = capturedAt
        self.ssid = ssid
        self.accessPointIdentifier = accessPointIdentifier
        self.wifiStandard = wifiStandard
        self.rxRateMbps = rxRateMbps
        self.txRateMbps = txRateMbps
        self.rssiDbm = rssiDbm
        self.noiseDbm = noiseDbm
        self.channelNumber = channelNumber
        self.bandGHz = bandGHz
        self.snrDb = snrDb
    }

    /// A faixa é inferida exclusivamente do número de canal IEEE 802.11.
    /// Canais sem mapeamento inequívoco (por exemplo 6 GHz) ficam ausentes;
    /// o Linka nunca usa SSID, RSSI ou taxa para inventar uma banda.
    public static func bandGHz(forChannel channel: Int?) -> Double? {
        guard let channel else { return nil }
        switch channel {
        case 1...14: return 2.4
        case 32...177: return 5
        default: return nil
        }
    }

    public static func snrDb(rssiDbm: Double?, noiseDbm: Double?) -> Double? {
        guard let rssiDbm, let noiseDbm,
              rssiDbm.isFinite, noiseDbm.isFinite else { return nil }
        return rssiDbm - noiseDbm
    }

    /// Janela temporal da issue #134. A captura só pode acompanhar uma
    /// medição quando cai até 30 s antes do começo, durante ela ou até 10 s
    /// depois do fim. O SSID nativo, quando ambos existem, é uma segunda
    /// proteção contra associação cruzada.
    public func isEligible(
        forMeasurementStartedAt startedAt: Date,
        endedAt: Date,
        nativeSSID: String?
    ) -> Bool {
        guard capturedAt >= startedAt.addingTimeInterval(-30),
              capturedAt <= endedAt.addingTimeInterval(10) else {
            return false
        }
        guard let ssid, let nativeSSID else { return true }
        return ssid == nativeSSID
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
            ("loadedLatencyUploadMs", measurement.loadedLatencyUploadMs),
            ("dnsResolutionMs", measurement.dnsResolutionMs)
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

        if measurement.wifiContext != nil, measurement.connectionKind != .wifi {
            result.append("wifiContext")
        }

        if let advanced = measurement.advancedWiFiDiagnostics {
            if measurement.connectionKind != .wifi {
                result.append("advancedWiFiDiagnostics")
            }
            if advanced.schemaVersion != AdvancedWiFiDiagnostics.currentSchemaVersion {
                result.append("advancedWiFiDiagnostics")
            }
            if advanced.shortcutVersion > AdvancedWiFiDiagnostics.currentShortcutVersion || advanced.shortcutVersion < 1 {
                result.append("advancedWiFiDiagnostics")
            }
            for value in [advanced.rxRateMbps, advanced.txRateMbps, advanced.rssiDbm, advanced.noiseDbm, advanced.bandGHz, advanced.snrDb] {
                if let value, !value.isFinite {
                    result.append("advancedWiFiDiagnostics")
                }
            }
            if let rxRate = advanced.rxRateMbps, rxRate < 0 { result.append("advancedWiFiDiagnostics") }
            if let txRate = advanced.txRateMbps, txRate < 0 { result.append("advancedWiFiDiagnostics") }
            if let channel = advanced.channelNumber, channel <= 0 { result.append("advancedWiFiDiagnostics") }
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

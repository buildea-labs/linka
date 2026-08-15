import Foundation
import NetworkCore

/// Traduz uma medição atual + histórico + sinais de plataforma em um
/// `DiagnosticSnapshot` schemaVersion 6. Regras:
///
/// - Nunca inventa valor. Campo não-medido vira `nil` (o worker aceita).
/// - Nunca vaza segredo ou identificador pessoal — só métricas técnicas.
/// - Determinístico e testável — sem I/O, sem relógio próprio.
public struct DiagnosticSnapshotBuilder: Sendable {
    public init() {}

    public func snapshot(
        current: NetworkMeasurement,
        history: [NetworkMeasurement],
        platform: PlatformHints,
        sessionId: String? = nil,
        appVersion: String? = nil,
        platformIdentifier: String,
        now: Date = Date()
    ) -> DiagnosticSnapshot {
        let connectionType = current.connectionKind.map(mapConnectionType(_:))
        let hasInternet = current.outcome == .complete ? true : nil

        let speed = DiagnosticSnapshot.Speed(
            downloadMbps: current.downloadMbps,
            uploadMbps: current.uploadMbps
        )
        let quality = DiagnosticSnapshot.Quality(
            latencyMs: current.latencyMs,
            jitterMs: current.jitterMs,
            packetLossPercent: current.packetLossPercent,
            loadedLatencyMs: current.loadedLatencyMs
        )

        let wifi = mapWifi(platform.wifi, connectionKind: current.connectionKind)
        let mobile = mapMobile(platform.mobile, connectionKind: current.connectionKind)
        let historical = historicalSummary(history: history, now: now)

        return DiagnosticSnapshot(
            sessionId: sessionId,
            appVersion: appVersion,
            platform: platformIdentifier,
            connection: DiagnosticSnapshot.Connection(
                type: connectionType,
                hasInternet: hasInternet,
                ipv6Available: nil
            ),
            wifi: wifi,
            speed: nullIfAllNil(speed),
            quality: nullIfAllNil(quality),
            mobile: mobile,
            historical: historical
        )
    }

    private func mapConnectionType(_ kind: NetworkConnectionKind) -> String {
        switch kind {
        case .wifi: return "wifi"
        case .cellular: return "mobile"
        case .ethernet: return "ethernet"
        case .other: return "other"
        }
    }

    private func mapWifi(
        _ hint: PlatformHints.Wifi?,
        connectionKind: NetworkConnectionKind?
    ) -> DiagnosticSnapshot.Wifi? {
        guard connectionKind == .wifi, let hint else { return nil }
        let wifi = DiagnosticSnapshot.Wifi(
            band: hint.band,
            rssiDbm: hint.rssiDbm,
            frequencyMhz: nil,
            linkSpeedMbps: hint.linkSpeedMbps
        )
        return nullIfAllNil(wifi)
    }

    private func mapMobile(
        _ hint: PlatformHints.Mobile?,
        connectionKind: NetworkConnectionKind?
    ) -> DiagnosticSnapshot.Mobile? {
        guard connectionKind == .cellular, let hint else { return nil }
        let mobile = DiagnosticSnapshot.Mobile(
            technology: hint.technology,
            operatorName: hint.operatorName
        )
        return nullIfAllNil(mobile)
    }

    private func historicalSummary(
        history: [NetworkMeasurement],
        now: Date
    ) -> DiagnosticSnapshot.Historical? {
        guard !history.isEmpty else { return nil }

        let cutoff7d = now.addingTimeInterval(-7 * 86_400)
        let cutoff30d = now.addingTimeInterval(-30 * 86_400)
        let last7 = history.filter { $0.measuredAt >= cutoff7d }
        let last30 = history.filter { $0.measuredAt >= cutoff30d }

        let historical = DiagnosticSnapshot.Historical(
            testsCount7d: last7.isEmpty ? nil : last7.count,
            testsCount30d: last30.isEmpty ? nil : last30.count,
            avgDownload7d: average(last7.compactMap(\.downloadMbps)),
            avgDownload30d: average(last30.compactMap(\.downloadMbps)),
            avgUpload7d: average(last7.compactMap(\.uploadMbps)),
            avgUpload30d: average(last30.compactMap(\.uploadMbps)),
            avgPing7d: average(last7.compactMap(\.latencyMs)),
            avgPing30d: average(last30.compactMap(\.latencyMs))
        )
        return nullIfAllNil(historical)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

private func nullIfAllNil(_ value: DiagnosticSnapshot.Speed) -> DiagnosticSnapshot.Speed? {
    (value.downloadMbps == nil && value.uploadMbps == nil) ? nil : value
}

private func nullIfAllNil(_ value: DiagnosticSnapshot.Quality) -> DiagnosticSnapshot.Quality? {
    let all: [Double?] = [value.latencyMs, value.jitterMs, value.packetLossPercent, value.loadedLatencyMs]
    return all.allSatisfy { $0 == nil } ? nil : value
}

private func nullIfAllNil(_ value: DiagnosticSnapshot.Wifi) -> DiagnosticSnapshot.Wifi? {
    let all: [Any?] = [value.band, value.rssiDbm, value.frequencyMhz, value.linkSpeedMbps]
    return all.allSatisfy { $0 == nil } ? nil : value
}

private func nullIfAllNil(_ value: DiagnosticSnapshot.Mobile) -> DiagnosticSnapshot.Mobile? {
    (value.technology == nil && value.operatorName == nil) ? nil : value
}

private func nullIfAllNil(_ value: DiagnosticSnapshot.Historical) -> DiagnosticSnapshot.Historical? {
    let all: [Any?] = [
        value.testsCount7d, value.testsCount30d,
        value.avgDownload7d, value.avgDownload30d,
        value.avgUpload7d, value.avgUpload30d,
        value.avgPing7d, value.avgPing30d
    ]
    return all.allSatisfy { $0 == nil } ? nil : value
}

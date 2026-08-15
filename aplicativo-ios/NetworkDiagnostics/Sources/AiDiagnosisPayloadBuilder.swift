import Foundation
import NetworkCore

/// Monta o payload PT-BR aceito pelo `ai-diagnosis-worker`. Espelha o que o
/// app SignallQ Android envia (`connectionType`, `metricasAtuais`, `historico`,
/// `wifi`, `movel`, `feedbackUsuario`), para reaproveitar o mesmo prompt e
/// comportamento do modelo.
public struct AiDiagnosisPayloadBuilder: Sendable {
    public init() {}

    public func payload(
        question: String,
        current: NetworkMeasurement,
        history: [NetworkMeasurement],
        platform: PlatformHints,
        appVersion: String?,
        platformIdentifier: String,
        now: Date = Date()
    ) -> AiDiagnosisPayload {
        AiDiagnosisPayload(
            connectionType: current.connectionKind.map(mapConnectionType(_:)),
            appVersion: appVersion,
            plataforma: platformIdentifier,
            metricasAtuais: AiDiagnosisPayload.Metricas(
                downloadMbps: current.downloadMbps,
                uploadMbps: current.uploadMbps,
                latenciaMs: current.latencyMs,
                jitterMs: current.jitterMs,
                perdaPacotes: current.packetLossPercent,
                bufferbloatMs: current.loadedLatencyMs
            ),
            historico: historico(history: history, now: now),
            wifi: mapWifi(platform.wifi, kind: current.connectionKind),
            movel: mapMovel(platform.mobile, kind: current.connectionKind),
            feedbackUsuario: question.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func historico(
        history: [NetworkMeasurement],
        now: Date
    ) -> AiDiagnosisPayload.Historico? {
        guard !history.isEmpty else { return nil }
        let cutoff7d = now.addingTimeInterval(-7 * 86_400)
        let cutoff30d = now.addingTimeInterval(-30 * 86_400)
        let last7 = history.filter { $0.measuredAt >= cutoff7d }
        let last30 = history.filter { $0.measuredAt >= cutoff30d }

        let hist = AiDiagnosisPayload.Historico(
            qtdTestes7d: last7.isEmpty ? nil : last7.count,
            qtdTestes30d: last30.isEmpty ? nil : last30.count,
            mediaDownload7d: average(last7.compactMap(\.downloadMbps)),
            mediaUpload7d: average(last7.compactMap(\.uploadMbps)),
            mediaLatencia7d: average(last7.compactMap(\.latencyMs))
        )
        let all: [Any?] = [
            hist.qtdTestes7d, hist.qtdTestes30d,
            hist.mediaDownload7d, hist.mediaUpload7d, hist.mediaLatencia7d
        ]
        return all.allSatisfy { $0 == nil } ? nil : hist
    }

    private func mapWifi(
        _ hint: PlatformHints.Wifi?,
        kind: NetworkConnectionKind?
    ) -> AiDiagnosisPayload.Wifi? {
        guard kind == .wifi, let hint else { return nil }
        let wifi = AiDiagnosisPayload.Wifi(
            ssid: hint.ssid,
            bssid: hint.bssid,
            rssiDbm: hint.rssiDbm,
            banda: hint.band
        )
        let all: [Any?] = [wifi.ssid, wifi.bssid, wifi.rssiDbm, wifi.banda]
        return all.allSatisfy { $0 == nil } ? nil : wifi
    }

    private func mapMovel(
        _ hint: PlatformHints.Mobile?,
        kind: NetworkConnectionKind?
    ) -> AiDiagnosisPayload.Movel? {
        guard kind == .cellular, let hint else { return nil }
        let movel = AiDiagnosisPayload.Movel(
            tecnologia: hint.technology,
            operadora: hint.operatorName
        )
        return (movel.tecnologia == nil && movel.operadora == nil) ? nil : movel
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

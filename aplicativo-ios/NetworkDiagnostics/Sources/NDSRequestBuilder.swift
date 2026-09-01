import Foundation
import NetworkCore

public struct NDSRequestBuilder: Sendable {
    public init() {}

    public func buildRequest(
        current: NetworkMeasurement,
        platformHints: PlatformHints,
        appVersion: String?,
        platformIdentifier: String,
        requestAI: Bool,
        diagnosticContext: NDSRequest.DiagnosticContext? = nil,
        historical: NDSRequest.Historical? = nil
    ) -> NDSRequest {
        var capabilities: [String] = []
        if (platformHints.wifi != nil || current.advancedWiFiDiagnostics != nil), current.connectionKind == .wifi {
            capabilities.append("wifi")
        }
        if historical != nil {
            capabilities.append("historical")
        }

        let hasInternet: Bool? = (current.latencyMs != nil || current.downloadMbps != nil) ? true : nil
        let bandStr: String? = current.wifiBandGHz.map { String($0) }

        return NDSRequest(
            schemaVersion: "1.0",
            request_id: UUID().uuidString,
            sessionId: current.id.uuidString,
            platform: platformIdentifier,
            locale: Locale.current.language.languageCode?.identifier ?? "en",
            app: NDSRequest.AppInfo(id: "linka", version: appVersion),
            capabilities: capabilities,
            requestedOutputs: requestAI ? ["scoring", "ai"] : ["scoring"],
            context: diagnosticContext,
            connection: mapConnection(current.connectionKind, hasInternet: hasInternet),
            wifi: mapWifi(platformHints.wifi, advanced: current.advancedWiFiDiagnostics, kind: current.connectionKind, band: bandStr),
            // `speed: {}` (objeto presente, campos vazios) é rejeitado pelo
            // relay do NDS com RELAY_INVALID_REQUEST — confirmado testando
            // o payload real contra o serviço em produção (issue #129).
            // Um teste que aborta antes do download/upload (outcome
            // .partial) chega aqui com as duas velocidades nil; omitir a
            // chave inteira (em vez de mandar o objeto vazio) é o mesmo
            // "dado ausente permanece ausente" já aplicado a `wifi` e
            // `connection` acima, e é o único formato que o relay aceita.
            speed: (current.downloadMbps != nil || current.uploadMbps != nil)
                ? NDSRequest.Speed(downloadMbps: current.downloadMbps, uploadMbps: current.uploadMbps)
                : nil,
            quality: NDSRequest.Quality(
                latencyMs: current.latencyMs,
                loadedLatencyMs: current.loadedLatencyMs,
                jitterMs: current.jitterMs,
                packetLossPercent: current.packetLossPercent
            ),
            historical: historical
        )
    }

    private func mapConnection(_ kind: NetworkConnectionKind?, hasInternet: Bool?) -> NDSRequest.Connection? {
        guard let kind = kind else { return nil }
        let typeStr: String
        switch kind {
        case .wifi: typeStr = "wifi"
        case .cellular: typeStr = "cellular"
        case .ethernet: typeStr = "ethernet"
        case .other: typeStr = "other"
        }
        return NDSRequest.Connection(type: typeStr, hasInternet: hasInternet)
    }

    private func mapWifi(_ hint: PlatformHints.Wifi?, advanced: AdvancedWiFiDiagnostics?, kind: NetworkConnectionKind?, band: String?) -> NDSRequest.Wifi? {
        guard kind == .wifi else { return nil }
        guard hint != nil || advanced != nil else { return nil }
        let rssi = advanced?.rssiDbm ?? hint?.rssiDbm
        let linkSpeed = advanced?.txRateMbps ?? advanced?.rxRateMbps ?? hint?.linkSpeedMbps
        return NDSRequest.Wifi(
            rssiDbm: rssi,
            linkSpeedMbps: linkSpeed,
            band: band
        )
    }
}

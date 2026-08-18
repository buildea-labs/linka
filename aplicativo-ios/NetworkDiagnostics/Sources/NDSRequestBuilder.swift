import Foundation
import NetworkCore

public struct NDSRequestBuilder: Sendable {
    public init() {}

    public func buildRequest(
        current: NetworkMeasurement,
        platformHints: PlatformHints,
        appVersion: String?,
        platformIdentifier: String,
        requestAI: Bool
    ) -> NDSRequest {
        var capabilities: [String] = ["scoring"]
        if requestAI {
            capabilities.append("ai")
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
            connection: mapConnection(current.connectionKind, hasInternet: hasInternet),
            wifi: mapWifi(platformHints.wifi, kind: current.connectionKind, band: bandStr),
            speed: NDSRequest.Speed(downloadMbps: current.downloadMbps, uploadMbps: current.uploadMbps),
            quality: NDSRequest.Quality(
                latencyMs: current.latencyMs,
                loadedLatencyMs: current.loadedLatencyMs,
                jitterMs: current.jitterMs,
                packetLossPercent: current.packetLossPercent
            )
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

    private func mapWifi(_ hint: PlatformHints.Wifi?, kind: NetworkConnectionKind?, band: String?) -> NDSRequest.Wifi? {
        guard kind == .wifi, let hint = hint else { return nil }
        return NDSRequest.Wifi(
            rssiDbm: hint.rssiDbm,
            linkSpeedMbps: hint.linkSpeedMbps,
            band: band
        )
    }
}

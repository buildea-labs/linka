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
        var capabilities: [String] = []
        if requestAI {
            capabilities.append("ai")
        }

        return NDSRequest(
            sessionId: current.id.uuidString,
            request_id: UUID().uuidString,
            platform: platformIdentifier,
            app: NDSRequest.AppInfo(id: "linka", version: appVersion),
            capabilities: capabilities,
            connection: mapConnection(current.connectionKind),
            wifi: mapWifi(platformHints.wifi, kind: current.connectionKind),
            speed: NDSRequest.Speed(downloadMbps: current.downloadMbps, uploadMbps: current.uploadMbps),
            quality: NDSRequest.Quality(
                latencyMs: current.latencyMs,
                loadedLatencyMs: current.loadedLatencyMs,
                packetLossPercent: current.packetLossPercent
            )
        )
    }

    private func mapConnection(_ kind: NetworkConnectionKind?) -> NDSRequest.Connection? {
        guard let kind = kind else { return nil }
        let typeStr: String
        switch kind {
        case .wifi: typeStr = "wifi"
        case .cellular: typeStr = "cellular"
        case .ethernet: typeStr = "ethernet"
        case .other: typeStr = "other"
        }
        return NDSRequest.Connection(type: typeStr, status: "connected")
    }

    private func mapWifi(_ hint: PlatformHints.Wifi?, kind: NetworkConnectionKind?) -> NDSRequest.Wifi? {
        guard kind == .wifi, let hint = hint else { return nil }
        // Se `band` puder ser mapeado para double, faça. Por hora, enviamos nil.
        return NDSRequest.Wifi(
            rssi: hint.rssiDbm,
            frequency: nil,
            standard: nil, // Linka não coleta standard publicamente
            linkSpeed: hint.linkSpeedMbps
        )
    }
}

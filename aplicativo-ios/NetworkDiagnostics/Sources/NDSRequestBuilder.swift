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
            locale: Locale.current.language.languageCode?.identifier ?? "pt",
            app: NDSRequest.AppInfo(id: "linka", version: appVersion ?? "1.0.0"),
            capabilities: capabilities,
            requestedOutputs: requestAI ? ["scoring", "ai"] : ["scoring"],
            context: diagnosticContext,
            connection: mapConnection(current.connectionKind, hasInternet: hasInternet),
            wifi: mapWifi(platformHints.wifi, context: current.wifiContext, advanced: current.advancedWiFiDiagnostics, kind: current.connectionKind, band: bandStr),
            speed: mapSpeed(downloadMbps: current.downloadMbps, uploadMbps: current.uploadMbps),
            quality: mapQuality(
                latencyMs: current.latencyMs,
                loadedLatencyMs: current.loadedLatencyMs,
                loadedLatencyUploadMs: current.loadedLatencyUploadMs,
                dnsResolutionMs: current.dnsResolutionMs,
                jitterMs: current.jitterMs,
                packetLossPercent: current.packetLossPercent
            ),
            historical: historical
        )
    }

    private func mapSpeed(downloadMbps: Double?, uploadMbps: Double?) -> NDSRequest.Speed? {
        let validDownload = downloadMbps.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validUpload = uploadMbps.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }

        guard validDownload != nil || validUpload != nil else { return nil }
        return NDSRequest.Speed(downloadMbps: validDownload, uploadMbps: validUpload)
    }

    private func mapQuality(
        latencyMs: Double?,
        loadedLatencyMs: Double?,
        loadedLatencyUploadMs: Double?,
        dnsResolutionMs: Double?,
        jitterMs: Double?,
        packetLossPercent: Double?
    ) -> NDSRequest.Quality? {
        let validLatency = latencyMs.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validLoaded = loadedLatencyMs.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validLoadedUpload = loadedLatencyUploadMs.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validDns = dnsResolutionMs.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validJitter = jitterMs.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let validLoss = packetLossPercent.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }

        guard validLatency != nil || validLoaded != nil || validLoadedUpload != nil || validDns != nil || validJitter != nil || validLoss != nil else {
            return nil
        }
        return NDSRequest.Quality(
            latencyMs: validLatency,
            loadedLatencyMs: validLoaded,
            loadedLatencyUploadMs: validLoadedUpload,
            dnsResolutionMs: validDns,
            jitterMs: validJitter,
            packetLossPercent: validLoss
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

    private func mapWifi(_ hint: PlatformHints.Wifi?, context: WiFiNetworkContext?, advanced: AdvancedWiFiDiagnostics?, kind: NetworkConnectionKind?, band: String?) -> NDSRequest.Wifi? {
        guard kind == .wifi else { return nil }
        let rssi = advanced?.rssiDbm ?? context?.rssiDbm ?? hint?.rssiDbm
        let linkSpeed = advanced?.txRateMbps ?? advanced?.rxRateMbps ?? context?.linkSpeedMbps ?? hint?.linkSpeedMbps
        
        let validBand = band ?? context?.bandGHz.map { String($0) } ?? advanced?.bandGHz.map { String($0) }
        
        guard rssi != nil || linkSpeed != nil || validBand != nil || context != nil || advanced != nil else { return nil }
        
        return NDSRequest.Wifi(
            rssiDbm: rssi,
            linkSpeedMbps: linkSpeed,
            band: validBand,
            securityType: context?.securityType?.rawValue,
            rxRateMbps: advanced?.rxRateMbps,
            txRateMbps: advanced?.txRateMbps,
            noiseDbm: advanced?.noiseDbm,
            snrDb: advanced?.snrDb,
            channelNumber: advanced?.channelNumber,
            gatewayIP: context?.gatewayIP,
            gatewayVendor: context?.gatewayVendor,
            gatewayAdminURL: context?.gatewayAdminURL
        )
    }
}

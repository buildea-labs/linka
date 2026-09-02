import Foundation
import NetworkCore
import NetworkInsights

public enum WiFiBandRecommendationTarget: Double, Codable, Equatable, Sendable {
    case band5GHz = 5.0
    case band6GHz = 6.0
}

public enum WiFiBandRecommendationAction: Equatable, Sendable {
    case switchBand(target: WiFiBandRecommendationTarget)
}

public enum WiFiBandRecommendationReason: String, Codable, Equatable, Sendable {
    case historicallyBetterOn5GHz
    case historicallyBetterOn6GHz
}

public struct WiFiBandRecommendation: Equatable, Sendable {
    public let currentBand: Double?
    public let action: WiFiBandRecommendationAction?
    public let reason: WiFiBandRecommendationReason?
    public let isEvidenceSufficient: Bool
    
    public init(
        currentBand: Double?,
        action: WiFiBandRecommendationAction?,
        reason: WiFiBandRecommendationReason?,
        isEvidenceSufficient: Bool
    ) {
        self.currentBand = currentBand
        self.action = action
        self.reason = reason
        self.isEvidenceSufficient = isEvidenceSufficient
    }
}

public struct WiFiBandRecommendationEvaluator {
    public let minimumGoodSignalDbm: Double

    public init(minimumGoodSignalDbm: Double = -70) {
        self.minimumGoodSignalDbm = minimumGoodSignalDbm
    }

    public func evaluate(
        measurement: NetworkMeasurement,
        historicalMeasurements: [NetworkMeasurement] = []
    ) -> WiFiBandRecommendation {
        guard measurement.connectionKind == .wifi else {
            return WiFiBandRecommendation(currentBand: nil, action: nil, reason: nil, isEvidenceSufficient: false)
        }

        let currentBand = measurement.wifiBandGHz ?? measurement.advancedWiFiDiagnostics?.bandGHz ?? measurement.wifiContext?.bandGHz
        let rssi = measurement.advancedWiFiDiagnostics?.rssiDbm ?? measurement.wifiContext?.rssiDbm
        let download = measurement.downloadMbps
        
        guard let currentBand, let rssi, let download else {
            return WiFiBandRecommendation(currentBand: currentBand, action: nil, reason: nil, isEvidenceSufficient: false)
        }
        
        guard let currentSSID = measurement.wifiContext?.ssid, !currentSSID.isEmpty else {
            return WiFiBandRecommendation(currentBand: currentBand, action: nil, reason: nil, isEvidenceSufficient: false)
        }
        
        // Filter history by same SSID
        let sameNetworkHistory = historicalMeasurements.filter { hist in
            hist.connectionKind == .wifi && hist.wifiContext?.ssid == currentSSID
        }
        
        func medianDownload(for band: Double) -> Double? {
            let values = sameNetworkHistory.compactMap { hist -> Double? in
                let histBand = hist.wifiBandGHz ?? hist.advancedWiFiDiagnostics?.bandGHz ?? hist.wifiContext?.bandGHz
                if histBand == band, let speed = hist.downloadMbps {
                    return speed
                }
                return nil
            }.sorted()
            
            guard !values.isEmpty else { return nil }
            let count = values.count
            if count % 2 == 0 {
                return (values[count/2 - 1] + values[count/2]) / 2.0
            } else {
                return values[count/2]
            }
        }
        
        let median5GHz = medianDownload(for: 5.0)
        let median6GHz = medianDownload(for: 6.0)
        
        switch currentBand {
        case 2.4:
            if rssi > minimumGoodSignalDbm {
                if let m5 = median5GHz, m5 > download * 1.2 { // At least 20% better historically
                    return WiFiBandRecommendation(
                        currentBand: currentBand,
                        action: .switchBand(target: .band5GHz),
                        reason: .historicallyBetterOn5GHz,
                        isEvidenceSufficient: true
                    )
                }
            }
            return WiFiBandRecommendation(currentBand: currentBand, action: nil, reason: nil, isEvidenceSufficient: true)
            
        case 5.0:
            if let m6 = median6GHz, m6 > download * 1.2 {
                return WiFiBandRecommendation(
                    currentBand: currentBand,
                    action: .switchBand(target: .band6GHz),
                    reason: .historicallyBetterOn6GHz,
                    isEvidenceSufficient: true
                )
            }
            return WiFiBandRecommendation(currentBand: currentBand, action: nil, reason: nil, isEvidenceSufficient: true)
            
        default:
            return WiFiBandRecommendation(currentBand: currentBand, action: nil, reason: nil, isEvidenceSufficient: true)
        }
    }
}

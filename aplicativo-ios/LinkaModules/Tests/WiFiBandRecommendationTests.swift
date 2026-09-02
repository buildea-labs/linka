import XCTest
import NetworkCore
@testable import LinkaModules

final class WiFiBandRecommendationTests: XCTestCase {
    
    private func createMeasurement(
        band: Double?,
        rssi: Double?,
        download: Double?,
        ssid: String? = "MyWiFi"
    ) -> NetworkMeasurement {
        return NetworkMeasurement(
            downloadMbps: download,
            connectionKind: .wifi,
            wifiBandGHz: band,
            wifiContext: WiFiNetworkContext(ssid: ssid, rssiDbm: rssi)
        )
    }

    func test2_4GHzWithGoodCoverageLimitationAnd5GHzConfirmedBetter() {
        let evaluator = WiFiBandRecommendationEvaluator()
        let current = createMeasurement(band: 2.4, rssi: -60, download: 50)
        let hist1 = createMeasurement(band: 5.0, rssi: -60, download: 200)
        
        let result = evaluator.evaluate(measurement: current, historicalMeasurements: [hist1])
        
        XCTAssertEqual(result.action, .switchBand(target: .band5GHz))
        XCTAssertEqual(result.reason, .historicallyBetterOn5GHz)
        XCTAssertTrue(result.isEvidenceSufficient)
    }

    func test2_4GHzWithWeakSignal() {
        let evaluator = WiFiBandRecommendationEvaluator()
        let current = createMeasurement(band: 2.4, rssi: -80, download: 10)
        let hist = createMeasurement(band: 5.0, rssi: -60, download: 200)
        
        let result = evaluator.evaluate(measurement: current, historicalMeasurements: [hist])
        
        XCTAssertNil(result.action)
        XCTAssertTrue(result.isEvidenceSufficient)
    }
}

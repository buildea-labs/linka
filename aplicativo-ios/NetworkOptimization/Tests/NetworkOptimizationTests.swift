import XCTest
@testable import NetworkOptimization
import NetworkCore

final class NetworkOptimizationTests: XCTestCase {
    func testBuildsDeterministicLoadOpportunity() {
        let measurement = sample(latency: 20, loaded: 150)
        let plan = OptimizationPlanBuilder().build(baseline: measurement, history: [])
        XCTAssertEqual(plan.opportunities.first?.kind, .responsivenessUnderLoad)
        XCTAssertEqual(plan.opportunities.first?.action, .reduceConcurrentUse)
    }

    func testDoesNotInventHistoryWithoutConfirmedIdentity() {
        let measurement = sample(latency: 80, loaded: nil, ssid: nil)
        let history = (0..<4).map { _ in sample(latency: 20, loaded: nil, ssid: nil) }
        XCTAssertTrue(OptimizationPlanBuilder().build(baseline: measurement, history: history).opportunities.isEmpty)
    }

    func testLimitsPlanToThreeOpportunities() {
        let measurement = sample(latency: 100, loaded: 240, jitter: 30, loss: 5)
        let history = (0..<3).map { _ in sample(latency: 20, loaded: nil) }
        XCTAssertEqual(OptimizationPlanBuilder().build(baseline: measurement, history: history).opportunities.count, 3)
    }

    private func sample(latency: Double, loaded: Double?, jitter: Double? = nil, loss: Double? = nil, ssid: String? = "Casa") -> NetworkMeasurement {
        NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            latencyMs: latency,
            jitterMs: jitter,
            packetLossPercent: loss,
            loadedLatencyMs: loaded,
            connectionKind: .wifi,
            wifiContext: WiFiNetworkContext(ssid: ssid)
        )
    }
}

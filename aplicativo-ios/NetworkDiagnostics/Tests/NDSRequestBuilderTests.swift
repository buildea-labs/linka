import XCTest
@testable import NetworkDiagnostics
import NetworkCore

final class NDSRequestBuilderTests: XCTestCase {
    func testBuildRequest() {
        let builder = NDSRequestBuilder()
        let measurement = NetworkMeasurement(
            id: UUID(),
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20,
            connectionKind: .wifi
        )
        let hints = PlatformHints(wifi: PlatformHints.Wifi(rssiDbm: -50, linkSpeedMbps: 866))
        
        let request = builder.buildRequest(current: measurement, platformHints: hints, appVersion: "1.0.0", platformIdentifier: "ios", requestAI: true)
        
        XCTAssertEqual(request.sessionId, measurement.id.uuidString)
        XCTAssertEqual(request.platform, "ios")
        XCTAssertEqual(request.app?.version, "1.0.0")
        XCTAssertEqual(request.capabilities, ["scoring", "ai"])
        XCTAssertEqual(request.connection?.type, "wifi")
        XCTAssertEqual(request.wifi?.rssiDbm, -50)
        XCTAssertEqual(request.speed?.downloadMbps, 100)
    }
}

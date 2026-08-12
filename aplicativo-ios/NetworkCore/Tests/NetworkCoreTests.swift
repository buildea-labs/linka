import XCTest
@testable import NetworkCore

final class NetworkCoreTests: XCTestCase {
    func testCompleteMeasurementRequiresCoreMetrics() {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 500,
            uploadMbps: 100,
            latencyMs: 12
        )

        XCTAssertTrue(NetworkMeasurementContract.isValid(measurement))
    }

    func testPartialMeasurementRequiresAtLeastOneMetric() {
        XCTAssertFalse(NetworkMeasurementContract.isValid(NetworkMeasurement()))
        XCTAssertTrue(NetworkMeasurementContract.isValid(NetworkMeasurement(latencyMs: 15)))
    }

    func testInvalidRangesAreRejected() {
        let measurement = NetworkMeasurement(
            downloadMbps: -1,
            packetLossPercent: 101
        )

        let violations = NetworkMeasurementContract.violations(for: measurement)
        XCTAssertTrue(violations.contains("downloadMbps"))
        XCTAssertTrue(violations.contains("packetLossPercent"))
    }

    func testMeasurementRoundTripsThroughJSON() throws {
        let original = NetworkMeasurement(
            id: UUID(uuidString: "4A5F9B63-E4F4-4D90-904F-3E618FC92C32")!,
            measuredAt: Date(timeIntervalSince1970: 1_786_428_000),
            outcome: .complete,
            downloadMbps: 512.4,
            uploadMbps: 104.8,
            latencyMs: 11.7,
            connectionKind: .wifi,
            serverIdentifier: "cloudflare"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NetworkMeasurement.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}

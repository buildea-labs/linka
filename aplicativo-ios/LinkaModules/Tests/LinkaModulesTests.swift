import XCTest
@testable import LinkaModules

final class LinkaModulesTests: XCTestCase {
    func testFreeTierOnlyIncludesSpeedTest() {
        XCTAssertEqual(LinkaAccessPolicy.capabilities(for: .free), [.speedTest])
        XCTAssertTrue(LinkaAccessPolicy.hasAccess(to: .speedTest, on: .free))
        XCTAssertFalse(LinkaAccessPolicy.hasAccess(to: .history, on: .free))
        XCTAssertFalse(LinkaAccessPolicy.hasAccess(to: .insights, on: .free))
        XCTAssertFalse(LinkaAccessPolicy.hasAccess(to: .assist, on: .free))
        XCTAssertFalse(LinkaAccessPolicy.hasAccess(to: .appleIntegrations, on: .free))
    }

    func testPlusTierIncludesAllCapabilities() {
        XCTAssertEqual(
            LinkaAccessPolicy.capabilities(for: .plus),
            Set(LinkaCapability.allCases)
        )
    }

    func testHistoryReturnsNewestMeasurementsFirst() async throws {
        let older = NetworkMeasurement(
            measuredAt: Date(timeIntervalSince1970: 100),
            downloadMbps: 100
        )
        let newer = NetworkMeasurement(
            measuredAt: Date(timeIntervalSince1970: 200),
            downloadMbps: 200
        )
        let store = InMemoryHistoryStore()

        try await store.save(older)
        try await store.save(newer)

        let measurements = try await store.recent(limit: 2)
        XCTAssertEqual(measurements.map(\.id), [newer.id, older.id])
    }

    func testInsightProviderCalculatesRelativeDeltaWithoutDiagnosis() async {
        let baseline = NetworkMeasurement(
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let current = NetworkMeasurement(
            downloadMbps: 120,
            uploadMbps: 40,
            latencyMs: 30
        )

        let comparison = await BasicInsightProvider().compare(
            current: current,
            against: baseline
        )

        XCTAssertEqual(comparison.delta.downloadPercent ?? 0, 20, accuracy: 0.001)
        XCTAssertEqual(comparison.delta.uploadPercent ?? 0, -20, accuracy: 0.001)
        XCTAssertEqual(comparison.delta.latencyPercent ?? 0, 50, accuracy: 0.001)
    }

    func testUnconfiguredAssistTransportFailsClosed() async {
        let context = AssistContext(
            question: "Minha velocidade mudou?",
            currentMeasurement: NetworkMeasurement(downloadMbps: 100)
        )
        let provider = TransportBackedAssistProvider(
            transport: UnconfiguredAssistTransport()
        )

        do {
            _ = try await provider.answer(context)
            XCTFail("Expected AssistError.notConfigured")
        } catch let error as AssistError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCompleteMeasurementRequiresCoreMetrics() {
        let complete = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 500,
            uploadMbps: 100,
            latencyMs: 12
        )

        XCTAssertTrue(NetworkMeasurementContract.isValid(complete))
    }

    func testCompleteMeasurementRejectsMissingCoreMetric() {
        let incomplete = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 500,
            latencyMs: 12
        )

        XCTAssertFalse(NetworkMeasurementContract.isValid(incomplete))
        XCTAssertTrue(NetworkMeasurementContract.violations(for: incomplete).contains("uploadMbps"))
    }

    func testPartialMeasurementNeedsAtLeastOneMeasuredMetric() {
        XCTAssertFalse(NetworkMeasurementContract.isValid(NetworkMeasurement()))
        XCTAssertTrue(NetworkMeasurementContract.isValid(NetworkMeasurement(latencyMs: 18)))
    }

    func testContractRejectsInvalidMetricRanges() {
        let invalid = NetworkMeasurement(
            downloadMbps: -1,
            packetLossPercent: 101
        )

        let violations = NetworkMeasurementContract.violations(for: invalid)
        XCTAssertTrue(violations.contains("downloadMbps"))
        XCTAssertTrue(violations.contains("packetLossPercent"))
    }

    func testCanonicalMeasurementRoundTripsAsISO8601JSON() throws {
        let original = NetworkMeasurement(
            id: UUID(uuidString: "4A5F9B63-E4F4-4D90-904F-3E618FC92C32")!,
            measuredAt: Date(timeIntervalSince1970: 1_786_428_000),
            outcome: .complete,
            downloadMbps: 512.4,
            uploadMbps: 104.8,
            latencyMs: 11.7,
            jitterMs: 1.9,
            connectionKind: .wifi,
            serverIdentifier: "cloudflare",
            engineVersion: "linka-engine-v1"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NetworkMeasurement.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.schemaVersion, NetworkMeasurementContract.currentSchemaVersion)
    }
}

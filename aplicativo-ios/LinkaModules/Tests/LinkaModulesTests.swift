import XCTest
@testable import LinkaModules
import LinkaEntitlements
import NetworkAssist
import NetworkInsights

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

    func testHistoryCompatibilityUsesStandaloneRepository() async throws {
        let older = NetworkMeasurement(
            measuredAt: Date(timeIntervalSince1970: 100),
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let newer = NetworkMeasurement(
            measuredAt: Date(timeIntervalSince1970: 200),
            outcome: .complete,
            downloadMbps: 200,
            uploadMbps: 50,
            latencyMs: 20
        )
        let store = InMemoryHistoryStore()

        try await store.save(older)
        try await store.save(newer)

        let measurements = try await store.measurements(
            matching: .init(limit: 2)
        )
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

    func testPartialMeasurementNeedsAtLeastOneMeasuredMetric() {
        XCTAssertFalse(NetworkMeasurementContract.isValid(NetworkMeasurement()))
        XCTAssertTrue(NetworkMeasurementContract.isValid(NetworkMeasurement(latencyMs: 18)))
    }

    // MARK: - EntitlementGatedNetworkInsightsAnalyzer

    func testEntitlementGatedInsightsDeniesFreePlan() {
        let gated = EntitlementGatedNetworkInsightsAnalyzer(
            wrapping: BasicNetworkInsightsAnalyzer(),
            snapshot: .free
        )

        XCTAssertThrowsError(
            try gated.summarize([NetworkMeasurement(downloadMbps: 100)])
        ) { error in
            XCTAssertEqual(error as? NetworkInsightsError, .notEntitled)
        }
    }

    func testEntitlementGatedInsightsDelegatesForActivePlus() throws {
        let gated = EntitlementGatedNetworkInsightsAnalyzer(
            wrapping: BasicNetworkInsightsAnalyzer(),
            snapshot: .plus(status: .active, source: .subscription)
        )

        let summary = try gated.summarize([
            NetworkMeasurement(downloadMbps: 100),
            NetworkMeasurement(downloadMbps: 120)
        ])

        XCTAssertEqual(summary.measurementCount, 2)
    }

    // MARK: - EntitlementGatedNetworkAssistProvider

    func testEntitlementGatedAssistDeniesFreePlanWithoutCallingTheWrappedProvider() async {
        let gated = EntitlementGatedNetworkAssistProvider(
            wrapping: NetworkAssistService(transport: UnconfiguredNetworkAssistTransport()),
            snapshot: { .free }
        )

        let context = NetworkAssistContext(
            question: "Minha conexão está boa?",
            currentMeasurement: NetworkMeasurement(downloadMbps: 100)
        )

        do {
            _ = try await gated.answer(context)
            XCTFail("Expected NetworkAssistError.notEntitled")
        } catch let error as NetworkAssistError {
            // .notEntitled, não .notConfigured — o gate de plano roda antes
            // do transport, então a ausência de transport nunca é observada
            // para um usuário sem direito ao Assist.
            XCTAssertEqual(error, .notEntitled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEntitlementGatedAssistDelegatesForActivePlus() async {
        let gated = EntitlementGatedNetworkAssistProvider(
            wrapping: NetworkAssistService(transport: UnconfiguredNetworkAssistTransport()),
            snapshot: { .plus(status: .active, source: .subscription) }
        )

        let context = NetworkAssistContext(
            question: "Minha conexão está boa?",
            currentMeasurement: NetworkMeasurement(downloadMbps: 100)
        )

        do {
            _ = try await gated.answer(context)
            XCTFail("Expected NetworkAssistError.notConfigured (delegated to the wrapped transport)")
        } catch let error as NetworkAssistError {
            // Plano Plus passa pelo gate; o erro observado é o do transport
            // real (não configurado neste teste), confirmando delegação.
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

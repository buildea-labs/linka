import XCTest
@testable import LinkaWidgetShared

final class LinkaWidgetSharedTests: XCTestCase {
    private let testSuiteName = "LinkaWidgetSharedTests.suite"
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: testSuiteName)
        testDefaults.removePersistentDomain(forName: testSuiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        super.tearDown()
    }

    func testWriteThenReadRoundTrips() {
        let summary = LinkaWidgetShared.LatestMeasurementSummary(
            downloadMbps: 123.4,
            uploadMbps: 45.6,
            latencyMs: 12,
            measuredAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        LinkaWidgetShared.writeLatestSummary(summary, userDefaults: testDefaults)
        let read = LinkaWidgetShared.readLatestSummary(userDefaults: testDefaults)

        XCTAssertEqual(read, summary)
    }

    func testReadWithoutPriorWriteReturnsNil() {
        XCTAssertNil(LinkaWidgetShared.readLatestSummary(userDefaults: testDefaults))
    }

    /// Simula o App Group ainda não provisionado no Apple Developer Portal
    /// (mesma pendência de conta documentada em
    /// `LinkaWidgetShared.appGroupIdentifier`) — leitura deve virar `nil`,
    /// nunca crash.
    func testReadWithUnavailableAppGroupReturnsNilInsteadOfCrashing() {
        XCTAssertNil(LinkaWidgetShared.readLatestSummary(userDefaults: nil))
    }

    func testWriteWithUnavailableAppGroupIsSilentNoOp() {
        LinkaWidgetShared.writeLatestSummary(
            LinkaWidgetShared.LatestMeasurementSummary(
                downloadMbps: 1,
                uploadMbps: 1,
                latencyMs: 1,
                measuredAt: Date()
            ),
            userDefaults: nil
        )
        // Nada para asserir além de não travar — `nil` não tem onde
        // escrever por definição.
    }

    /// `widgetKind` precisa bater exatamente com o `kind:` de
    /// `StaticConfiguration` em `LinkaSpeedTestWidget` (target `LinkaWidget`,
    /// fora do alcance de `swift test` deste pacote) — travado aqui como
    /// contrato explícito para não divergir silenciosamente.
    func testWidgetKindIsStableForReloadTimelines() {
        XCTAssertEqual(LinkaWidgetShared.widgetKind, "LinkaSpeedTestWidget")
    }

    func testDifferentSummariesAreNotEqual() {
        let a = LinkaWidgetShared.LatestMeasurementSummary(
            downloadMbps: 100,
            uploadMbps: 10,
            latencyMs: 5,
            measuredAt: Date(timeIntervalSince1970: 0)
        )
        let b = LinkaWidgetShared.LatestMeasurementSummary(
            downloadMbps: 200,
            uploadMbps: 10,
            latencyMs: 5,
            measuredAt: Date(timeIntervalSince1970: 0)
        )
        XCTAssertNotEqual(a, b)
    }
}

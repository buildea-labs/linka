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

    func testAbsentDataIsNotZeroed() {
        let summary = LinkaWidgetShared.LatestMeasurementSummary(
            downloadMbps: 123.4,
            uploadMbps: nil,
            latencyMs: nil,
            measuredAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        LinkaWidgetShared.writeLatestSummary(summary, userDefaults: testDefaults)
        let read = LinkaWidgetShared.readLatestSummary(userDefaults: testDefaults)

        XCTAssertEqual(read?.downloadMbps, 123.4)
        XCTAssertNil(read?.uploadMbps)
        XCTAssertNil(read?.latencyMs)
    }

    func testReadWithoutPriorWriteReturnsNil() {
        XCTAssertNil(LinkaWidgetShared.readLatestSummary(userDefaults: testDefaults))
    }

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
    }

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

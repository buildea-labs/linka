import XCTest
@testable import LinkaApp

final class LinkaHistoryAdSessionGateTests: XCTestCase {
    func testDisabledConfigurationNeverStartsAnAdRequest() {
        var gate = LinkaHistoryAdSessionGate()

        XCTAssertFalse(gate.beginIfEligible(isEnabled: false, hasPlus: false, hasHistory: true))
        XCTAssertFalse(gate.didAttempt)
    }

    func testPlusAndEmptyHistoryNeverStartAnAdRequest() {
        var plusGate = LinkaHistoryAdSessionGate()
        var emptyHistoryGate = LinkaHistoryAdSessionGate()

        XCTAssertFalse(plusGate.beginIfEligible(isEnabled: true, hasPlus: true, hasHistory: true))
        XCTAssertFalse(emptyHistoryGate.beginIfEligible(isEnabled: true, hasPlus: false, hasHistory: false))
        XCTAssertFalse(plusGate.didAttempt)
        XCTAssertFalse(emptyHistoryGate.didAttempt)
    }

    func testEligibleFreeHistoryStartsOnlyOncePerSession() {
        var gate = LinkaHistoryAdSessionGate()

        XCTAssertTrue(gate.beginIfEligible(isEnabled: true, hasPlus: false, hasHistory: true))
        XCTAssertTrue(gate.didAttempt)
        XCTAssertFalse(gate.beginIfEligible(isEnabled: true, hasPlus: false, hasHistory: true))
    }
}

import XCTest
@testable import LinkaEntitlements

final class LinkaEntitlementsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    func testFreeAlwaysAllowsSpeedTestAndDeniesPremium() {
        XCTAssertTrue(
            LinkaEntitlementPolicy.hasAccess(
                to: .speedTest,
                snapshot: .free,
                at: now
            )
        )

        for capability in [
            LinkaCapability.history,
            .insights,
            .assist,
            .appleIntegrations
        ] {
            let decision = LinkaEntitlementPolicy.decision(
                for: capability,
                snapshot: .free,
                at: now
            )
            XCTAssertFalse(decision.isGranted)
            XCTAssertEqual(decision.reason, .planDoesNotIncludeCapability)
        }
    }

    func testActivePlusAllowsPremiumCapabilities() {
        let snapshot = LinkaEntitlementSnapshot.plus(
            status: .active,
            source: .subscription,
            validUntil: now.addingTimeInterval(3_600)
        )

        for capability in LinkaCapability.allCases {
            XCTAssertTrue(
                LinkaEntitlementPolicy.hasAccess(
                    to: capability,
                    snapshot: snapshot,
                    at: now
                )
            )
        }
    }

    func testUnknownInactiveAndExpiredFailClosedForPremium() {
        let cases: [(LinkaEntitlementStatus, LinkaAccessReason)] = [
            (.unknown, .unknownEntitlement),
            (.inactive, .inactiveEntitlement),
            (.expired, .expiredEntitlement)
        ]

        for (status, reason) in cases {
            let snapshot = LinkaEntitlementSnapshot.plus(
                status: status,
                source: .subscription
            )
            let decision = LinkaEntitlementPolicy.decision(
                for: .history,
                snapshot: snapshot,
                at: now
            )
            XCTAssertFalse(decision.isGranted)
            XCTAssertEqual(decision.reason, reason)
        }
    }

    func testExpirationDateOverridesActiveStatus() {
        let snapshot = LinkaEntitlementSnapshot.plus(
            status: .active,
            source: .subscription,
            validUntil: now.addingTimeInterval(-1)
        )

        let decision = LinkaEntitlementPolicy.decision(
            for: .assist,
            snapshot: snapshot,
            at: now
        )

        XCTAssertFalse(decision.isGranted)
        XCTAssertEqual(decision.reason, .expiredEntitlement)
    }

    func testTrialPromotionAndLifetimeCanGrantPlus() {
        let sources: [LinkaEntitlementSource] = [.trial, .promotion, .lifetime]

        for source in sources {
            let snapshot = LinkaEntitlementSnapshot.plus(
                status: .active,
                source: source,
                validUntil: source == .lifetime ? nil : now.addingTimeInterval(3_600)
            )

            XCTAssertTrue(
                LinkaEntitlementPolicy.hasAccess(
                    to: .insights,
                    snapshot: snapshot,
                    at: now
                )
            )
        }
    }

    func testInvalidSnapshotFailsClosedForPremiumButKeepsSpeedTest() {
        let invalid = LinkaEntitlementSnapshot(
            plan: .plus,
            status: .active,
            source: .free
        )

        let premiumDecision = LinkaEntitlementPolicy.decision(
            for: .history,
            snapshot: invalid,
            at: now
        )
        XCTAssertFalse(premiumDecision.isGranted)
        XCTAssertEqual(premiumDecision.reason, .invalidSnapshot)

        let speedDecision = LinkaEntitlementPolicy.decision(
            for: .speedTest,
            snapshot: invalid,
            at: now
        )
        XCTAssertTrue(speedDecision.isGranted)
        XCTAssertEqual(speedDecision.reason, .includedInFree)
    }

    func testLifetimeCannotCarryExpirationDate() {
        let invalid = LinkaEntitlementSnapshot.plus(
            status: .active,
            source: .lifetime,
            validUntil: now.addingTimeInterval(3_600)
        )

        let decision = LinkaEntitlementPolicy.decision(
            for: .appleIntegrations,
            snapshot: invalid,
            at: now
        )

        XCTAssertFalse(decision.isGranted)
        XCTAssertEqual(decision.reason, .invalidSnapshot)
    }

    func testStaticProviderUsesCentralPolicy() async {
        let provider = StaticLinkaEntitlementProvider(
            snapshot: .plus(
                status: .active,
                source: .promotion,
                validUntil: now.addingTimeInterval(60)
            )
        )

        XCTAssertTrue(await provider.hasAccess(to: .assist, at: now))
        XCTAssertFalse(
            await provider.hasAccess(
                to: .assist,
                at: now.addingTimeInterval(61)
            )
        )
    }
}

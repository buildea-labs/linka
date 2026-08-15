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

        let activeAccess = await provider.hasAccess(to: .assist, at: now)
        let expiredAccess = await provider.hasAccess(
            to: .assist,
            at: now.addingTimeInterval(61)
        )

        XCTAssertTrue(activeAccess)
        XCTAssertFalse(expiredAccess)
    }
}

// MARK: - StoreKitEntitlementProvider

@MainActor
final class StoreKitEntitlementProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 100_000)

    private func makeDefaults() -> UserDefaults {
        let suiteName = "StoreKitEntitlementProviderTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    // MARK: computeSnapshot (puro)

    func testComputeSnapshotIsFreeWithoutAKnownPurchase() {
        let snapshot = StoreKitEntitlementProvider.computeSnapshot(
            purchaseDate: nil,
            validityInterval: LinkaStoreEntitlementWindow.annualValidityInterval,
            now: now
        )

        XCTAssertEqual(snapshot, .free)
    }

    func testComputeSnapshotIsActivePlusWithinTheValidityWindow() {
        let purchaseDate = now.addingTimeInterval(-10)
        let snapshot = StoreKitEntitlementProvider.computeSnapshot(
            purchaseDate: purchaseDate,
            validityInterval: LinkaStoreEntitlementWindow.annualValidityInterval,
            now: now
        )

        XCTAssertEqual(snapshot.plan, .plus)
        XCTAssertEqual(snapshot.status, .active)
        XCTAssertEqual(snapshot.source, .subscription)
        XCTAssertEqual(
            snapshot.validUntil,
            purchaseDate.addingTimeInterval(LinkaStoreEntitlementWindow.annualValidityInterval)
        )

        XCTAssertTrue(
            LinkaEntitlementPolicy.hasAccess(to: .history, snapshot: snapshot, at: now)
        )
    }

    func testComputeSnapshotIsExpiredPlusPastTheValidityWindow() {
        let validityInterval: TimeInterval = 365 * 24 * 60 * 60
        let purchaseDate = now.addingTimeInterval(-(validityInterval + 1))
        let snapshot = StoreKitEntitlementProvider.computeSnapshot(
            purchaseDate: purchaseDate,
            validityInterval: validityInterval,
            now: now
        )

        XCTAssertEqual(snapshot.plan, .plus)
        XCTAssertEqual(snapshot.status, .expired)

        XCTAssertFalse(
            LinkaEntitlementPolicy.hasAccess(to: .history, snapshot: snapshot, at: now)
        )
    }

    func testIsEntitledOnlyForActivePlus() {
        XCTAssertFalse(StoreKitEntitlementProvider.isEntitled(.free))
        XCTAssertFalse(
            StoreKitEntitlementProvider.isEntitled(
                .plus(status: .expired, source: .subscription, validUntil: now)
            )
        )
        XCTAssertTrue(
            StoreKitEntitlementProvider.isEntitled(
                .plus(status: .active, source: .subscription, validUntil: now.addingTimeInterval(60))
            )
        )
    }

    // MARK: init a partir de cache local

    func testInitRestoresFreeSnapshotWhenNoPurchaseIsCached() {
        let provider = StoreKitEntitlementProvider(defaults: makeDefaults())
        XCTAssertEqual(provider.snapshot, .free)
    }

    func testInitRestoresPlusSnapshotFromCachedPurchaseDate() {
        let defaults = makeDefaults()
        defaults.set(Date(), forKey: "com.linka.plus.lastKnownPurchaseDate")

        let provider = StoreKitEntitlementProvider(defaults: defaults)

        XCTAssertEqual(provider.snapshot.plan, .plus)
        XCTAssertEqual(provider.snapshot.status, .active)
    }

    // MARK: handle(_:) — cancelamento e pendência (sem transação assinada real)

    func testHandleUserCancelledKeepsFreeSnapshotAndReportsCancellation() async throws {
        let provider = StoreKitEntitlementProvider(defaults: makeDefaults())

        let outcome = try await provider.handle(.userCancelled)

        XCTAssertEqual(outcome, .userCancelled)
        XCTAssertEqual(provider.snapshot, .free)
    }

    func testHandlePendingKeepsFreeSnapshotAndReportsPending() async throws {
        let provider = StoreKitEntitlementProvider(defaults: makeDefaults())

        let outcome = try await provider.handle(.pending)

        XCTAssertEqual(outcome, .pending)
        XCTAssertEqual(provider.snapshot, .free)
    }

    // MARK: DEBUG-only overrides

    #if DEBUG
    func testDebugForcePlusAndResetRoundTrip() {
        let provider = StoreKitEntitlementProvider(defaults: makeDefaults())
        XCTAssertEqual(provider.snapshot, .free)

        provider.debugForcePlus()
        XCTAssertEqual(provider.snapshot.plan, .plus)
        XCTAssertEqual(provider.snapshot.status, .active)
        XCTAssertEqual(provider.snapshot.source, .promotion)

        provider.debugResetToFree()
        XCTAssertEqual(provider.snapshot, .free)
    }
    #endif
}

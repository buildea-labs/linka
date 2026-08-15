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

    // MARK: restore() / refreshSnapshot() — sucesso e falha (revisão #79, item 1)
    //
    // `restore()` chama `AppStore.sync()` antes de tudo, que depende de
    // conectividade real com a App Store. Num `swift test` headless (sem
    // simulador, sem sessão de App Store, sem StoreKit Configuration
    // file) essa chamada não falha rápido — ela trava, o que travaria a
    // pipeline de CI se exercitada aqui. Essa é a mesma PENDÊNCIA já
    // documentada no cabeçalho de `LinkaStoreProductID`: falta configurar
    // um `.storekit` Configuration file + `SKTestSession`, o que exige um
    // alvo de teste hospedado pelo Xcode — não um pacote SPM puro rodando
    // via linha de comando. A PR (#79) já documentava isso como "não
    // testado" nas validações locais.
    //
    // Por isso os testes abaixo exercitam `refreshSnapshot()` diretamente
    // — o mesmo método que `restore()` chama internamente logo após
    // `AppStore.sync()`, e onde vive a correção do item 1 (iterar
    // `Transaction.all` filtrando `productID` + `revocationDate == nil`,
    // em vez de `Transaction.currentEntitlements`, que não cobre
    // non-renewing subscriptions). `Transaction.all` é um log local, não
    // uma chamada de rede, e não trava neste ambiente.
    //
    // "Sucesso": nenhuma transação StoreKit real existe no ambiente de
    // teste, então `refreshSnapshot()` cai para a data de compra em cache
    // (`cachedPurchaseDate()`) — o mesmo fallback que `restore()` usaria
    // se `Transaction.all` não repetisse uma compra já conhecida
    // localmente. "Falha": sem cache e sem transação, o snapshot
    // permanece `.free` e `isEntitled` retorna `false` — o mesmo par que
    // `restore()` reportaria como "nenhuma entitlement Plus encontrada".

    func testRefreshSnapshotSucceedsAndIsEntitledWhenAPurchaseIsKnown() async {
        let defaults = makeDefaults()
        defaults.set(Date(), forKey: "com.linka.plus.lastKnownPurchaseDate")
        let provider = StoreKitEntitlementProvider(defaults: defaults)

        await provider.refreshSnapshot()

        XCTAssertEqual(provider.snapshot.plan, .plus)
        XCTAssertEqual(provider.snapshot.status, .active)
        XCTAssertTrue(StoreKitEntitlementProvider.isEntitled(provider.snapshot))
    }

    func testRefreshSnapshotFailsAndIsNotEntitledWithoutAnyKnownPurchase() async {
        let provider = StoreKitEntitlementProvider(defaults: makeDefaults())

        await provider.refreshSnapshot()

        XCTAssertEqual(provider.snapshot, .free)
        XCTAssertFalse(StoreKitEntitlementProvider.isEntitled(provider.snapshot))
    }

    // MARK: LinkaStoreError

    func testLinkaStoreErrorCasesAreEquatableAndCarryTheirProductID() {
        XCTAssertEqual(LinkaStoreError.productNotFound("a"), .productNotFound("a"))
        XCTAssertNotEqual(LinkaStoreError.productNotFound("a"), .productNotFound("b"))
        XCTAssertNotEqual(LinkaStoreError.productNotFound("a"), .verificationFailed)
        XCTAssertEqual(LinkaStoreError.verificationFailed, .verificationFailed)
    }

    /// `Product.products(for:)` com um ID desconhecido não depende de
    /// `AppStore.sync()` (não trava neste ambiente) — retorna uma lista
    /// vazia, e `purchase()` traduz isso em `.productNotFound`. Cobre o
    /// caminho de erro real de `purchase()`, exigido pelo aceite #6.
    func testPurchaseThrowsProductNotFoundForAnUnknownProductID() async {
        let unknownProductID = "com.linka.does.not.exist.\(UUID().uuidString)"
        let provider = StoreKitEntitlementProvider(
            productID: unknownProductID,
            defaults: makeDefaults()
        )

        do {
            _ = try await provider.purchase()
            XCTFail("esperava que purchase() lançasse LinkaStoreError.productNotFound")
        } catch let error as LinkaStoreError {
            XCTAssertEqual(error, .productNotFound(unknownProductID))
        } catch {
            XCTFail("esperava LinkaStoreError, recebeu \(error)")
        }
    }
}

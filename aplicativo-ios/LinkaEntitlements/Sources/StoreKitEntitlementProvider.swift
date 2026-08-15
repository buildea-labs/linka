import Foundation
import StoreKit

/// Identificadores de produto do Linka Plus na App Store Connect.
///
/// PENDÊNCIA (issue #60): estes IDs são placeholders. Luiz precisa:
/// 1. Criar o produto correspondente em App Store Connect. A copy atual da
///    `PurchaseSheet` ("compra única de R$ 6,90, válida por um ano, sem
///    renovação automática") descreve uma **Non-Renewing Subscription**, não
///    uma assinatura auto-renovável nem um non-consumable — a App Store não
///    rastreia validade desse tipo de produto, então este provider computa
///    a janela de 1 ano a partir da data de compra (`LinkaStoreEntitlementWindow`).
/// 2. Configurar um StoreKit Configuration file local (`.storekit`) e
///    associá-lo ao scheme de teste antes de qualquer TestFlight — sem ele,
///    `Product.products(for:)` não encontra nenhum produto em desenvolvimento.
public enum LinkaStoreProductID {
    /// Produto ativo hoje na `PurchaseSheet`: "R$ 6,90/ano".
    public static let plusAnnual = "com.linka.plus.annual"

    /// Reservado para uma futura oferta mensal. Não ofertado na UI atual —
    /// não usar até existir copy e produto correspondentes em ASC.
    public static let plusMonthly = "com.linka.plus.monthly"

    public static let all: Set<String> = [plusAnnual, plusMonthly]
}

/// Duração de validade do "Linka Plus" hoje: compra anual sem renovação
/// automática (Non-Renewing Subscription). Como a App Store não rastreia a
/// validade desse tipo de produto, o app precisa computar a janela a partir
/// da data de compra e persistir esse estado localmente.
public enum LinkaStoreEntitlementWindow {
    public static let annualValidityInterval: TimeInterval = 365 * 24 * 60 * 60
}

public enum LinkaPurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case userCancelled
}

public enum LinkaStoreError: Error, Equatable, Sendable {
    case productNotFound(String)
    case verificationFailed
}

/// Provider real de entitlement do Linka Plus, baseado em StoreKit 2.
///
/// É o único ponto de escrita do snapshot de produção: consulta
/// `Transaction.currentEntitlements`, escuta `Transaction.updates` e publica
/// o snapshot resultante via `@Published` para a UI observar (`ObservableObject`).
///
/// Non-renewing subscriptions não têm validade rastreada pela App Store —
/// este provider computa a janela (compra + `validityInterval`) e persiste a
/// última data de compra conhecida em `UserDefaults` para sobreviver a
/// reinícios do app sem depender de round-trip de rede a cada abertura.
@MainActor
public final class StoreKitEntitlementProvider: ObservableObject, LinkaEntitlementProviding, @unchecked Sendable {
    @Published public private(set) var snapshot: LinkaEntitlementSnapshot = .free

    private let productID: String
    private let validityInterval: TimeInterval
    private let defaults: UserDefaults
    private let purchaseDateKey = "com.linka.plus.lastKnownPurchaseDate"
    private var updatesTask: Task<Void, Never>?

    public init(
        productID: String = LinkaStoreProductID.plusAnnual,
        validityInterval: TimeInterval = LinkaStoreEntitlementWindow.annualValidityInterval,
        defaults: UserDefaults = .standard
    ) {
        self.productID = productID
        self.validityInterval = validityInterval
        self.defaults = defaults
        self.snapshot = Self.computeSnapshot(
            purchaseDate: defaults.object(forKey: purchaseDateKey) as? Date,
            validityInterval: validityInterval,
            now: Date()
        )

        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - LinkaEntitlementProviding

    public func decision(
        for capability: LinkaCapability,
        at date: Date
    ) async -> LinkaAccessDecision {
        LinkaEntitlementPolicy.decision(for: capability, snapshot: snapshot, at: date)
    }

    // MARK: - Compra

    /// Inicia a compra do Linka Plus via StoreKit 2. Não escreve `isPro`
    /// nem qualquer flag local diretamente — o snapshot só muda a partir de
    /// uma transação real, verificada e persistida.
    @discardableResult
    public func purchase() async throws -> LinkaPurchaseOutcome {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw LinkaStoreError.productNotFound(productID)
        }

        let result = try await product.purchase()
        return try await handle(result)
    }

    /// Restaura compras anteriores consultando o estado real da App Store
    /// (`AppStore.sync()` + `Transaction.currentEntitlements`), não um
    /// atalho local. Retorna `true` quando uma entitlement Plus ativa foi
    /// encontrada.
    @discardableResult
    public func restore() async throws -> Bool {
        try await AppStore.sync()
        await refreshSnapshot()
        return Self.isEntitled(snapshot)
    }

    // MARK: - Estado interno

    /// Recalcula o snapshot a partir de `Transaction.currentEntitlements`.
    /// Exposto (não `private`) para permitir refresh manual (ex.: ao abrir
    /// a `SettingsSheet`) sem duplicar a lógica de leitura do StoreKit.
    public func refreshSnapshot() async {
        var latestPurchaseDate: Date?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result),
                  transaction.productID == productID else { continue }

            if latestPurchaseDate == nil || transaction.purchaseDate > latestPurchaseDate! {
                latestPurchaseDate = transaction.purchaseDate
            }
        }

        if let latestPurchaseDate {
            recordPurchase(at: latestPurchaseDate)
        }

        snapshot = Self.computeSnapshot(
            purchaseDate: latestPurchaseDate ?? cachedPurchaseDate(),
            validityInterval: validityInterval,
            now: Date()
        )
    }

    /// Interpreta um `Product.PurchaseResult` do StoreKit e atualiza o
    /// snapshot quando aplicável. Isolado do fetch de produto para permitir
    /// cobertura de teste dos ramos `.userCancelled` e `.pending`, que não
    /// exigem uma transação assinada real.
    func handle(_ result: Product.PurchaseResult) async throws -> LinkaPurchaseOutcome {
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            guard transaction.productID == productID else {
                await transaction.finish()
                throw LinkaStoreError.productNotFound(productID)
            }
            recordPurchase(at: transaction.purchaseDate)
            await transaction.finish()
            await refreshSnapshot()
            return .purchased
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            guard let transaction = try? Self.checkVerified(update),
                  transaction.productID == productID else { continue }
            recordPurchase(at: transaction.purchaseDate)
            await transaction.finish()
            await refreshSnapshot()
        }
    }

    private func cachedPurchaseDate() -> Date? {
        defaults.object(forKey: purchaseDateKey) as? Date
    }

    private func recordPurchase(at date: Date) {
        let current = cachedPurchaseDate()
        if current == nil || date > current! {
            defaults.set(date, forKey: purchaseDateKey)
        }
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw LinkaStoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// Pura e testável: deriva o snapshot de entitlement a partir de uma
    /// data de compra conhecida (ou `nil`, quando não há compra registrada).
    /// A checagem de expiração propriamente dita continua sendo feita por
    /// `LinkaEntitlementPolicy.decision` (via `validUntil`); aqui apenas
    /// refletimos o status observável no snapshot para leitura direta pela UI.
    static func computeSnapshot(
        purchaseDate: Date?,
        validityInterval: TimeInterval,
        now: Date
    ) -> LinkaEntitlementSnapshot {
        guard let purchaseDate else { return .free }
        let validUntil = purchaseDate.addingTimeInterval(validityInterval)
        let status: LinkaEntitlementStatus = validUntil > now ? .active : .expired
        return .plus(status: status, source: .subscription, validUntil: validUntil)
    }

    /// Pura e testável: determina se um snapshot representa um Plus
    /// utilizável agora (usado pelo retorno de `restore()`).
    static func isEntitled(_ snapshot: LinkaEntitlementSnapshot) -> Bool {
        snapshot.plan == .plus && snapshot.status == .active
    }

    #if DEBUG
    /// Atalho de desenvolvimento para exercitar a UI Plus sem depender de um
    /// StoreKit Configuration file. Compilado apenas em builds DEBUG — não
    /// existe no binário de Release (issue #60, requisito de aceite 5).
    public func debugForcePlus() {
        snapshot = .plus(status: .active, source: .promotion)
    }

    /// Reverte o override de desenvolvimento e limpa o registro local de
    /// compra, voltando ao estado free. Também DEBUG-only.
    public func debugResetToFree() {
        defaults.removeObject(forKey: purchaseDateKey)
        snapshot = .free
    }
    #endif
}

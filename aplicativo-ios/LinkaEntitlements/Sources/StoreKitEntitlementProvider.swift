import Foundation
import StoreKit

/// Identificadores de produto do Linka Plus na App Store Connect.
///
/// A validacao de existencia/preco acontece no StoreKit: se o produto nao
/// existir ou nao estiver disponivel, a UI falha fechada e nao libera Plus.
public enum LinkaStoreProductID {
    /// Produto ativo hoje na `PurchaseSheet`: "R$ 19,90/ano".
    public static let plusAnnual = "com.linka.plus.annual"

    /// Reservado para uma futura oferta mensal.
    public static let plusMonthly = "com.linka.plus.monthly"

    public static let all: Set<String> = [plusAnnual, plusMonthly]
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
/// Refatorado para lidar exclusivamente com assinaturas auto-renováveis.
/// Ele consulta `Transaction.currentEntitlements` nativamente, e confia
/// no próprio StoreKit para gerenciar a validade (expirationDate), sem
/// necessidade de computar e salvar no UserDefaults a data de validade.
@MainActor
public final class StoreKitEntitlementProvider: ObservableObject, LinkaEntitlementProviding, @unchecked Sendable {
    @Published public private(set) var snapshot: LinkaEntitlementSnapshot = .free

    @Published public private(set) var product: Product?
    @Published public private(set) var isLoadingProduct = false
    @Published public private(set) var isRefreshingSnapshot = false

    private let productID: String
    private var updatesTask: Task<Void, Never>?
    private var productTask: Task<Void, Never>?

    public init(
        productID: String = LinkaStoreProductID.plusAnnual
    ) {
        self.productID = productID
        
        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }

        productTask = Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshSnapshot()
        }
    }

    deinit {
        updatesTask?.cancel()
        productTask?.cancel()
    }

    // MARK: - LinkaEntitlementProviding

    public func decision(
        for capability: LinkaCapability,
        at date: Date
    ) async -> LinkaAccessDecision {
        LinkaEntitlementPolicy.decision(for: capability, snapshot: snapshot, at: date)
    }

    // MARK: - Compra

    @discardableResult
    public func purchase() async throws -> LinkaPurchaseOutcome {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw LinkaStoreError.productNotFound(productID)
        }

        let result = try await product.purchase()
        return try await handle(result)
    }

    public func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            product = nil
        }
    }

    @discardableResult
    public func restore() async throws -> Bool {
        try await AppStore.sync()
        await refreshSnapshot()
        return Self.isEntitled(snapshot)
    }

    // MARK: - Estado interno

    /// Recalcula o snapshot a partir de `Transaction.currentEntitlements`.
    /// Como o Linka Plus agora é uma Auto-Renewable Subscription, essa API
    /// do StoreKit 2 é a fonte da verdade sobre se o usuário tem a assinatura
    /// ativa, já lidando com revogações, renovações e carências.
    public func refreshSnapshot() async {
        isRefreshingSnapshot = true
        defer { isRefreshingSnapshot = false }

        var activeTransaction: Transaction?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result),
                  transaction.productID == productID else { continue }
            
            // Com currentEntitlements, a transação que volta aqui
            // representa um entitlement ativo neste exato momento.
            activeTransaction = transaction
        }

        if let transaction = activeTransaction {
            snapshot = .plus(
                status: .active,
                source: .subscription,
                validUntil: transaction.expirationDate
            )
        } else {
            snapshot = .free
        }
    }

    func handle(_ result: Product.PurchaseResult) async throws -> LinkaPurchaseOutcome {
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            guard transaction.productID == productID else {
                await transaction.finish()
                throw LinkaStoreError.productNotFound(productID)
            }
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
            await transaction.finish()
            await refreshSnapshot()
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

    static func isEntitled(_ snapshot: LinkaEntitlementSnapshot) -> Bool {
        snapshot.plan == .plus && snapshot.status == .active
    }

    #if DEBUG
    public func debugForcePlus() {
        snapshot = .plus(status: .active, source: .promotion)
    }

    public func debugResetToFree() {
        snapshot = .free
    }
    #endif
}

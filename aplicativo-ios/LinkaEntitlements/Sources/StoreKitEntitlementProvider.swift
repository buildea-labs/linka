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

    public enum ProductLoadState: Equatable, Sendable {
        case loading
        case loaded(Product)
        case unavailable
        case error(String)
        
        // Custom Equatable for Product (compares ids since Product itself doesn't conform to Equatable directly in earlier iOS, though it might. We'll implement == just in case or just compare ids)
        public static func == (lhs: ProductLoadState, rhs: ProductLoadState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.unavailable, .unavailable): return true
            case let (.loaded(l), .loaded(r)): return l.id == r.id
            case let (.error(l), .error(r)): return l == r
            default: return false
            }
        }
    }

    @Published public private(set) var productState: ProductLoadState = .loading
    @Published public private(set) var isRefreshingSnapshot = false

    private let productID: String
    private var updatesTask: Task<Void, Never>?
    private var productTask: Task<Void, Never>?

    /// Chave UserDefaults para forçar Linka Plus sem compra.
    /// Útil para testes internos em qualquer build (debug, release, TestFlight).
    /// Para ativar: UserDefaults.standard.set(true, forKey: "linkaForcePlus")
    /// Para desativar: UserDefaults.standard.removeObject(forKey: "linkaForcePlus")
    public static let forcePlusKey = "linkaForcePlus"

    private var isForcePlusEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.forcePlusKey)
    }

    public init(
        productID: String = LinkaStoreProductID.plusAnnual
    ) {
        self.productID = productID

        // Override de Plus para testes internos — não depende de StoreKit
        if UserDefaults.standard.bool(forKey: Self.forcePlusKey) {
            snapshot = .plus(status: .active, source: .promotion)
        }

        let localProductID = productID
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let transaction = try? Self.checkVerified(update),
                      transaction.productID == localProductID else { continue }
                await transaction.finish()
                await self?.refreshSnapshot()
            }
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
        let productToPurchase: Product
        if case .loaded(let p) = productState {
            productToPurchase = p
        } else {
            let products = try await Product.products(for: [productID])
            guard let p = products.first else {
                throw LinkaStoreError.productNotFound(productID)
            }
            productToPurchase = p
        }

        let result = try await productToPurchase.purchase()
        return try await handle(result)
    }

    public func loadProduct() async {
        productState = .loading

        do {
            let products = try await Product.products(for: [productID])
            if let firstProduct = products.first {
                productState = .loaded(firstProduct)
            } else {
                productState = .unavailable
            }
        } catch {
            productState = .error(error.localizedDescription)
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
        // Se o override de Plus está ativo, não sobrescreve com o resultado do StoreKit
        guard !isForcePlusEnabled else { return }
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

    // MARK: - Override de Plus para testes internos

    /// Ativa ou desativa o Linka Plus forçado via UserDefaults.
    /// Funciona em qualquer build (debug, release, TestFlight).
    ///
    /// Para ativar sem código:
    ///   Launch argument no Xcode: `-linkaForcePlus 1`
    ///   Ou via LLDB: `e UserDefaults.standard.set(true, forKey: "linkaForcePlus")`
    public func setForcePlus(_ enabled: Bool) {
        if enabled {
            UserDefaults.standard.set(true, forKey: Self.forcePlusKey)
            snapshot = .plus(status: .active, source: .promotion)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.forcePlusKey)
            Task { await refreshSnapshot() }
        }
    }

    #if DEBUG
    public func debugForcePlus() { setForcePlus(true) }
    public func debugResetToFree() { setForcePlus(false) }
    #endif
}

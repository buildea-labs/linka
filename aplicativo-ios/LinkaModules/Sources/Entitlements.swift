import Foundation
import LinkaEntitlements

/// Contrato legado preservado apenas para a fundação inicial de `LinkaModules`.
/// Código novo deve depender de `LinkaEntitlementProviding`.
public protocol EntitlementProviding: Sendable {
    func hasAccess(to capability: LinkaCapability) async -> Bool
}

/// Compatibilidade com a API inicial free/plus.
/// A política canônica vive em `LinkaEntitlementPolicy`.
public enum LinkaAccessPolicy {
    public static func capabilities(for tier: LinkaTier) -> Set<LinkaCapability> {
        LinkaEntitlementPolicy.capabilities(for: tier)
    }

    public static func hasAccess(
        to capability: LinkaCapability,
        on tier: LinkaTier
    ) -> Bool {
        capabilities(for: tier).contains(capability)
    }
}

/// Provider legado que traduz tier para um snapshot estático.
/// Não representa StoreKit nem estado real de assinatura.
public struct StaticEntitlementProvider: EntitlementProviding {
    private let provider: StaticLinkaEntitlementProvider

    public init(tier: LinkaTier) {
        let snapshot: LinkaEntitlementSnapshot
        switch tier {
        case .free:
            snapshot = .free
        case .plus:
            snapshot = .plus(status: .active, source: .subscription)
        }
        self.provider = StaticLinkaEntitlementProvider(snapshot: snapshot)
    }

    public func hasAccess(to capability: LinkaCapability) async -> Bool {
        await provider.hasAccess(to: capability)
    }
}

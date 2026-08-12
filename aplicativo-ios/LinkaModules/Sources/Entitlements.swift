import Foundation

public protocol EntitlementProviding: Sendable {
    func hasAccess(to capability: LinkaCapability) async -> Bool
}

public enum LinkaAccessPolicy {
    public static func capabilities(for tier: LinkaTier) -> Set<LinkaCapability> {
        switch tier {
        case .free:
            return [.speedTest]
        case .plus:
            return Set(LinkaCapability.allCases)
        }
    }

    public static func hasAccess(
        to capability: LinkaCapability,
        on tier: LinkaTier
    ) -> Bool {
        capabilities(for: tier).contains(capability)
    }
}

public struct StaticEntitlementProvider: EntitlementProviding {
    public let tier: LinkaTier

    public init(tier: LinkaTier) {
        self.tier = tier
    }

    public func hasAccess(to capability: LinkaCapability) async -> Bool {
        LinkaAccessPolicy.hasAccess(to: capability, on: tier)
    }
}

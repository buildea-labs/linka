import Foundation

public enum LinkaPlan: String, Codable, CaseIterable, Sendable {
    case free
    case plus
}

public enum LinkaCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case speedTest
    case history
    case insights
    case assist
    case appleIntegrations
}

public enum LinkaEntitlementStatus: String, Codable, Sendable {
    case unknown
    case inactive
    case active
    case expired
}

public enum LinkaEntitlementSource: String, Codable, Sendable {
    case free
    case subscription
    case trial
    case promotion
    case lifetime
}

public enum LinkaAccessReason: String, Codable, Sendable {
    case includedInFree
    case activeEntitlement
    case planDoesNotIncludeCapability
    case unknownEntitlement
    case inactiveEntitlement
    case expiredEntitlement
    case invalidSnapshot
}

public struct LinkaEntitlementSnapshot: Codable, Equatable, Sendable {
    public let plan: LinkaPlan
    public let status: LinkaEntitlementStatus
    public let source: LinkaEntitlementSource
    public let validUntil: Date?

    public init(
        plan: LinkaPlan,
        status: LinkaEntitlementStatus,
        source: LinkaEntitlementSource,
        validUntil: Date? = nil
    ) {
        self.plan = plan
        self.status = status
        self.source = source
        self.validUntil = validUntil
    }

    public static let free = LinkaEntitlementSnapshot(
        plan: .free,
        status: .active,
        source: .free
    )

    public static func plus(
        status: LinkaEntitlementStatus,
        source: LinkaEntitlementSource,
        validUntil: Date? = nil
    ) -> LinkaEntitlementSnapshot {
        LinkaEntitlementSnapshot(
            plan: .plus,
            status: status,
            source: source,
            validUntil: validUntil
        )
    }
}

public struct LinkaAccessDecision: Codable, Equatable, Sendable {
    public let capability: LinkaCapability
    public let isGranted: Bool
    public let reason: LinkaAccessReason

    public init(
        capability: LinkaCapability,
        isGranted: Bool,
        reason: LinkaAccessReason
    ) {
        self.capability = capability
        self.isGranted = isGranted
        self.reason = reason
    }
}

public enum LinkaEntitlementPolicy {
    public static func capabilities(for plan: LinkaPlan) -> Set<LinkaCapability> {
        switch plan {
        case .free:
            return [.speedTest]
        case .plus:
            return Set(LinkaCapability.allCases)
        }
    }

    public static func decision(
        for capability: LinkaCapability,
        snapshot: LinkaEntitlementSnapshot,
        at date: Date = Date()
    ) -> LinkaAccessDecision {
        // A função principal nunca depende do estado do sistema de assinatura.
        if capability == .speedTest {
            return LinkaAccessDecision(
                capability: capability,
                isGranted: true,
                reason: .includedInFree
            )
        }

        guard isStructurallyValid(snapshot) else {
            return denied(capability, reason: .invalidSnapshot)
        }

        guard capabilities(for: snapshot.plan).contains(capability) else {
            return denied(capability, reason: .planDoesNotIncludeCapability)
        }

        switch snapshot.status {
        case .unknown:
            return denied(capability, reason: .unknownEntitlement)
        case .inactive:
            return denied(capability, reason: .inactiveEntitlement)
        case .expired:
            return denied(capability, reason: .expiredEntitlement)
        case .active:
            if let validUntil = snapshot.validUntil, validUntil <= date {
                return denied(capability, reason: .expiredEntitlement)
            }

            return LinkaAccessDecision(
                capability: capability,
                isGranted: true,
                reason: .activeEntitlement
            )
        }
    }

    public static func hasAccess(
        to capability: LinkaCapability,
        snapshot: LinkaEntitlementSnapshot,
        at date: Date = Date()
    ) -> Bool {
        decision(for: capability, snapshot: snapshot, at: date).isGranted
    }

    private static func isStructurallyValid(_ snapshot: LinkaEntitlementSnapshot) -> Bool {
        switch snapshot.plan {
        case .free:
            return snapshot.source == .free && snapshot.validUntil == nil
        case .plus:
            guard snapshot.source != .free else { return false }
            if snapshot.source == .lifetime && snapshot.validUntil != nil {
                return false
            }
            return true
        }
    }

    private static func denied(
        _ capability: LinkaCapability,
        reason: LinkaAccessReason
    ) -> LinkaAccessDecision {
        LinkaAccessDecision(
            capability: capability,
            isGranted: false,
            reason: reason
        )
    }
}

public protocol LinkaEntitlementProviding: Sendable {
    func decision(
        for capability: LinkaCapability,
        at date: Date
    ) async -> LinkaAccessDecision
}

public extension LinkaEntitlementProviding {
    func hasAccess(
        to capability: LinkaCapability,
        at date: Date = Date()
    ) async -> Bool {
        await decision(for: capability, at: date).isGranted
    }
}

public struct StaticLinkaEntitlementProvider: LinkaEntitlementProviding {
    public let snapshot: LinkaEntitlementSnapshot

    public init(snapshot: LinkaEntitlementSnapshot) {
        self.snapshot = snapshot
    }

    public func decision(
        for capability: LinkaCapability,
        at date: Date
    ) async -> LinkaAccessDecision {
        LinkaEntitlementPolicy.decision(
            for: capability,
            snapshot: snapshot,
            at: date
        )
    }
}

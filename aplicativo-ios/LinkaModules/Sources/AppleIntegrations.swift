import Foundation

public enum AppleIntegration: String, Codable, CaseIterable, Hashable, Sendable {
    case widgets
    case appIntents
    case siriShortcuts
    case sharedHistory
}

public protocol AppleIntegrationProviding: Sendable {
    func isAvailable(_ integration: AppleIntegration) async -> Bool
}

public struct StaticAppleIntegrationProvider: AppleIntegrationProviding {
    private let supported: Set<AppleIntegration>

    public init(supported: Set<AppleIntegration> = []) {
        self.supported = supported
    }

    public func isAvailable(_ integration: AppleIntegration) async -> Bool {
        supported.contains(integration)
    }
}

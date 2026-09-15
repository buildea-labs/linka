import Foundation

public protocol NetworkProfileRepository: Sendable {
    func upsert(_ profile: NetworkProfile) async throws
    func profile(for identity: NetworkProfileIdentity) async throws -> NetworkProfile?
    func profiles() async throws -> [NetworkProfile]
    func remove(identity: NetworkProfileIdentity) async throws
}

public enum NetworkProfileRepositoryError: Error, Equatable, Sendable {
    case corruptedStore
    case unsupportedStoreVersion(Int)
    case persistenceFailed
}

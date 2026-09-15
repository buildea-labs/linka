import Foundation

/// Repositório local de perfis com documento JSON versionado.
///
/// Falhas de leitura e versões desconhecidas não são recuperadas nem
/// sobrescritas: o repositório falha fechado para preservar o documento.
public actor FileNetworkProfileRepository: NetworkProfileRepository {
    public static let storeSchemaVersion = 1

    private struct StoreDocument: Codable {
        let schemaVersion: Int
        let profiles: [NetworkProfile]
    }

    private let fileURL: URL
    private var hasLoaded = false
    private var storedProfiles: [NetworkProfile] = []

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func upsert(_ profile: NetworkProfile) async throws {
        try loadIfNeeded()
        var updatedProfiles = storedProfiles
        updatedProfiles.removeAll { $0.identity == profile.identity }
        updatedProfiles.append(profile)
        updatedProfiles.sort(by: Self.sortProfiles)
        try persist(updatedProfiles)
        storedProfiles = updatedProfiles
    }

    public func profile(for identity: NetworkProfileIdentity) async throws -> NetworkProfile? {
        try loadIfNeeded()
        return storedProfiles.first { $0.identity == identity }
    }

    public func profiles() async throws -> [NetworkProfile] {
        try loadIfNeeded()
        return storedProfiles.sorted(by: Self.sortProfiles)
    }

    public func remove(identity: NetworkProfileIdentity) async throws {
        try loadIfNeeded()
        let updatedProfiles = storedProfiles.filter { $0.identity != identity }
        guard updatedProfiles.count != storedProfiles.count else { return }
        try persist(updatedProfiles)
        storedProfiles = updatedProfiles
    }

    private func loadIfNeeded() throws {
        guard !hasLoaded else { return }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            storedProfiles = []
            hasLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .deferredToDate
            let document = try decoder.decode(StoreDocument.self, from: data)
            guard document.schemaVersion == Self.storeSchemaVersion else {
                throw NetworkProfileRepositoryError.unsupportedStoreVersion(document.schemaVersion)
            }
            guard Set(document.profiles.map(\.identity)).count == document.profiles.count else {
                throw NetworkProfileRepositoryError.corruptedStore
            }
            storedProfiles = document.profiles.sorted(by: Self.sortProfiles)
            hasLoaded = true
        } catch let error as NetworkProfileRepositoryError {
            throw error
        } catch {
            throw NetworkProfileRepositoryError.corruptedStore
        }
    }

    private func persist(_ profiles: [NetworkProfile]) throws {
        do {
            let parent = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: parent,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .deferredToDate
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(StoreDocument(
                schemaVersion: Self.storeSchemaVersion,
                profiles: profiles
            ))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw NetworkProfileRepositoryError.persistenceFailed
        }
    }

    private static func sortProfiles(_ lhs: NetworkProfile, _ rhs: NetworkProfile) -> Bool {
        if lhs.updatedAt == rhs.updatedAt {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.updatedAt > rhs.updatedAt
    }
}

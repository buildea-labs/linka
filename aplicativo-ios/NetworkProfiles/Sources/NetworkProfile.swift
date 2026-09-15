import Foundation

/// Perfil local nomeado pela pessoa para contextualizar medições da mesma rede.
/// Não armazena SSID, BSSID/MAC ou métricas de medição.
public struct NetworkProfile: Codable, Equatable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let identity: NetworkProfileIdentity
    public let name: String
    public let createdAt: Date
    public let updatedAt: Date
    /// Marco local e persistido a partir do qual as medições podem compor a
    /// referência. Não apaga nem altera o Histórico.
    public let referenceStartedAt: Date
    public let lastAnalyzedAt: Date?

    public init?(
        id: UUID = UUID(),
        identity: NetworkProfileIdentity,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        referenceStartedAt: Date? = nil,
        lastAnalyzedAt: Date? = nil
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, updatedAt >= createdAt else {
            return nil
        }

        self.id = id
        self.identity = identity
        self.name = trimmedName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.referenceStartedAt = referenceStartedAt ?? createdAt
        self.lastAnalyzedAt = lastAnalyzedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case identity
        case name
        case createdAt
        case updatedAt
        case referenceStartedAt
        case lastAnalyzedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let identity = try container.decode(NetworkProfileIdentity.self, forKey: .identity)
        let name = try container.decode(String.self, forKey: .name)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        let referenceStartedAt = try container.decodeIfPresent(Date.self, forKey: .referenceStartedAt)
        let lastAnalyzedAt = try container.decodeIfPresent(Date.self, forKey: .lastAnalyzedAt)
        guard let profile = Self(
            id: id,
            identity: identity,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            referenceStartedAt: referenceStartedAt,
            lastAnalyzedAt: lastAnalyzedAt
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .name,
                in: container,
                debugDescription: "Invalid network profile"
            )
        }
        self = profile
    }
}

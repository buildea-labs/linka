import CryptoKit
import Foundation

/// Identidade local e não reversível de uma rede Wi-Fi.
///
/// O SSID só existe durante a criação desta identidade. O valor persistível é
/// exclusivamente o fingerprint SHA-256 e sua versão de algoritmo.
public struct NetworkProfileIdentity: Codable, Equatable, Hashable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let fingerprint: String

    /// Cria uma identidade a partir de um SSID disponível em memória.
    /// Retorna `nil` para SSID ausente, vazio ou composto só por espaços.
    public init?(ssid: String?, installationSecret: Data) {
        guard !installationSecret.isEmpty,
              let normalizedSSID = Self.normalizedSSID(ssid) else {
            return nil
        }

        self.version = Self.currentVersion
        self.fingerprint = HMAC<SHA256>.authenticationCode(
            for: Data(normalizedSSID.utf8),
            using: SymmetricKey(data: installationSecret)
        )
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// Reconstrói uma identidade persistida, rejeitando versões e digests que
    /// não correspondem ao formato atual.
    public init?(version: Int, fingerprint: String) {
        guard version == Self.currentVersion,
              fingerprint.count == 64,
              fingerprint.unicodeScalars.allSatisfy({
                  (48...57).contains($0.value) || (65...70).contains($0.value) || (97...102).contains($0.value)
              }) else {
            return nil
        }

        self.version = version
        self.fingerprint = fingerprint.lowercased()
    }

    /// Normalização estável para o fingerprint: composição Unicode canônica e
    /// remoção apenas de espaços de borda. Não reduz caixa nem remove espaços
    /// internos, pois isso poderia unir SSIDs distintos.
    public static func normalizedSSID(_ ssid: String?) -> String? {
        guard let ssid else { return nil }
        let normalized = ssid
            .precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case fingerprint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        let fingerprint = try container.decode(String.self, forKey: .fingerprint)
        guard let identity = Self(version: version, fingerprint: fingerprint) else {
            throw DecodingError.dataCorruptedError(
                forKey: .fingerprint,
                in: container,
                debugDescription: "Invalid network profile identity"
            )
        }
        self = identity
    }
}

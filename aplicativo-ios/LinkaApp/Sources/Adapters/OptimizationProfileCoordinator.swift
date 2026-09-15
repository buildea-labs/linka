import Foundation
import Combine
import Security
import NetworkCore
import NetworkInsights
import NetworkOptimization
import NetworkProfiles

/// Estado local da jornada de perfis. A coordenação conhece a preferência de
/// identificação e o histórico, mas não pede permissão nem envia dados.
@MainActor
final class OptimizationProfileCoordinator: ObservableObject {
    enum CurrentNetworkState: Equatable {
        case identificationDisabled
        case notWiFi
        case ssidUnavailable
        case available(identity: NetworkProfileIdentity)
    }

    enum ReferenceState: Equatable {
        case building(sampleCount: Int)
        case ready(sampleCount: Int)
    }

    @Published private(set) var profiles: [NetworkProfile] = []
    @Published private(set) var currentNetworkState: CurrentNetworkState = .notWiFi
    @Published private(set) var referenceSampleCounts: [NetworkProfileIdentity: Int] = [:]
    @Published private(set) var readyProfileIdentities: Set<NetworkProfileIdentity> = []
    @Published private(set) var currentComparisons: [NetworkProfileIdentity: [MetricComparison]] = [:]
    @Published private(set) var hasStoreError = false

    private let repository: any NetworkProfileRepository
    private let identityForSSID: (String?) -> NetworkProfileIdentity?
    private var measurements: [NetworkMeasurement] = []
    private var currentMeasurement: NetworkMeasurement?

    init(
        repository: (any NetworkProfileRepository)? = nil,
        identityForSSID: @escaping (String?) -> NetworkProfileIdentity? = NetworkProfileInstallationSecret.identity
    ) {
        self.repository = repository ?? FileNetworkProfileRepository(
            fileURL: Self.defaultStoreURL()
        )
        self.identityForSSID = identityForSSID
    }

    func refresh(currentMeasurement: NetworkMeasurement, history: [NetworkMeasurement]) async {
        measurements = Array(Set(history + [currentMeasurement]))
        self.currentMeasurement = currentMeasurement
        currentNetworkState = networkState(for: currentMeasurement)

        do {
            profiles = try await repository.profiles()
            hasStoreError = false
            recalculateReferenceStates()
        } catch {
            hasStoreError = true
        }
    }

    func retryStoreAccess() async {
        guard let currentMeasurement else { return }
        await refresh(currentMeasurement: currentMeasurement, history: measurements)
    }

    func loadProfiles() async {
        do { profiles = try await repository.profiles(); hasStoreError = false }
        catch { hasStoreError = true }
    }

    func createProfile(named name: String) async -> Bool {
        guard case .available(let identity) = currentNetworkState,
              let currentMeasurement,
              let profile = NetworkProfile(identity: identity, name: name) else {
            return false
        }
        guard let profileAtMeasurement = NetworkProfile(
            id: profile.id,
            identity: profile.identity,
            name: profile.name,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            referenceStartedAt: currentMeasurement.measuredAt
        ) else { return false }
        return await save(profileAtMeasurement)
    }

    func rename(_ profile: NetworkProfile, to name: String) async -> Bool {
        guard let updated = NetworkProfile(
            id: profile.id,
            identity: profile.identity,
            name: name,
            createdAt: profile.createdAt,
            updatedAt: Date(),
            referenceStartedAt: profile.referenceStartedAt,
            lastAnalyzedAt: profile.lastAnalyzedAt
        ) else {
            return false
        }
        return await save(updated)
    }

    /// Persiste um novo marco para a referência derivada, sem apagar o perfil
    /// ou qualquer medição do Histórico.
    func resetReference(for profile: NetworkProfile) async -> Bool {
        guard let resetProfile = NetworkProfile(
            id: profile.id,
            identity: profile.identity,
            name: profile.name,
            createdAt: profile.createdAt,
            updatedAt: Date(),
            referenceStartedAt: Date(),
            lastAnalyzedAt: profile.lastAnalyzedAt
        ) else { return false }
        return await save(resetProfile)
    }

    func remove(_ profile: NetworkProfile) async -> Bool {
        do {
            try await repository.remove(identity: profile.identity)
            profiles.removeAll { $0.identity == profile.identity }
            recalculateReferenceStates()
            return true
        } catch {
            hasStoreError = true
            return false
        }
    }

    func referenceState(for profile: NetworkProfile) -> ReferenceState {
        let count = referenceSampleCounts[profile.identity, default: 0]
        return readyProfileIdentities.contains(profile.identity)
            ? .ready(sampleCount: count)
            : .building(sampleCount: count)
    }

    func profileForCurrentNetwork() -> NetworkProfile? {
        guard case .available(let identity) = currentNetworkState else { return nil }
        return profiles.first { $0.identity == identity }
    }

    func comparison(for profile: NetworkProfile) -> [MetricComparison]? {
        currentComparisons[profile.identity]
    }

    func markAnalyzed(_ profile: NetworkProfile) async {
        guard let lastEligible = measurements
            .filter({
                $0.outcome == .complete &&
                $0.connectionKind == .wifi &&
                $0.measuredAt >= profile.referenceStartedAt &&
                identityForSSID($0.wifiContext?.ssid) == profile.identity
            })
            .map(\.measuredAt)
            .max(),
            lastEligible != profile.lastAnalyzedAt,
            let updated = NetworkProfile(
                id: profile.id,
                identity: profile.identity,
                name: profile.name,
                createdAt: profile.createdAt,
                updatedAt: Date(),
                referenceStartedAt: profile.referenceStartedAt,
                lastAnalyzedAt: lastEligible
            ) else { return }
        _ = await save(updated)
    }

    private func save(_ profile: NetworkProfile) async -> Bool {
        do {
            try await repository.upsert(profile)
            profiles = try await repository.profiles()
            hasStoreError = false
            recalculateReferenceStates()
            return true
        } catch {
            hasStoreError = true
            return false
        }
    }

    private func recalculateReferenceStates() {
        guard LinkaWiFiPreferences.isIdentificationEnabled else {
            referenceSampleCounts = [:]
            readyProfileIdentities = []
            currentComparisons = [:]
            return
        }

        let now = Date()
        let builder = NetworkBaselineBuilder { measurement in
            guard measurement.connectionKind == .wifi,
                  let ssid = measurement.wifiContext?.ssid else { return nil }
            return self.identityForSSID(ssid).map(Self.profileKey)
        }
        let comparator = NetworkBaselineComparator { measurement in
            guard let ssid = measurement.wifiContext?.ssid else { return nil }
            return self.identityForSSID(ssid).map(Self.profileKey)
        }

        var counts: [NetworkProfileIdentity: Int] = [:]
        var ready: Set<NetworkProfileIdentity> = []
        var comparisons: [NetworkProfileIdentity: [MetricComparison]] = [:]
        for profile in profiles {
            let key = Self.profileKey(profile.identity)
            let eligibleCount = measurements.filter {
                $0.outcome == .complete &&
                $0.connectionKind == .wifi &&
                $0.measuredAt >= profile.referenceStartedAt &&
                $0.measuredAt >= now.addingTimeInterval(-30 * 24 * 60 * 60) &&
                $0.measuredAt <= now &&
                self.identityForSSID($0.wifiContext?.ssid).map(Self.profileKey) == key
            }.count
            counts[profile.identity] = eligibleCount
            let referenceMeasurements = measurements.filter {
                $0.measuredAt >= profile.referenceStartedAt
            }
            let baselineMeasurements = referenceMeasurements.filter { $0.id != currentMeasurement?.id }
            if let baseline = builder.build(
                profileIdentity: key,
                measurements: baselineMeasurements,
                referenceDate: now
            ) {
                ready.insert(profile.identity)
                if let currentMeasurement,
                   case .compared(let result) = comparator.compare(current: currentMeasurement, against: baseline) {
                    comparisons[profile.identity] = result.metrics
                }
            }
        }
        referenceSampleCounts = counts
        readyProfileIdentities = ready
        currentComparisons = comparisons
    }

    private func networkState(for measurement: NetworkMeasurement) -> CurrentNetworkState {
        guard LinkaWiFiPreferences.isIdentificationEnabled else { return .identificationDisabled }
        guard measurement.connectionKind == .wifi else { return .notWiFi }
        guard let ssid = measurement.wifiContext?.ssid,
              let identity = identityForSSID(ssid) else { return .ssidUnavailable }
        // O SSID é usado somente neste ponto para derivar a identidade. Não
        // atravessa a fronteira do coordinator, portanto não pode virar nome
        // sugerido nem ser persistido indiretamente no perfil.
        return .available(identity: identity)
    }

    nonisolated private static func profileKey(_ identity: NetworkProfileIdentity) -> String {
        "v\(identity.version):\(identity.fingerprint)"
    }

    private static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Linka", isDirectory: true)
            .appendingPathComponent("network-profiles-v1.json")
    }
}

private enum NetworkProfileInstallationSecret {
    private static let service = "com.linka.network-profiles"
    private static let account = "installation-secret-v1"

    static func identity(for ssid: String?) -> NetworkProfileIdentity? {
        guard let secret = installationSecret() else { return nil }
        return NetworkProfileIdentity(ssid: ssid, installationSecret: secret)
    }

    private static func installationSecret() -> Data? {
        if let existing = KeychainHelper.shared.read(service: service, account: account), existing.count == 32 {
            return existing
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return nil }
        let generated = Data(bytes)
        KeychainHelper.shared.save(generated, service: service, account: account)
        return KeychainHelper.shared.read(service: service, account: account) == generated ? generated : nil
    }
}

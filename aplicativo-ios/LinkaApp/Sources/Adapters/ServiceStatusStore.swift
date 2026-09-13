import Foundation
import SwiftUI
import UserNotifications

/// Estado operacional externo. Nunca é usado para concluir nada sobre uma medição.
struct LinkaService: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let icon: String
    let notificationEligible: Bool
}

struct LinkaServiceIncident: Codable, Identifiable, Hashable {
    let id: String
    let serviceId: String
    let state: String
    let severity: String
    let confidence: String
    let summary: String
    let updatedAt: Date
}

@MainActor
final class ServiceStatusStore: ObservableObject {
    @Published private(set) var services: [LinkaService] = []
    @Published private(set) var incidents: [LinkaServiceIncident] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let defaults: UserDefaults
    private let session: URLSession
    private let endpoint: URL?
    private static let subscriptionsKey = "linka.serviceStatus.subscriptions"

    init(defaults: UserDefaults = .standard, session: URLSession = .shared, bundle: Bundle = .main) {
        self.defaults = defaults
        self.session = session
        self.endpoint = bundle.object(forInfoDictionaryKey: "LinkaServiceStatusEndpoint")
            .flatMap { $0 as? String }
            .flatMap(URL.init(string:))
    }

    func isFollowing(_ service: LinkaService) -> Bool {
        (defaults.stringArray(forKey: Self.subscriptionsKey) ?? []).contains(service.id)
    }

    func setFollowing(_ service: LinkaService, enabled: Bool) async {
        var subscriptions = Set(defaults.stringArray(forKey: Self.subscriptionsKey) ?? [])
        if enabled { subscriptions.insert(service.id) } else { subscriptions.remove(service.id) }
        defaults.set(Array(subscriptions).sorted(), forKey: Self.subscriptionsKey)
        guard enabled, service.notificationEligible else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    func refresh() async {
        guard let endpoint else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let catalog: [LinkaService] = fetch("catalog", from: endpoint)
            async let active: [LinkaServiceIncident] = fetch("incidents?active=true", from: endpoint)
            services = try await catalog
            incidents = try await active
            lastError = nil
        } catch { lastError = "Não foi possível atualizar o status agora." }
    }

    private func fetch<T: Decodable>(_ path: String, from endpoint: URL) async throws -> T {
        let url = endpoint.appendingPathComponent(path)
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder.serviceStatus.decode(T.self, from: data)
    }

    func incident(for service: LinkaService) -> LinkaServiceIncident? {
        incidents.first { $0.serviceId == service.id && $0.state != "resolved" }
    }
}

private extension JSONDecoder {
    static let serviceStatus: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

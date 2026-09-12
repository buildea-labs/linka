import SwiftUI

struct ServiceStatusView: View {
    @EnvironmentObject private var store: ServiceStatusStore
    @State private var query = ""

    private var visibleServices: [LinkaService] {
        guard !query.isEmpty else { return store.services }
        return store.services.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List {
            if let error = store.lastError { Text(error).foregroundStyle(.secondary) }
            if visibleServices.isEmpty && !store.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right").font(.title2).foregroundStyle(.secondary)
                    Text("Sem dados de status").font(.headline)
                    Text("Atualize novamente em alguns instantes.").font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            }
            ForEach(visibleServices) { service in
                HStack(spacing: 12) {
                    Image(systemName: service.icon).frame(width: 24).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(service.name)
                        Text(statusText(for: service)).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Receber alertas de \(service.name)", isOn: Binding(
                        get: { store.isFollowing(service) },
                        set: { enabled in Task { await store.setFollowing(service, enabled: enabled) } }
                    )).labelsHidden().disabled(!service.notificationEligible)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .searchable(text: $query, prompt: "Buscar serviço")
        .navigationTitle("Status de serviços")
        .task { await store.refresh() }
        .refreshable { await store.refresh() }
    }

    private func statusText(for service: LinkaService) -> String {
        guard let incident = store.incident(for: service) else { return "Operando normalmente" }
        switch incident.confidence {
        case "high": return incident.summary
        default: return "Há sinais de instabilidade. \(incident.summary)"
        }
    }
}

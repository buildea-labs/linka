import SwiftUI
import NetworkProfiles
import NetworkInsights

/// Continuação discreta da Otimização. Perfis não aparecem na Home e não
/// interrompem a medição; a pessoa os cria manualmente após ver o resultado.
struct NetworkProfilesSection: View {
    @ObservedObject var coordinator: OptimizationProfileCoordinator
    let isPlusActive: Bool
    let onRequestPurchase: () -> Void
    let onManageIdentification: () -> Void
    @Binding var isPresentingCreation: Bool

    var body: some View {
        Group {
            if coordinator.hasStoreError {
                Section {
                    Text(LinkaCopy.value("profiles.storeError.message"))
                        .foregroundStyle(.secondary)
                    Button(LinkaCopy.value("profiles.storeError.retry")) {
                        Task { await coordinator.retryStoreAccess() }
                    }
                }
            }
            Section(LinkaCopy.value("profiles.current.title")) {
                currentNetworkContent
            }

            if isPlusActive, !coordinator.profiles.isEmpty {
                Section(LinkaCopy.value("profiles.saved.title")) {
                    ForEach(coordinator.profiles) { profile in
                        NavigationLink {
                            NetworkProfileDetailView(profile: profile, coordinator: coordinator)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.name)
                                    .font(.body.weight(.medium))
                                Text(referenceLabel(for: profile))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("\(profile.name), \(referenceLabel(for: profile))")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var currentNetworkContent: some View {
        switch coordinator.currentNetworkState {
        case .identificationDisabled:
            Label(LinkaCopy.value("profiles.disabled.title"), systemImage: "wifi.slash")
                .foregroundStyle(.secondary)
            Text(LinkaCopy.value("profiles.disabled.message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(LinkaCopy.value("profiles.disabled.manage"), action: onManageIdentification)
        case .notWiFi:
            Label(LinkaCopy.value("profiles.notWifi.title"), systemImage: "wifi")
                .foregroundStyle(.secondary)
            Text(LinkaCopy.value("profiles.notWifi.message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .ssidUnavailable:
            Label(LinkaCopy.value("profiles.unavailable.title"), systemImage: "wifi.exclamationmark")
                .foregroundStyle(.secondary)
            Text(LinkaCopy.value("profiles.unavailable.message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .available:
            if isPlusActive, let profile = coordinator.profileForCurrentNetwork() {
                NavigationLink {
                    NetworkProfileDetailView(profile: profile, coordinator: coordinator)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.name)
                            .font(.body.weight(.medium))
                        Text(referenceLabel(for: profile))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isPlusActive {
                Text(LinkaCopy.value("profiles.create.message"))
                    .foregroundStyle(.secondary)
                Button(LinkaCopy.value("profiles.create.cta")) {
                    isPresentingCreation = true
                }
            } else {
                Text(LinkaCopy.value("profiles.preview.message"))
                    .foregroundStyle(.secondary)
                Button(LinkaCopy.value("profiles.preview.cta"), action: onRequestPurchase)
            }
        }
    }

    private func referenceLabel(for profile: NetworkProfile) -> String {
        switch coordinator.referenceState(for: profile) {
        case .ready:
            return LinkaCopy.value("profiles.reference.ready")
        case .building(let sampleCount):
            return String(
                format: LinkaCopy.value("profiles.reference.building.count"),
                sampleCount
            )
        }
    }

}

struct NetworkProfilesManagementView: View {
    @StateObject private var coordinator = OptimizationProfileCoordinator()
    let isPlusActive: Bool
    let onRequestPurchase: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if isPlusActive {
                    if coordinator.profiles.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(LinkaCopy.value("profiles.empty.title"), systemImage: "wifi")
                                .foregroundStyle(.secondary)
                            Text(LinkaCopy.value("profiles.empty.message"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(LinkaCopy.value("profiles.saved.title")) {
                            ForEach(coordinator.profiles) { profile in
                                NavigationLink(profile.name) { NetworkProfileDetailView(profile: profile, coordinator: coordinator) }
                            }
                        }
                    }
                } else {
                    Section {
                        Text(LinkaCopy.value("profiles.preview.message"))
                        Button(LinkaCopy.value("profiles.preview.cta"), action: onRequestPurchase)
                    }
                }
            }
            .navigationTitle(LinkaCopy.value("profiles.saved.title"))
            .task { await coordinator.loadProfiles() }
        }
    }
}

private struct NetworkProfileDetailView: View {
    let profile: NetworkProfile
    @ObservedObject var coordinator: OptimizationProfileCoordinator

    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingRename = false
    @State private var isConfirmingDeletion = false
    @State private var isConfirmingReferenceReset = false

    var body: some View {
        List {
            Section {
                Label(referenceLabel, systemImage: referenceIcon)
                    .accessibilityLabel(referenceLabel)
                Text(referenceExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(LinkaCopy.value("profiles.reference.reset")) {
                    isConfirmingReferenceReset = true
                }
                if let lastAnalyzedAt = profile.lastAnalyzedAt {
                    LabeledContent(LinkaCopy.value("profiles.lastAnalyzed.title")) {
                        Text(lastAnalyzedAt, format: .dateTime.day().month().year().hour().minute())
                    }
                }
            } header: {
                Text(LinkaCopy.value("profiles.reference.title"))
            } footer: {
                Text(LinkaCopy.value("profiles.reference.resetHint"))
            }

            Section(LinkaCopy.value("profiles.local.title")) {
                Button(LinkaCopy.value("profiles.rename.cta")) { isPresentingRename = true }
                Button(LinkaCopy.value("profiles.delete.cta"), role: .destructive) { isConfirmingDeletion = true }
            }

            if let comparison = coordinator.comparison(for: profile) {
                Section {
                    ForEach(comparison, id: \.metric.rawValue) { metric in
                        HStack {
                            Text(metricName(metric.metric))
                            Spacer()
                            Text("\(formatted(metric.currentValue, metric: metric.metric)) · \(formatted(metric.baselineValue, metric: metric.metric))")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("\(metricName(metric.metric)): \(LinkaCopy.value("profiles.comparison.current")) \(formatted(metric.currentValue, metric: metric.metric)), \(LinkaCopy.value("profiles.comparison.reference")) \(formatted(metric.baselineValue, metric: metric.metric))")
                    }
                } header: { Text(LinkaCopy.value("profiles.comparison.title")) } footer: {
                    Text(LinkaCopy.value("profiles.comparison.hint"))
                }
            }
        }
        .navigationTitle(profile.name)
        .task(id: profile.id) {
            await coordinator.markAnalyzed(profile)
        }
        .confirmationDialog(
            LinkaCopy.value("profiles.reference.reset"),
            isPresented: $isConfirmingReferenceReset,
            titleVisibility: .visible
        ) {
            Button(LinkaCopy.value("profiles.reference.reset"), role: .destructive) {
                Task { _ = await coordinator.resetReference(for: profile) }
            }
            Button(LinkaCopy.value("common.cancel"), role: .cancel) {}
        } message: {
            Text(LinkaCopy.value("profiles.reference.resetHint"))
        }
        .confirmationDialog(
            LinkaCopy.value("profiles.delete.title"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button(LinkaCopy.value("profiles.delete.cta"), role: .destructive) {
                Task {
                    if await coordinator.remove(profile) {
                        dismiss()
                    }
                }
            }
            Button(LinkaCopy.value("common.cancel"), role: .cancel) {}
        } message: {
            Text(LinkaCopy.value("profiles.delete.message"))
        }
        .sheet(isPresented: $isPresentingRename) {
            NetworkProfileNameEditor(
                title: LinkaCopy.value("profiles.rename.title"),
                name: profile.name,
                saveTitle: LinkaCopy.value("profiles.rename.save")
            ) { name in
                Task {
                    if await coordinator.rename(profile, to: name) {
                        isPresentingRename = false
                    }
                }
            }
        }
    }

    private var referenceIcon: String {
        coordinator.readyProfileIdentities.contains(profile.identity)
            ? "checkmark.circle"
            : "chart.line.uptrend.xyaxis"
    }

    private var referenceLabel: String {
        switch coordinator.referenceState(for: profile) {
        case .ready:
            return LinkaCopy.value("profiles.reference.ready")
        case .building(let sampleCount):
            return String(
                format: LinkaCopy.value("profiles.reference.building.count"),
                sampleCount
            )
        }
    }

    private var referenceExplanation: String {
        coordinator.readyProfileIdentities.contains(profile.identity)
            ? LinkaCopy.value("profiles.reference.readyMessage")
            : LinkaCopy.value("profiles.reference.buildingMessage")
    }

    private func metricName(_ metric: NetworkMetric) -> String {
        switch metric {
        case .downloadMbps: return LinkaCopy.value("profiles.metric.download")
        case .uploadMbps: return LinkaCopy.value("profiles.metric.upload")
        case .latencyMs: return LinkaCopy.value("profiles.metric.latency")
        case .jitterMs: return LinkaCopy.value("profiles.metric.jitter")
        case .packetLossPercent: return LinkaCopy.value("profiles.metric.loss")
        @unknown default: return metric.rawValue
        }
    }

    private func formatted(_ value: Double?, metric: NetworkMetric) -> String {
        guard let value else { return LinkaCopy.value("common.unavailable") }
        switch metric {
        case .downloadMbps, .uploadMbps: return String(format: "%.1f Mbps", value)
        case .latencyMs, .jitterMs: return String(format: "%.1f ms", value)
        case .packetLossPercent: return String(format: "%.1f%%", value)
        @unknown default: return String(format: "%.1f", value)
        }
    }
}

struct NetworkProfileNameEditor: View {
    let title: String
    let saveTitle: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(title: String, name: String, saveTitle: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.saveTitle = saveTitle
        self.onSave = onSave
        _name = State(initialValue: name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(LinkaCopy.value("profiles.name.title")) {
                    TextField(LinkaCopy.value("profiles.name.placeholder"), text: $name)
                    #if os(iOS)
                        .textInputAutocapitalization(.words)
                    #endif
                }
                Section {
                    Text(LinkaCopy.value("profiles.privacy.message"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LinkaCopy.value("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle) { onSave(name) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

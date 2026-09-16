import SwiftUI
import NetworkProfiles
import NetworkInsights

/// Continuação pós-resultado: a pessoa escolhe onde mediu sem interromper o teste.
struct NetworkProfilesSection: View {
    @ObservedObject var coordinator: OptimizationProfileCoordinator
    let isPlusActive: Bool
    let onRequestPurchase: () -> Void
    let onManageIdentification: () -> Void
    @Binding var isPresentingCreation: Bool

    var body: some View {
        Group {
            if coordinator.hasStoreError {
                Section { Text(LinkaCopy.value("environments.storeError.message")).foregroundStyle(.secondary); Button(LinkaCopy.value("environments.storeError.retry")) { Task { await coordinator.retryStoreAccess() } } }
            }
            Section(LinkaCopy.value("environments.current.title")) { currentMeasurementContent }
        }
    }

    @ViewBuilder private var currentMeasurementContent: some View {
        switch coordinator.currentNetworkState {
        case .identificationDisabled:
            Label(LinkaCopy.value("environments.disabled.title"), systemImage: "wifi.slash").foregroundStyle(.secondary)
            Text(LinkaCopy.value("environments.disabled.message")).font(.footnote).foregroundStyle(.secondary)
            Button(LinkaCopy.value("environments.disabled.manage"), action: onManageIdentification)
        case .notWiFi:
            Label(LinkaCopy.value("environments.notWifi.title"), systemImage: "wifi").foregroundStyle(.secondary)
            Text(LinkaCopy.value("environments.notWifi.message")).font(.footnote).foregroundStyle(.secondary)
        case .ssidUnavailable:
            Label(LinkaCopy.value("environments.unavailable.title"), systemImage: "wifi.exclamationmark").foregroundStyle(.secondary)
            Text(LinkaCopy.value("environments.unavailable.message")).font(.footnote).foregroundStyle(.secondary)
        case .available:
            if !isPlusActive {
                Text(LinkaCopy.value("environments.preview.message")).foregroundStyle(.secondary)
                Button(LinkaCopy.value("environments.preview.cta"), action: onRequestPurchase)
            } else if let assignment = coordinator.currentAssignment, let environment = coordinator.environments.first(where: { $0.id == assignment.environmentID }) {
                Label(LinkaCopy.format("environments.assigned", environment.name), systemImage: "checkmark.circle").foregroundStyle(.secondary)
                Text(referenceLabel(for: environment)).font(.footnote).foregroundStyle(.secondary)
                environmentPicker
                if let comparison = coordinator.comparison(for: environment) {
                    Divider()
                    Text(LinkaCopy.value("environments.comparison.title"))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(comparison, id: \.metric.rawValue) { metric in
                        LabeledContent(metricName(metric.metric)) {
                            Text("\(LinkaCopy.value("environments.comparison.current")) \(formatted(metric.currentValue, metric: metric.metric)) · \(LinkaCopy.value("environments.comparison.reference")) \(formatted(metric.baselineValue, metric: metric.metric))")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("\(metricName(metric.metric)): \(LinkaCopy.value("environments.comparison.current")) \(formatted(metric.currentValue, metric: metric.metric)), \(LinkaCopy.value("environments.comparison.reference")) \(formatted(metric.baselineValue, metric: metric.metric))")
                    }
                }
            } else {
                Text(LinkaCopy.value("environments.prompt.message")).foregroundStyle(.secondary)
                environmentPicker
            }
        }
    }

    private var environmentPicker: some View {
        Group {
            ForEach(coordinator.environments) { environment in
                Button(environment.name) { Task { _ = await coordinator.assignCurrentMeasurement(to: environment) } }
            }
            Button(LinkaCopy.value("environments.create.cta")) { isPresentingCreation = true }
        }
    }

    private func referenceLabel(for environment: NetworkEnvironment) -> String {
        switch coordinator.referenceState(for: environment) {
        case .ready: return LinkaCopy.value("environments.reference.ready")
        case .building(let count): return String(format: LinkaCopy.value("environments.reference.building.count"), count)
        }
    }

    private func metricName(_ metric: NetworkMetric) -> String {
        switch metric {
        case .downloadMbps: return LinkaCopy.value("environments.metric.download")
        case .uploadMbps: return LinkaCopy.value("environments.metric.upload")
        case .latencyMs: return LinkaCopy.value("environments.metric.latency")
        case .jitterMs: return LinkaCopy.value("environments.metric.jitter")
        case .packetLossPercent: return LinkaCopy.value("environments.metric.loss")
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

/// Settings apenas gerencia ambientes já criados; criar exige um resultado elegível.
struct NetworkProfilesManagementView: View {
    @StateObject private var coordinator = OptimizationProfileCoordinator()
    let isPlusActive: Bool
    let onRequestPurchase: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if isPlusActive {
                    if coordinator.environments.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(LinkaCopy.value("environments.empty.title"), systemImage: "mappin.and.ellipse")
                                .foregroundStyle(.secondary)
                            Text(LinkaCopy.value("environments.empty.message"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(LinkaCopy.value("environments.saved.title")) {
                            ForEach(coordinator.environments) { environment in
                                NavigationLink(environment.name) { NetworkEnvironmentDetailView(environment: environment, coordinator: coordinator) }
                            }
                        }
                    }
                } else {
                    Section { Text(LinkaCopy.value("environments.preview.message")); Button(LinkaCopy.value("environments.preview.cta"), action: onRequestPurchase) }
                }
            }
            .navigationTitle(LinkaCopy.value("environments.saved.title"))
            .task { await coordinator.loadEnvironments() }
        }
    }
}

private struct NetworkEnvironmentDetailView: View {
    let environment: NetworkEnvironment
    @ObservedObject var coordinator: OptimizationProfileCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var renamePresented = false
    @State private var deletePresented = false

    var body: some View {
        List {
            Section(LinkaCopy.value("environments.reference.title")) {
                Text(referenceLabel).foregroundStyle(.secondary)
                Text(LinkaCopy.value("environments.reference.message")).font(.footnote).foregroundStyle(.secondary)
            }
            Section(LinkaCopy.value("environments.local.title")) {
                Button(LinkaCopy.value("environments.rename.cta")) { renamePresented = true }
                Button(LinkaCopy.value("environments.delete.cta"), role: .destructive) { deletePresented = true }
            }
        }
        .navigationTitle(environment.name)
        .confirmationDialog(LinkaCopy.value("environments.delete.title"), isPresented: $deletePresented) {
            Button(LinkaCopy.value("environments.delete.cta"), role: .destructive) { Task { if await coordinator.remove(environment) { dismiss() } } }
        } message: { Text(LinkaCopy.value("environments.delete.message")) }
        .sheet(isPresented: $renamePresented) {
            NetworkProfileNameEditor(title: LinkaCopy.value("environments.rename.title"), name: environment.name, saveTitle: LinkaCopy.value("environments.rename.save")) { name in
                Task { if await coordinator.rename(environment, to: name) { renamePresented = false } }
            }
        }
    }
    private var referenceLabel: String {
        switch coordinator.referenceState(for: environment) {
        case .ready: return LinkaCopy.value("environments.reference.ready")
        case .building(let count): return String(format: LinkaCopy.value("environments.reference.building.count"), count)
        }
    }
}

struct NetworkProfileNameEditor: View {
    let title: String; let saveTitle: String; let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    init(title: String, name: String, saveTitle: String, onSave: @escaping (String) -> Void) { self.title = title; self.saveTitle = saveTitle; self.onSave = onSave; _name = State(initialValue: name) }
    var body: some View {
        NavigationStack { Form { Section(LinkaCopy.value("environments.name.title")) { TextField(LinkaCopy.value("environments.name.placeholder"), text: $name) } }
            .navigationTitle(title).toolbar { ToolbarItem(placement: .cancellationAction) { Button(LinkaCopy.value("common.cancel")) { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button(saveTitle) { onSave(name) }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } }
        }
    }
}

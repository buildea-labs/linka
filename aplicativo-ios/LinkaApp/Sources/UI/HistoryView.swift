import SwiftUI
import MapKit
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules

enum HistoryDisplayMode {
    case list
    case map
}

struct HistoryView: View {
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var measurements: [NetworkMeasurement] = []
    @State private var isLoading = true
    @State private var hasPlus = false
    @State private var showAssist = false
    @State private var showPurchase = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .historyInsights
    @State private var insightText: String?
    @State private var displayMode: HistoryDisplayMode = .list

    private var repository: any MeasurementHistoryRepository {
        LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
    }

    @ViewBuilder
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.surfacePage)
            } else {
                VStack(spacing: 0) {
                    if displayMode == .list {
                        List {
                            // Resumo da semana
                            Section {
                                Button(action: {
                                    let assistDecision = LinkaEntitlementPolicy.decision(
                                        for: .assist,
                                        snapshot: entitlements.snapshot,
                                        at: Date()
                                    )
                                    if assistDecision.isGranted {
                                        showAssist = true
                                    } else {
                                        purchaseEntryPoint = .historyInsights
                                        showPurchase = true
                                    }
                                }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Resumo da semana")
                                                .font(.bodyRegularStrong)
                                                .foregroundColor(.textPrimary)

                                            if !hasPlus {
                                                Text("Veja tendências e comparações com Linka Plus")
                                                    .font(.bodySmall)
                                                    .foregroundColor(.textSecondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            } else if let insightText {
                                                Text(insightText)
                                                    .font(.bodySmall)
                                                    .foregroundColor(.textSecondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            } else {
                                                Text("Ainda não há dados suficientes para um resumo semanal — faça alguns testes ao longo dos dias.")
                                                    .font(.bodySmall)
                                                    .foregroundColor(.textSecondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        Spacer(minLength: 8)
                                        Image(systemName: "chevron.right")
                                            .font(.captionStrong)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            // Lista de medições
                            Section("Histórico de medições") {
                                if measurements.isEmpty {
                                    Text("Nenhuma medição encontrada.")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(measurements, id: \.id) { measurement in
                                        NavigationLink(destination: HistoricalMeasurementDetailView(measurement: measurement)) {
                                            HistoryRow(measurement: measurement)
                                        }
                                    }
                                }
                            }
                        }
                        #if canImport(UIKit)
                        .listStyle(.insetGrouped)
                        #else
                        .listStyle(.automatic)
                        #endif
                    } else {
                        MapHistoryView(measurements: measurements)
                    }
                }
            }
        }
        .toolbar {
            if hasPlus {
                if FeatureFlags.isCoverageMapEnabled {
                    #if canImport(UIKit)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Picker("Modo", selection: $displayMode) {
                            Image(systemName: "list.bullet").tag(HistoryDisplayMode.list)
                            Image(systemName: "map").tag(HistoryDisplayMode.map)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }
                    #else
                    ToolbarItem {
                        Picker("Modo", selection: $displayMode) {
                            Image(systemName: "list.bullet").tag(HistoryDisplayMode.list)
                            Image(systemName: "map").tag(HistoryDisplayMode.map)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }
                    #endif
                }
            }
        }
        .navigationTitle("Histórico")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationDestination(isPresented: $showAssist) {
            AssistView(
                currentMeasurement: measurements.first,
                recentMeasurements: Array(measurements.dropFirst().prefix(20)),
                entitlements: entitlements
            )
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                showAssist = true
            }
            .environmentObject(entitlements)
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            let decision = LinkaEntitlementPolicy.decision(
                for: .insights,
                snapshot: entitlements.snapshot,
                at: Date()
            )

            hasPlus = decision.isGranted

            let query = MeasurementQuery(limit: 50, sortOrder: .newestFirst)
            measurements = (try? await repository.measurements(matching: query)) ?? []
            
            if hasPlus {
                insightText = weeklyInsightText(from: measurements)
            }

            isLoading = false
        }
    }

    private func weeklyInsightText(from measurements: [NetworkMeasurement]) -> String? {
        let now = Date()
        let cutoff7d = now.addingTimeInterval(-7 * 86_400)
        let cutoff14d = now.addingTimeInterval(-14 * 86_400)

        let last7 = measurements.filter { $0.measuredAt >= cutoff7d }
        let baseline = measurements.filter { $0.measuredAt >= cutoff14d && $0.measuredAt < cutoff7d }

        guard last7.count >= 2, baseline.count >= 2 else { return nil }

        let insightsAnalyzer = EntitlementGatedNetworkInsightsAnalyzer(
            wrapping: BasicNetworkInsightsAnalyzer(),
            snapshot: entitlements.snapshot
        )

        let comparison: NetworkPeriodComparison
        do {
            comparison = try insightsAnalyzer.comparePeriods(current: last7, baseline: baseline)
        } catch {
            return nil
        }

        guard let download = comparison.comparison(for: .downloadMbps),
              let percentDelta = download.percentDelta,
              abs(percentDelta) >= 5 else {
            return nil
        }

        let deltaStr = String(format: "%.0f", abs(percentDelta))
        switch download.direction {
        case .improved:
            return "Sua velocidade de download está cerca de \(deltaStr)% melhor esta semana em comparação à semana anterior."
        case .worsened:
            return "Sua velocidade de download está cerca de \(deltaStr)% pior esta semana em comparação à semana anterior."
        case .stable, .unavailable:
            return nil
        }
    }
}

struct HistoryRow: View {
    let measurement: NetworkMeasurement

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(networkTitle)
                    .font(.bodyRegularStrong)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatDate(measurement.measuredAt))
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)

                    Text("·")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)

                    Image(systemName: connectionIconName(for: measurement.connectionKind))
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.captionSmallStrong)
                        .foregroundColor(.brandAccentWarm)
                    Text("\(formatSpeed(measurement.downloadMbps)) Mbps")
                        .font(.bodySmallStrong)
                        .foregroundColor(.textPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                    Text("\(formatSpeed(measurement.uploadMbps)) Mbps")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var networkTitle: String {
        if measurement.connectionKind == .wifi {
            return measurement.wifiContext?.ssid ?? "Wi-Fi"
        } else if measurement.connectionKind == .cellular {
            return measurement.networkIdentifier ?? "Rede móvel"
        } else if measurement.connectionKind == .ethernet {
            return "Ethernet"
        }
        return "Medição"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }

    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "--" }
        return String(format: "%.0f", speed)
    }

    private func connectionIconName(for kind: NetworkConnectionKind?) -> String {
        switch kind {
        case .wifi: return "wifi"
        case .cellular: return "cellularbars"
        case .ethernet: return "cable.connector"
        case .other, .none: return "network"
        }
    }
}

struct MapLocationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct MapHistoryView: View {
    let measurements: [NetworkMeasurement]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.55052, longitude: -46.633308),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var locationItems: [MapLocationItem] {
        measurements.compactMap { m in
            if let loc = m.location {
                return MapLocationItem(id: m.id, coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), title: m.serverIdentifier ?? "Medição")
            }
            return nil
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locationItems) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Circle()
                    .fill(Color.brandAccentWarm)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .onAppear {
            if let first = locationItems.first {
                region.center = first.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        }
    }
}

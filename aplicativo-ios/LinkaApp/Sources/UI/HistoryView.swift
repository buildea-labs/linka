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

private enum HistoryFilter: CaseIterable {
    case all, wifi, mobile
    var label: String { switch self { case .all: return LinkaCopy.value("history.filter.all"); case .wifi: return LinkaCopy.value("network.wifi"); case .mobile: return LinkaCopy.value("history.filter.mobile") } }
}

private enum HistorySort: CaseIterable, Hashable {
    case recent
    case fastest
    case slowest

    var label: String {
        switch self {
        case .recent: return LinkaCopy.value("history.sort.recent")
        case .fastest: return LinkaCopy.value("history.sort.fastest")
        case .slowest: return LinkaCopy.value("history.sort.slowest")
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    var onSelectMeasurement: ((NetworkMeasurement) -> Void)? = nil

    @State private var measurements: [NetworkMeasurement] = []
    @State private var isLoading = true
    @State private var hasPlus = false
    @State private var showPurchase = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .historyInsights
    @State private var insightText: String?
    @State private var filter: HistoryFilter = .all
    @State private var sort: HistorySort = .recent

    private var repository: any MeasurementHistoryRepository {
        LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
    }

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        VStack(spacing: 12) {
                            Picker(LinkaCopy.value("history.filter.title"), selection: $filter) {
                                ForEach(availableFilters, id: \.self) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Menu {
                                ForEach(HistorySort.allCases, id: \.self) { option in
                                    Button {
                                        sort = option
                                    } label: {
                                        HStack {
                                            Text(option.label)
                                            if sort == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label(sort.label, systemImage: "arrow.up.arrow.down")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if hasPlus {
                        if let insightText = insightText {
                            Section(LinkaCopy.value("history.insights")) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.brandAccentWarm)
                                        .font(.bodyRegularStrong)
                                    Text(insightText)
                                        .font(.bodyRegular)
                                        .foregroundColor(.textPrimary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else if !filteredMeasurements.isEmpty {
                        Section(LinkaCopy.value("history.insights")) {
                            Button {
                                purchaseEntryPoint = .historyInsights
                                showPurchase = true
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.textSecondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LinkaCopy.value("history.plus.prompt"))
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                        LinkaPlusWordmarkView(height: 14)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmallStrong)
                                        .foregroundColor(.textSecondary.opacity(0.65))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if filteredMeasurements.isEmpty {
                        Section {
                            LinkaUnavailableState(
                                title: LinkaCopy.value("history.empty.title"),
                                message: LinkaCopy.value("history.empty.message"),
                                systemImage: "clock"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        Section(LinkaCopy.value("history.measurements")) {
                            ForEach(filteredMeasurements, id: \.id) { measurement in
                                HStack(spacing: 8) {
                                    Button {
                                        onSelectMeasurement?(measurement)
                                    } label: {
                                        PrototypeHistoryRow(measurement: measurement)
                                    }
                                    .buttonStyle(.plain)

                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(LinkaCopy.value("history.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                loadData()
            }
            .environmentObject(entitlements)
        }
        .onAppear {
            loadData()
        }
    }

    private var filteredMeasurements: [NetworkMeasurement] {
        let scoped = measurements.filter { measurement in
            switch filter {
            case .all: return true
            case .wifi: return measurement.connectionKind == .wifi
            case .mobile: return measurement.connectionKind == .cellular
            }
        }
        switch sort {
        case .recent: return scoped.sorted { $0.measuredAt > $1.measuredAt }
        case .fastest: return scoped.sorted { ($0.downloadMbps ?? 0) > ($1.downloadMbps ?? 0) }
        case .slowest: return scoped.sorted { ($0.downloadMbps ?? 0) < ($1.downloadMbps ?? 0) }
        }
    }

    private var availableFilters: [HistoryFilter] {
        #if os(macOS)
        // Um Mac não mede rede celular. Não oferecemos um filtro que nunca
        // pode ter dado real, mas preservamos a mesma consulta de histórico.
        return [.all, .wifi]
        #else
        return HistoryFilter.allCases
        #endif
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

        let deltaStr = abs(percentDelta).formatted(.number.precision(.fractionLength(0)).locale(LinkaLanguagePreference.currentLocale))
        switch download.direction {
        case .improved:
            return LinkaCopy.format("history.insight.improved", deltaStr)
        case .worsened:
            return LinkaCopy.format("history.insight.worsened", deltaStr)
        case .stable, .unavailable:
            return nil
        }
    }
}

private struct PrototypeHistoryRow: View {
    let measurement: NetworkMeasurement

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(networkTitle)
                    .font(.bodyRegularStrong)
                    .foregroundColor(.textPrimary)
                Text("\(formattedDate) · \(formattedSpeed(measurement.downloadMbps)) Mbps")
                    .font(.captionSmall)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.captionSmallStrong)
                .foregroundColor(.textSecondary.opacity(0.65))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }

    private var networkTitle: String {
        switch measurement.connectionKind {
        case .wifi: return measurement.wifiContext?.ssid ?? LinkaCopy.value("network.wifi")
        case .cellular: return measurement.networkIdentifier ?? LinkaCopy.value("network.cellular")
        case .ethernet: return "Ethernet"
        default: return LinkaCopy.value("history.measurement")
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = LinkaLanguagePreference.currentLocale
        formatter.setLocalizedDateFormatFromTemplate("dMMMjm")
        return formatter.string(from: measurement.measuredAt)
    }

    private func formattedSpeed(_ value: Double?) -> String {
        (value ?? 0).formatted(.number.precision(.fractionLength(0)).locale(LinkaLanguagePreference.currentLocale))
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
            return measurement.wifiContext?.ssid ?? LinkaCopy.value("network.wifi")
        } else if measurement.connectionKind == .cellular {
            return measurement.networkIdentifier ?? LinkaCopy.value("network.cellular")
        } else if measurement.connectionKind == .ethernet {
            return "Ethernet"
        }
        return LinkaCopy.value("history.measurement")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = LinkaLanguagePreference.currentLocale
        return formatter.string(from: date)
    }

    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "--" }
        return speed.formatted(.number.precision(.fractionLength(0)).locale(LinkaLanguagePreference.currentLocale))
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
                return MapLocationItem(id: m.id, coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), title: m.serverIdentifier ?? LinkaCopy.value("history.measurement"))
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

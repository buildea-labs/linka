import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements

struct HistoryView: View {
    @State private var measurements: [NetworkMeasurement] = []
    @State private var isLoading = true
    @State private var hasPlus = false
    @State private var showAssist = false
    @State private var insightText: String?

    let repository = FileMeasurementHistoryRepository(
        fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json")
    )

    private let insightsAnalyzer: NetworkInsightsAnalyzing = BasicNetworkInsightsAnalyzer()

    @ViewBuilder
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.surfacePage)
            } else if !hasPlus {
                // Upsell View for Free users
                VStack(spacing: 24) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.brandAccentWarm)

                    Text("Linka")
                        .font(.displayTitle)
                        .foregroundColor(.textPrimary)

                    Text("O histórico de medições e as análises de rede são exclusivos para assinantes do Linka.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button("Conhecer o Linka") {
                        // Action for Plus purchase flow
                    }
                    .font(Font.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.brandAccentWarm)
                    .clipShape(Capsule())
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.surfacePage)
            } else {
                List {
                    // Assist Insight Card — omit if we have nothing to say
                    if let insightText {
                        Section {
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.brandAccentWarm)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Insight da Semana")
                                        .font(Font.system(size: 15, weight: .semibold))
                                        .foregroundColor(.textPrimary)

                                    Text(insightText)
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Button(action: {
                                        showAssist = true
                                    }) {
                                        Text("Perguntar ao Assist")
                                            .font(Font.system(size: 11, weight: .bold))
                                            .foregroundColor(.brandAccentWarm)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // History List
                    Section(header: Text("MÊS ATUAL").font(.monoCaption).foregroundColor(.textSecondary)) {
                        if measurements.isEmpty {
                            Text("Nenhuma medição encontrada.")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(measurements, id: \.id) { measurement in
                                HistoryRow(measurement: measurement)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.surfacePage)
            }
        }
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAssist) {
            AssistSheet(
                currentMeasurement: measurements.first,
                recentMeasurements: Array(measurements.dropFirst().prefix(19))
            )
            .presentationDetents([.fraction(0.6), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            let policy = LinkaEntitlementPolicy.decision(
                for: .history,
                snapshot: .plus(status: .active, source: .subscription),
                at: Date()
            )

            hasPlus = policy.isGranted

            if hasPlus {
                let query = MeasurementQuery(limit: 50, sortOrder: .newestFirst)
                measurements = (try? await repository.measurements(matching: query)) ?? []
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

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView()
        }
    }
}

struct HistoryRow: View {
    let measurement: NetworkMeasurement
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(LinkaMotion.spring) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(measurement.measuredAt))
                            .font(.bodySmall.weight(.medium))
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: measurement.connectionKind == .wifi ? "wifi" : "cellularbars")
                                .font(.system(size: 10))
                            Text(connectionLabel(for: measurement.connectionKind))
                                .font(.monoCaption)
                        }
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.brandAccentWarm)
                            Text(formatSpeed(measurement.downloadMbps))
                                .font(.monoEyebrow)
                                .foregroundColor(.textPrimary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.textSecondary)
                            Text(formatSpeed(measurement.uploadMbps))
                                .font(.monoEyebrow)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.borderDefault)
                        .padding(.top, 4)

                    HStack {
                        DetailItem(label: "PING", value: formatPing(measurement.latencyMs))
                        Spacer()
                        DetailItem(label: "JITTER", value: formatPing(measurement.jitterMs))
                        Spacer()
                        DetailItem(label: "PERDA", value: measurement.packetLossPercent != nil ? "\(Int(measurement.packetLossPercent!))%" : "--")
                    }

                    HStack {
                        DetailItem(label: "SERVIDOR", value: measurement.serverIdentifier ?? "Automático")
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
                .padding(.top, 4)
            }
        }
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
        return String(format: "%.1f", speed)
    }

    private func formatPing(_ ping: Double?) -> String {
        guard let ping = ping else { return "--" }
        return String(format: "%.0f ms", ping)
    }

    private func connectionLabel(for kind: NetworkConnectionKind?) -> String {
        switch kind {
        case .wifi: return "WI-FI"
        case .cellular: return "REDE MÓVEL"
        case .ethernet: return "ETHERNET"
        case .other, .none: return "OUTRA"
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.monoCaption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.bodySmall.weight(.medium))
                .foregroundColor(.textPrimary)
        }
    }
}

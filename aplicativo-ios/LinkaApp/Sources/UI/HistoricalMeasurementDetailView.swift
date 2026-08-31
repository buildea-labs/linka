import SwiftUI
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules

/// Tela de detalhe de uma medição histórica.
/// Reproduz a estrutura visual leve do Resultado, focando no Download como protagonista e movendo métricas secundárias para Detalhes.
struct HistoricalMeasurementDetailView: View {
    let measurement: NetworkMeasurement
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var showShareSheet = false

    private var connectionPathReport: ConnectionPathReport? {
        ConnectionPathEvaluator().evaluate(measurement)
    }

    private var usageSuitabilityReport: UsageSuitabilityReport? {
        UsageSuitabilityEvaluator().evaluate(measurement)
    }

    private var usageQualityLevel: UsageQualityLevel? {
        guard let usageSuitabilityReport else { return nil }
        return UsageSuitabilityCopy.qualityLevel(for: usageSuitabilityReport)
    }

    private var simpleNetworkContext: String? {
        if measurement.connectionKind == .wifi {
            if let ssid = measurement.wifiContext?.ssid {
                if let band = measurement.wifiBandGHz {
                    let bandStr = band.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", band)
                        : String(format: "%.1f", band)
                    return "\(ssid) · \(bandStr) GHz"
                }
                return ssid
            }
            return "Wi-Fi"
        } else if measurement.connectionKind == .cellular {
            return "Rede móvel"
        } else if measurement.connectionKind == .ethernet {
            return "Ethernet"
        }
        return nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 1. Resultado Principal (Download único)
                VStack(spacing: 2) {
                    Text(formattedSpeed(measurement.downloadMbps))
                        .font(.heroValueHuge)
                        .foregroundColor(.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .tracking(-1)

                    Text("Mbps")
                        .font(.heroText17)
                        .foregroundColor(.textSecondary)

                    if let netContext = simpleNetworkContext {
                        Text(netContext)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 6)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 28)

                // 2. Diagnóstico Curto
                if let connectionPathReport {
                    Text(ConnectionPathCopy.shortConclusion(for: connectionPathReport))
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }

                // 3. Caminho da Conexão
                if let connectionPathReport {
                    ConnectionPathView(report: connectionPathReport)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }

                // 4. Ações de Navegação com divisores sutis
                VStack(spacing: 0) {
                    Divider()

                    NavigationLink(destination: UsageDiagnosticsView(measurement: measurement)) {
                        HStack {
                            Text("Qualidade de uso")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if let usageQualityLevel {
                                Text(usageQualityLevel.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(usageQualityLevel.color)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary.opacity(0.6))
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()

                    NavigationLink(destination: MeasurementDetailView(measurement: measurement, duration: nil)) {
                        HStack {
                            Text("Detalhes")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary.opacity(0.6))
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle(formatTitleDate(measurement.measuredAt))
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Compartilhar")
                }
            }
        }
        .shareMeasurementSheet(isPresented: $showShareSheet, measurement: measurement)
    }

    private func formattedSpeed(_ speed: Double?) -> String {
        guard let speed else { return "--" }
        return String(format: "%.1f", speed).replacingOccurrences(of: ".", with: ",")
    }

    private func formatTitleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "pt_BR")
        return "Resultado de " + formatter.string(from: date)
    }
}

import SwiftUI
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules

/// Tela dedicada aos detalhes técnicos da medição.
/// Agrupada em formato de List nativo: Velocidade, Conexão, Qualidade, Wi-Fi e Desempenho sob Carga.
struct MeasurementDetailView: View {
    let measurement: NetworkMeasurement?
    let duration: String?
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var showPurchase = false
    @State private var showShareSheet = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings

    private var canUseExpertMode: Bool {
        LinkaEntitlementPolicy.decision(
            for: .expertMode,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    private var canUseAdvancedWiFiDiagnostics: Bool {
        LinkaEntitlementPolicy.decision(
            for: .advancedWiFiDiagnostics,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    private var responsiveness: LoadResponsivenessCategory? {
        guard let measurement else { return nil }
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: measurement.latencyMs,
            loadedDownloadLatencyMs: measurement.loadedLatencyMs,
            loadedUploadLatencyMs: measurement.loadedLatencyUploadMs
        )
        return result.category == .notAssessed ? nil : result.category
    }

    var body: some View {
        List {
            // SEÇÃO VELOCIDADES
            if let measurement {
                Section("Velocidade") {
                    if let dl = measurement.downloadMbps {
                        LabeledContent("Download", value: String(format: "%.1f Mbps", dl).replacingOccurrences(of: ".", with: ","))
                    }
                    if let ul = measurement.uploadMbps {
                        LabeledContent("Upload", value: String(format: "%.1f Mbps", ul).replacingOccurrences(of: ".", with: ","))
                    }
                    if let ping = measurement.latencyMs {
                        LabeledContent("Ping", value: String(format: "%.0f ms", ping))
                    }
                }
            }

            // SEÇÃO CONEXÃO
            Section("Conexão") {
                if let measurement {
                    if measurement.connectionKind == .wifi {
                        if let ssid = measurement.wifiContext?.ssid {
                            LabeledContent("Rede Wi-Fi", value: ssid)
                            if let security = measurement.wifiContext?.securityType {
                                LabeledContent("Segurança", value: security.displayLabel)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rede Wi-Fi")
                                        .font(.bodyRegular)
                                        .foregroundColor(.textPrimary)
                                    Text("Não identificada")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Button("Identificar") {
                                    WiFiNetworkPermission.requestIdentification()
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)
                            }
                        }
                    }

                    LabeledContent("Data e hora", value: formattedDateTime(measurement.measuredAt))

                    LabeledContent("Tipo de rede", value: networkKindLabel(measurement))

                    if let provider = measurement.networkIdentifier, !provider.isEmpty {
                        LabeledContent("Provedor", value: provider)
                    }

                    if let duration, !duration.isEmpty {
                        LabeledContent("Duração", value: duration)
                    } else if let durationMs = measurement.durationMs {
                        LabeledContent("Duração", value: String(format: "%.1fs", Double(durationMs) / 1000.0).replacingOccurrences(of: ".", with: ","))
                    }
                } else {
                    Text("Nenhuma medição selecionada.")
                        .foregroundColor(.textSecondary)
                }
            }

            // SEÇÃO QUALIDADE AVANÇADA
            if let measurement {
                Section("Qualidade") {
                    if canUseExpertMode {
                        if let jitter = measurement.jitterMs {
                            LabeledContent("Jitter", value: String(format: "%.0f ms", jitter))
                        }
                        if let packetLoss = measurement.packetLossPercent {
                            LabeledContent("Perda de pacotes", value: "\(Int(packetLoss))%")
                        }
                        if let dns = measurement.dnsResolutionMs {
                            LabeledContent("Resolução DNS", value: String(format: "%.0f ms", dns))
                        }
                    } else {
                        Button {
                            purchaseEntryPoint = .settings
                            showPurchase = true
                        } label: {
                            HStack {
                                Text("Qualidade avançada")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                LinkaPlusBadge()
                                Image(systemName: "chevron.right")
                                    .font(.captionSmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
            }

            // SEÇÃO WI-FI
            if let measurement, measurement.connectionKind == .wifi {
                Section("Wi-Fi") {
                    if let gatewayIP = measurement.wifiContext?.gatewayIP {
                        let vendor = measurement.wifiContext?.gatewayVendor ?? "Roteador"
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vendor)
                                    .font(.bodyRegular)
                                    .foregroundColor(.textPrimary)
                                Text(gatewayIP)
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            if let adminURLString = measurement.wifiContext?.gatewayAdminURL,
                               let url = URL(string: adminURLString) {
                                Button("Abrir configurações") {
                                    openURL(url)
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)
                            }
                        }
                    }

                    if canUseAdvancedWiFiDiagnostics {
                        if let advanced = measurement.advancedWiFiDiagnostics {
                            if let standard = advanced.wifiStandard {
                                LabeledContent("Padrão", value: standard)
                            }
                            if let rssi = advanced.rssiDbm {
                                LabeledContent("Sinal", value: String(format: "%.0f dBm", rssi))
                            }
                            if let noise = advanced.noiseDbm {
                                LabeledContent("Ruído", value: String(format: "%.0f dBm", noise))
                            }
                            if let snr = advanced.snrDb {
                                LabeledContent("SNR", value: String(format: "%.0f dB", snr))
                            }
                            if let channel = advanced.channelNumber {
                                LabeledContent("Canal", value: "\(channel)")
                            }
                            if advanced.txRateMbps != nil || advanced.rxRateMbps != nil {
                                let tx = advanced.txRateMbps.map { String(format: "TX %.0f Mbps", $0) }
                                let rx = advanced.rxRateMbps.map { String(format: "RX %.0f Mbps", $0) }
                                LabeledContent("Taxa Wi-Fi", value: [tx, rx].compactMap { $0 }.joined(separator: " · "))
                            }
                        } else {
                            HStack {
                                Text("Diagnóstico Wi-Fi detalhado")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                #if os(iOS)
                                Button("Obter detalhes") {
                                    if let url = URL(string: "shortcuts://run-shortcut?name=Linka%20Wi-Fi%20Advanced") { openURL(url) }
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)
                                #endif
                            }
                        }
                    } else {
                        Button {
                            purchaseEntryPoint = .advancedWiFi
                            showPurchase = true
                        } label: {
                            HStack {
                                Text("Wi-Fi avançado")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                LinkaPlusBadge()
                                Image(systemName: "chevron.right")
                                    .font(.captionSmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
            }

            // SEÇÃO DESEMPENHO SOB CARGA
            if let measurement, measurement.loadedLatencyMs != nil || measurement.loadedLatencyUploadMs != nil || responsiveness != nil {
                Section("Desempenho sob carga") {
                    if let responsiveness {
                        LabeledContent("Responsividade", value: LoadResponsivenessCopy.label(for: responsiveness))
                    }
                    if let loadedDl = measurement.loadedLatencyMs {
                        LabeledContent("Latência em download", value: String(format: "%.0f ms", loadedDl))
                    }
                    if let loadedUl = measurement.loadedLatencyUploadMs {
                        LabeledContent("Latência em upload", value: String(format: "%.0f ms", loadedUl))
                    }
                }
            }
        }
        .navigationTitle("Detalhes da medição")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let measurement {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .shareMeasurementSheet(isPresented: $showShareSheet, measurement: measurement)
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint)
                .environmentObject(entitlements)
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }

    private func networkKindLabel(_ m: NetworkMeasurement) -> String {
        var base: String
        switch m.connectionKind {
        case .wifi: base = "Wi-Fi"
        case .cellular: base = "Rede móvel"
        case .ethernet: base = "Ethernet"
        case .other, .none: base = "Conexão de rede"
        }

        if let band = m.wifiBandGHz {
            let bandStr = band.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", band)
                : String(format: "%.1f", band)
            base += " · \(bandStr) GHz"
        }
        return base
    }
}

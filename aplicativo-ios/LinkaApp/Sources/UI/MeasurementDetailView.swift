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
    /// Um registro histórico não é alterado por telemetria posterior. Esta
    /// ação retorna à jornada que coleta os detalhes antes de uma nova medida.
    let onStartNewMeasurementWithAdvancedWiFi: (() -> Void)?
    /// Reteste parte do registro selecionado, sem depender do tipo de rede
    /// ou do plano. Diagnósticos avançados continuam uma ação adicional.
    let onStartNewMeasurement: (() -> Void)?
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var showPurchase = false
    @State private var showShareSheet = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings

    init(
        measurement: NetworkMeasurement?,
        duration: String?,
        onStartNewMeasurement: (() -> Void)? = nil,
        onStartNewMeasurementWithAdvancedWiFi: (() -> Void)? = nil
    ) {
        self.measurement = measurement
        self.duration = duration
        self.onStartNewMeasurement = onStartNewMeasurement
        self.onStartNewMeasurementWithAdvancedWiFi = onStartNewMeasurementWithAdvancedWiFi
    }

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

    private var responsivenessResult: LoadResponsivenessResult? {
        guard let measurement else { return nil }
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: measurement.latencyMs,
            loadedDownloadLatencyMs: measurement.loadedLatencyMs,
            loadedUploadLatencyMs: measurement.loadedLatencyUploadMs
        )
        return result.category == .notAssessed ? nil : result
    }

    var body: some View {
        List {
            // SEÇÃO VELOCIDADES
            if let measurement {
                Section(LinkaCopy.value("detail.speed")) {
                    if let dl = measurement.downloadMbps {
                        LabeledContent(LinkaCopy.value("detail.download"), value: speed(dl))
                    }
                    if let ul = measurement.uploadMbps {
                        LabeledContent(LinkaCopy.value("detail.upload"), value: speed(ul))
                    }
                    if let ping = measurement.latencyMs {
                        LabeledContent(LinkaCopy.value("detail.ping"), value: milliseconds(ping))
                    }
                }
            }

            if let onStartNewMeasurement {
                Section {
                    Button("Testar novamente") {
                        onStartNewMeasurement()
                    }
                }
            }

            // SEÇÃO CONEXÃO
            Section(LinkaCopy.value("detail.connection")) {
                if let measurement {
                    if measurement.connectionKind == .wifi {
                        if let ssid = measurement.wifiContext?.ssid {
                            LabeledContent(LinkaCopy.value("detail.wifiNetwork"), value: ssid)
                            if let security = measurement.wifiContext?.securityType {
                                LabeledContent(LinkaCopy.value("detail.security"), value: security.displayLabel)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LinkaCopy.value("detail.wifiNetwork"))
                                        .font(.bodyRegular)
                                        .foregroundColor(.textPrimary)
                                    Text(LinkaCopy.value("detail.unidentified"))
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Button(LinkaCopy.value("detail.identify")) {
                                    WiFiNetworkPermission.requestIdentification()
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)
                            }
                        }
                    }

                    LabeledContent(LinkaCopy.value("detail.dateTime"), value: formattedDateTime(measurement.measuredAt))

                    LabeledContent(LinkaCopy.value("detail.networkType"), value: networkKindLabel(measurement))

                    if let provider = measurement.networkIdentifier, !provider.isEmpty {
                        LabeledContent(LinkaCopy.value("detail.provider"), value: provider)
                    }

                    if let duration, !duration.isEmpty {
                        LabeledContent(LinkaCopy.value("detail.duration"), value: duration)
                    } else if let durationMs = measurement.durationMs {
                        LabeledContent(LinkaCopy.value("detail.duration"), value: seconds(Double(durationMs) / 1000.0))
                    }
                } else {
                    Text(LinkaCopy.value("detail.noMeasurement"))
                        .foregroundColor(.textSecondary)
                }
            }

            // SEÇÃO QUALIDADE AVANÇADA
            if let measurement {
                Section(LinkaCopy.value("detail.quality")) {
                    if canUseExpertMode {
                        if let jitter = measurement.jitterMs {
                            LabeledContent("Jitter", value: String(format: "%.0f ms", jitter))
                        }
                        if let packetLoss = measurement.packetLossPercent {
                            LabeledContent(LinkaCopy.value("detail.packetLoss"), value: "\(Int(packetLoss))%")
                        }
                        if let dns = measurement.dnsResolutionMs {
                            LabeledContent(LinkaCopy.value("detail.dns"), value: milliseconds(dns))
                        }
                    } else {
                        Button {
                            purchaseEntryPoint = .settings
                            showPurchase = true
                        } label: {
                            HStack {
                                Text(LinkaCopy.value("detail.advancedQuality"))
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
                Section(LinkaCopy.value("network.wifi")) {
                    if let gatewayIP = measurement.wifiContext?.gatewayIP {
                        let vendor = measurement.wifiContext?.gatewayVendor ?? LinkaCopy.value("router.defaultName")
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
                                #if os(macOS)
                                Text(LinkaCopy.value("detail.routerConfirmation"))
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                #else
                                Button(LinkaCopy.value("detail.openRouter")) {
                                    openURL(url)
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)
                                #endif
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
                            if let band = advanced.bandGHz {
                                LabeledContent("Banda", value: band == floor(band) ? String(format: "%.0f GHz", band) : String(format: "%.1f GHz", band))
                            }
                            if advanced.txRateMbps != nil || advanced.rxRateMbps != nil {
                                let tx = advanced.txRateMbps.map { String(format: "TX %.0f Mbps", $0) }
                                let rx = advanced.rxRateMbps.map { String(format: "RX %.0f Mbps", $0) }
                                LabeledContent("Taxa Wi-Fi", value: [tx, rx].compactMap { $0 }.joined(separator: " · "))
                            }
                        } else {
                            LabeledContent("Diagnóstico Wi-Fi detalhado", value: "Não coletado nesta medição")

                            if let onStartNewMeasurementWithAdvancedWiFi {
                                Button("Fazer nova medição com detalhes") {
                                    onStartNewMeasurementWithAdvancedWiFi()
                                }
                                .font(.bodySmallStrong)
                                .foregroundColor(.brandAccentWarm)

                                Text("Os detalhes são coletados antes da nova medição e não alteram este registro.")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
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
            if let measurement, measurement.loadedLatencyMs != nil || measurement.loadedLatencyUploadMs != nil || responsivenessResult != nil {
                Section("Desempenho sob carga") {
                    if let result = responsivenessResult {
                        LabeledContent("Responsividade", value: LoadResponsivenessCopy.label(for: result.category))
                        
                        Text(LoadResponsivenessCopy.explanation(for: result.category))
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 8)
                    }
                    
                    if let ping = measurement.latencyMs {
                        LabeledContent("Em repouso", value: String(format: "%.0f ms", ping))
                    } else {
                        LabeledContent("Em repouso", value: "Não avaliada")
                    }

                    if let loadedDl = measurement.loadedLatencyMs {
                        VStack(alignment: .leading, spacing: 2) {
                            LabeledContent("Durante download", value: String(format: "%.0f ms", loadedDl))
                            if let delta = responsivenessResult?.downloadComparison.absoluteDelta, delta > 0 {
                                Text(String(format: "+%.0f ms", delta))
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    } else {
                        LabeledContent("Durante download", value: "Não avaliada")
                    }
                    
                    if let loadedUl = measurement.loadedLatencyUploadMs {
                        VStack(alignment: .leading, spacing: 2) {
                            LabeledContent("Durante upload", value: String(format: "%.0f ms", loadedUl))
                            if let delta = responsivenessResult?.uploadComparison.absoluteDelta, delta > 0 {
                                Text(String(format: "+%.0f ms", delta))
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    } else {
                        LabeledContent("Durante upload", value: "Não avaliada")
                    }
                }
            }
        }
        .navigationTitle(LinkaCopy.value("detail.title"))
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
        formatter.locale = LinkaLanguagePreference.currentLocale
        return formatter.string(from: date)
    }

    private func speed(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(1)).locale(LinkaLanguagePreference.currentLocale)) + " Mbps" }
    private func milliseconds(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0)).locale(LinkaLanguagePreference.currentLocale)) + " ms" }
    private func seconds(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(1)).locale(LinkaLanguagePreference.currentLocale)) + " s" }

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

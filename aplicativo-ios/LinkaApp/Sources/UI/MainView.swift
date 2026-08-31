import SwiftUI
import LinkaEngine
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules
import NetworkConnectivityTriage

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared

    @State private var showPurchase: Bool = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showAssist: Bool = false
    @State private var showConnectivityTriage: Bool = false
    @State private var showExpertModeMigrationBanner: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @Namespace private var animation

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentMeasurement: NetworkMeasurement? {
        guard viewModel.uiPhase == .done else { return nil }
        return NetworkMeasurement(
            outcome: .complete,
            downloadMbps: viewModel.downloadSpeed,
            uploadMbps: viewModel.uploadSpeed,
            latencyMs: Double(viewModel.ping),
            jitterMs: viewModel.jitter,
            packetLossPercent: viewModel.packetLossPercent,
            loadedLatencyMs: viewModel.loadedLatencyMs,
            loadedLatencyUploadMs: viewModel.loadedLatencyUploadMs,
            dnsResolutionMs: viewModel.dnsResolutionMs,
            connectionKind: viewModel.connectionKind,
            wifiBandGHz: viewModel.wifiBandGHz,
            wifiContext: viewModel.wifiContext,
            advancedWiFiDiagnostics: viewModel.advancedWiFiDiagnostics,
            networkIdentifier: viewModel.provider.isEmpty ? nil : viewModel.provider
        )
    }

    private var isPlusActive: Bool {
        LinkaEntitlementPolicy.decision(
            for: .assist,
            snapshot: entitlements.snapshot,
            at: Date()
        ).isGranted
    }

    private var canUseUsageDiagnostics: Bool {
        LinkaEntitlementPolicy.decision(
            for: .usageDiagnostics,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    private var connectionPathReport: ConnectionPathReport? {
        if viewModel.uiPhase == .done, let currentMeasurement {
            return ConnectionPathEvaluator().evaluate(currentMeasurement)
        }
        return nil
    }

    private var usageSuitabilityReport: UsageSuitabilityReport? {
        guard let currentMeasurement else { return nil }
        return UsageSuitabilityEvaluator().evaluate(currentMeasurement)
    }

    private var usageContextForAssist: String? {
        guard let usageSuitabilityReport else { return nil }
        return UsageDiagnosticsAssistBridge.assistSummary(for: usageSuitabilityReport)
    }

    private var usageQualityLevel: UsageQualityLevel? {
        guard let usageSuitabilityReport else { return nil }
        return UsageSuitabilityCopy.qualityLevel(for: usageSuitabilityReport)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePage.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.uiPhase == .error {
                        errorView
                    } else if viewModel.uiPhase == .idle {
                        idleView
                    } else if viewModel.uiPhase == .connecting || viewModel.uiPhase == .downloading || viewModel.uiPhase == .uploading {
                        measuringView
                    } else {
                        resultView
                    }
                }
            }
            .navigationTitle("Linka")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.uiPhase == .idle || viewModel.uiPhase == .done || viewModel.uiPhase == .error {
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .medium))
                                .accessibilityLabel("Histórico")
                        }

                        NavigationLink(destination: SettingsSheet()) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .accessibilityLabel("Ajustes")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showAssist) {
                AssistProblemSelectionView(
                    currentMeasurement: currentMeasurement,
                    recentMeasurements: viewModel.recentMeasurements,
                    usageContext: usageContextForAssist,
                    onRetry: { viewModel.startTest() },
                    onShowDetails: nil,
                    entitlements: entitlements
                )
            }
        }
        .onChange(of: intentCoordinator.pendingStartSpeedTest) { pending in
            guard pending else { return }
            viewModel.startTest()
            intentCoordinator.consumeStartSpeedTestRequest()
        }
        .onChange(of: intentCoordinator.pendingAdvancedWiFiDiagnosticsImport) { pending in
            guard pending else { return }
            viewModel.consumePendingAdvancedWiFiDiagnostics()
            intentCoordinator.consumeAdvancedWiFiDiagnosticsImport()
        }
        .onChange(of: intentCoordinator.pendingPurchasePrompt) { pending in
            guard pending else { return }
            purchaseEntryPoint = .settings
            showPurchase = true
            intentCoordinator.consumePurchasePrompt()
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                if purchaseEntryPoint == .assist { showAssist = true }
            }
            .environmentObject(entitlements)
        }
        .sheet(isPresented: $showConnectivityTriage) {
            NavigationStack {
                ConnectivityTriageView(onRetry: { viewModel.startTest() })
            }
        }
        .sheet(isPresented: $showExpertModeMigrationBanner, onDismiss: {
            ExpertModeMigrationBannerState.markSeen()
        }) {
            ExpertModeMigrationBanner(
                onOpenPurchase: {
                    showExpertModeMigrationBanner = false
                    purchaseEntryPoint = .settings
                    showPurchase = true
                },
                onDismiss: { showExpertModeMigrationBanner = false }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            viewModel.refreshLiveNetwork()
        }
        .animation(reduceMotion ? nil : LinkaMotion.spring, value: viewModel.uiPhase)
        .onChange(of: scenePhase) { newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
        .onChange(of: viewModel.uiPhase) { newPhase in
            if newPhase != .error {
                showConnectivityTriage = false
            }
            switch newPhase {
            case .uploading:
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                if !reduceMotion {
                    withAnimation(LinkaMotion.pulse) {
                        ringScale = 1.05
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(LinkaMotion.pulse) {
                            ringScale = 1.0
                        }
                    }
                }
            case .downloading, .done:
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            default:
                break
            }

            if newPhase == .done, !isPlusActive, !ExpertModeMigrationBannerState.hasBeenSeen() {
                showExpertModeMigrationBanner = true
            }

            if newPhase == .done,
               let category = connectionPathReport?.category,
               category != .healthy {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                #endif
            }
        }
    }

    // MARK: - Subviews

    // 1. Início (Idle)
    private var idleView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Pronto para analisar")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                let networkText = !viewModel.liveNetworkLabel.isEmpty ? viewModel.liveNetworkLabel : (simpleNetworkContext ?? "Conexão de rede")
                Text(networkText)
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Botão Principal Analisar
            Button(action: {
                withAnimation {
                    viewModel.startTest()
                }
            }) {
                Text("Analisar conexão")
                    .font(.buttonLabel)
                    .foregroundColor(Color.surfacePage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            // Resumo do último teste se houver
            if let latest = viewModel.latestFinishedMeasurement {
                NavigationLink(destination: HistoricalMeasurementDetailView(measurement: latest)) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Última análise")
                                .font(.captionSmall)
                                .foregroundColor(.textSecondary)

                            let shortDiag = ConnectionPathCopy.shortConclusion(for: ConnectionPathEvaluator().evaluate(latest))
                            Text("\(shortDiag) • \(formatRelativeTime(latest.measuredAt))")
                                .font(.bodySmallStrong)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.captionSmall)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 24)
            } else {
                Spacer().frame(height: 28)
            }
        }
    }

    // 2. Medindo (Connecting / Downloading / Uploading)
    private var measuringView: some View {
        VStack(spacing: 0) {
            Spacer()

            MetricRing(
                connecting: viewModel.uiPhase == .connecting,
                progress: viewModel.progress,
                value: ringValue,
                unit: viewModel.uiPhase == .connecting ? nil : "Mbps",
                size: 160,
                animation: animation,
                matchedId: "downloadValue"
            )
            .scaleEffect(ringScale)
            .padding(.bottom, 28)

            Text(phaseLabel)
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .padding(.bottom, 14)

            PhaseDots(
                phases: [
                    (key: "downloading", label: "Download"),
                    (key: "uploading", label: "Upload")
                ],
                activeKey: activePhaseKey
            )

            Button(action: {
                viewModel.skipOrCancel()
            }) {
                Text(viewModel.hasValidResult ? "Cancelar" : "Pular")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            Spacer()
        }
    }

    // 3. Resultado (Done)
    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 1. Resultado Principal (Download único como protagonista)
                VStack(spacing: 2) {
                    Group {
                        if !reduceMotion {
                            Text(String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ","))
                                .matchedGeometryEffect(id: "downloadValue", in: animation)
                        } else {
                            Text(String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ","))
                        }
                    }
                    .font(.heroValueHuge)
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .tracking(-1)
                    .accessibilityLabel("\(formatted(viewModel.downloadSpeed)) megabits por segundo")

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

                // 3. Caminho da Conexão Discreto
                if let connectionPathReport {
                    ConnectionPathView(report: connectionPathReport)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }

                // 4. Ações de Navegação Limpas
                VStack(spacing: 0) {
                    Divider()

                    // Entender o resultado
                    Button {
                        if isPlusActive {
                            showAssist = true
                        } else {
                            purchaseEntryPoint = .assist
                            showPurchase = true
                        }
                    } label: {
                        HStack {
                            Text("Entender o resultado")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if !isPlusActive {
                                PlusBadge()
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

                    // Qualidade de uso
                    NavigationLink(destination: UsageDiagnosticsView(measurement: currentMeasurement)) {
                        HStack {
                            Text("Qualidade de uso")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if let usageQualityLevel {
                                Text(usageQualityLevel.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(usageQualityLevel.color)
                            } else if !canUseUsageDiagnostics {
                                PlusBadge()
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

                    // Detalhes
                    NavigationLink(destination: MeasurementDetailView(measurement: currentMeasurement, duration: viewModel.testDuration)) {
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
                .padding(.bottom, 28)

                if !isPlusActive && FeatureFlags.isAdsEnabled {
                    BannerView()
                        .padding(.bottom, 20)
                }

                // Botão Primário Testar Novamente
                Button(action: {
                    viewModel.startTest()
                }) {
                    Text("Testar novamente")
                        .font(.buttonLabel)
                        .foregroundColor(Color.surfacePage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    // 4. Erro (Error)
    private var errorView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.textSecondary)

            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)

                Text(errorMessage)
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Button(action: {
                viewModel.startTest()
            }) {
                Text("Tentar novamente")
                    .font(.buttonLabel)
                    .foregroundColor(Color.surfacePage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            Button("Verificar conexão") {
                showConnectivityTriage = true
            }
            .font(.bodySmallStrong)
            .foregroundColor(.textPrimary)
            .frame(minHeight: 44)
            .accessibilityHint("Mostra os fatos de conexão observados neste aparelho")

            Spacer()
        }
    }

    // MARK: - Helpers

    private var simpleNetworkContext: String? {
        if viewModel.connectionKind == .wifi {
            if let ssid = viewModel.wifiContext?.ssid {
                if let band = viewModel.wifiBandGHz {
                    let bandStr = band.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", band)
                        : String(format: "%.1f", band)
                    return "\(ssid) · \(bandStr) GHz"
                }
                return ssid
            }
            return "Wi-Fi"
        } else if viewModel.connectionKind == .cellular {
            return "Rede móvel"
        } else if viewModel.connectionKind == .ethernet {
            return "Ethernet"
        }
        return nil
    }

    private var ringValue: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Preparando"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .uploading, .done:
            return String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ",")
        case .error:
            return ""
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private var phaseLabel: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Conectando ao servidor mais próximo…"
        case .downloading:
            return "Medindo velocidade de download…"
        case .uploading, .done:
            return "Medindo velocidade de upload…"
        case .error:
            return ""
        }
    }

    private var activePhaseKey: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return ""
        case .downloading:
            return "downloading"
        case .uploading, .done:
            return "uploading"
        case .error:
            return ""
        }
    }

    private var errorTitle: String {
        switch viewModel.failureReason {
        case .offline:
            return "Sem conexão"
        case .connectionLost:
            return "Conexão perdida"
        case nil:
            return "Não foi possível medir"
        }
    }

    private var errorMessage: String {
        switch viewModel.failureReason {
        case .offline:
            return "Verifique sua conexão com a internet e tente novamente."
        case .connectionLost:
            return "A conexão foi interrompida durante o teste."
        case nil:
            return "Algo interrompeu a medição. Tente novamente."
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Hoje, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Ontem, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "d MMM, HH:mm"
            return formatter.string(from: date)
        }
    }
}

private struct PlusBadge: View {
    var body: some View {
        Text("Plus")
            .font(.captionSmallStrong)
            .foregroundColor(.brandAccentWarm)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.brandAccentWarm.opacity(0.12))
            .clipShape(Capsule())
    }
}

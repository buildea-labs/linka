import SwiftUI
import LinkaEngine
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules
import NetworkConnectivityTriage

enum AppRoute: Hashable {
    case settings
    case history
    case measurementDetail(NetworkMeasurement)
}

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared

    @State private var navPath = NavigationPath()
    @State private var showMoreMetrics: Bool = false
    @State private var showPurchase: Bool = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showAssist: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showDetails: Bool = false
    @State private var showUsage: Bool = false
    @State private var showConnectionPath: Bool = false
    @State private var showConnectivityTriage: Bool = false
    @State private var showExpertModeMigrationBanner: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @Namespace private var animation

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(LinkaWiFiPreferences.advancedConfiguredKey) private var advancedWiFiConfigured = false
    @AppStorage(LinkaWiFiPreferences.advancedDiagnosticsEnabledKey) private var advancedWiFiEnabled = true

    private var currentMeasurement: NetworkMeasurement? {
        guard viewModel.uiPhase == .done else { return nil }
        return NetworkMeasurement(
            outcome: .complete,
            downloadMbps: viewModel.downloadSpeed > 0 ? viewModel.downloadSpeed : nil,
            uploadMbps: viewModel.uploadSpeed > 0 ? viewModel.uploadSpeed : nil,
            latencyMs: viewModel.ping > 0 ? Double(viewModel.ping) : nil,
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

    private var measurementForAssist: NetworkMeasurement? {
        if viewModel.uiPhase == .done {
            return currentMeasurement
        }
        return viewModel.latestFinishedMeasurement ?? viewModel.recentMeasurements.first
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

    private var videoCallVerdict: (label: String, color: Color) {
        let dl = viewModel.downloadSpeed
        let ul = viewModel.uploadSpeed
        let ping = Double(viewModel.ping)
        let loss = viewModel.packetLossPercent ?? 0

        if dl >= 15 && ul >= 5 && ping <= 60 && loss < 2 {
            return ("Bom", .statusGood)
        } else if dl >= 5 && ul >= 1.5 && ping <= 120 && loss < 5 {
            return ("Regular", .statusAttention)
        } else {
            return ("Ruim", .statusCritical)
        }
    }

    private var gamingVerdict: (label: String, color: Color) {
        let ping = Double(viewModel.ping)
        let jitter = viewModel.jitter
        let loss = viewModel.packetLossPercent ?? 0

        if ping <= 40 && jitter <= 20 && loss < 1 {
            return ("Bom", .statusGood)
        } else if ping <= 90 && loss < 3 {
            return ("Regular", .statusAttention)
        } else {
            return ("Ruim", .statusCritical)
        }
    }

    private var streamingVerdict: (label: String, color: Color) {
        let dl = viewModel.downloadSpeed
        let loss = viewModel.packetLossPercent ?? 0

        if dl >= 25 && loss < 2 {
            return ("4K", .statusGood)
        } else if dl >= 10 {
            return ("HD", .statusGood)
        } else {
            return ("SD", .statusAttention)
        }
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color.surfacePage.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.uiPhase == .error {
                        errorView
                    } else if viewModel.uiPhase == .connectionChanged {
                        connectionChangedView
                    } else if viewModel.uiPhase == .idle {
                        idleView
                    } else if viewModel.uiPhase == .connecting || viewModel.uiPhase == .downloading || viewModel.uiPhase == .uploading {
                        measuringView
                    } else {
                        resultView
                    }
                }
            }
            .navigationTitle("Início")
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                        .environmentObject(entitlements)
                case .history:
                    HistoryView(onSelectMeasurement: { measurement in
                        navPath.append(AppRoute.measurementDetail(measurement))
                    })
                    .environmentObject(entitlements)
                case .measurementDetail(let measurement):
                    HistoricalMeasurementDetailView(measurement: measurement)
                        .environmentObject(entitlements)
                }
            }
            .overlay(alignment: .topLeading) {
                if viewModel.uiPhase == .done {
                    Button {
                        withAnimation {
                            viewModel.resetToIdle()
                        }
                    } label: {
                        Image(systemName: "house")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Voltar para o início")
                    .padding(.leading, 16)
                    .padding(.top, 12)
                }
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.uiPhase == .idle || viewModel.uiPhase == .done || viewModel.uiPhase == .error || viewModel.uiPhase == .connectionChanged {
                    HStack(spacing: 12) {
                        if viewModel.uiPhase == .idle || viewModel.uiPhase == .error || viewModel.uiPhase == .connectionChanged {
                            Button { navPath.append(AppRoute.history) } label: {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .accessibilityLabel("Histórico")
                        }
                        if viewModel.uiPhase == .done {
                            Button {
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .accessibilityLabel("Compartilhar resultado")
                        }
                        Button { navPath.append(AppRoute.settings) } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .accessibilityLabel("Ajustes")
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }
            }
            .sheet(isPresented: $showAssist) {
                AssistView(
                    currentMeasurement: measurementForAssist,
                    recentMeasurements: viewModel.recentMeasurements,
                    usageContext: usageContextForAssist,
                    onRetry: {
                        showAssist = false
                        viewModel.startTest()
                    },
                    onShowDetails: { showDetails = true },
                    entitlements: entitlements,
                    onCloseSheet: { showAssist = false }
                )
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
            ConnectivityTriageView(onRetry: { viewModel.startTest() })
        }
        .shareMeasurementSheet(isPresented: $showShareSheet, measurement: currentMeasurement)
        .sheet(isPresented: $showDetails) {
            NavigationStack {
                MeasurementDetailView(measurement: currentMeasurement, duration: viewModel.testDuration)
                    .environmentObject(entitlements)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Voltar") {
                                showDetails = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showUsage) {
            UsageDiagnosticsView(measurement: currentMeasurement)
        }
        .sheet(isPresented: $showConnectionPath) {
            if let connectionPathReport { ConnectionPathDetailView(report: connectionPathReport) }
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
    }

    // MARK: - Subviews

    // 1. Início (Idle)
    private var idleView: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    LiveConnectionPathView(
                        kind: viewModel.liveConnectionKind,
                        label: viewModel.liveNetworkLabel
                    )
                    .padding(.top, 100)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 34)

                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.statusGood)
                        
                        Text(heroStateTitle)
                            .font(.displayMedium)
                            .foregroundColor(.textPrimary)
                        
                        Text(heroStateSubtitle)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 38)

                    VStack(spacing: 12) {
                        // Botão Primário Analisar Rede
                        Button(action: {
                            startSpeedTest()
                        }) {
                            Text("Analisar rede")
                                .multilineTextAlignment(.center)
                        }
                        .buttonStyle(.linkaPrimary)

                        // Card do Último Teste
                        if let latest = viewModel.latestFinishedMeasurement {
                            Button {
                                navPath.append(AppRoute.history)
                            } label: {
                                HStack(alignment: .center, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Último teste")
                                            .font(.bodySmallStrong)
                                            .foregroundColor(.textPrimary)
                                        Text("\(formatted(latest.downloadMbps ?? 0)) Mbps · \(formatRelativeTime(latest.measuredAt))")
                                            .font(.monoCaption)
                                            .foregroundColor(.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmall)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 52)
                                .linkaCard()
                            }
                            .buttonStyle(.plain)
                        }

                        // Card Assist
                        Button {
                            if isPlusActive {
                                showAssist = true
                            } else {
                                purchaseEntryPoint = .assist
                                showPurchase = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Assist ✦")
                                    .font(.monoCaption)
                                    .textCase(.uppercase)
                                    .foregroundColor(.brandAccentWarm)
                                Text(usageContextForAssist ?? "Problemas na sua conexão? Entenda o que está acontecendo.")
                                    .font(.captionSmall)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .linkaCard()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
                .frame(minHeight: proxy.size.height)
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
                // Título: Velocidade (abaixo dos botões superiores da topbar)
                Text("Velocidade")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 64)

                // 1. Download Hero em número inteiro ocupando toda a largura
                VStack(spacing: 2) {
                    Text("\(Int(round(viewModel.downloadSpeed)))")
                        .font(.heroValueHuge)
                        .foregroundColor(.textPrimary)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)

                    Text("Mbps download")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)

                // 2. Botão "Mais" com seta para baixo
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showMoreMetrics.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("Mais")
                            .font(.bodySmallStrong)
                        Image(systemName: showMoreMetrics ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, showMoreMetrics ? 14 : 22)

                // Demais métricas reveladas: Upload, Ping e Perdas lado a lado
                if showMoreMetrics {
                    HStack(spacing: 0) {
                        metricColumn(title: "Upload", value: "\(Int(round(viewModel.uploadSpeed)))", unit: "Mbps")
                        Divider().frame(height: 32)
                        metricColumn(title: "Ping", value: "\(viewModel.ping)", unit: "ms")
                        Divider().frame(height: 32)
                        metricColumn(title: "Perdas", value: "\(Int(round(viewModel.packetLossPercent ?? 0)))", unit: "%")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 3. Casos de Uso (Vídeo, Jogos, Streaming) estilo caminho de rede
                ResultUsageCasesView(
                    videoCall: videoCallVerdict,
                    gaming: gamingVerdict,
                    streaming: streamingVerdict
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 18)

                // 4. CTA para o Assist: "Problemas com sua conexão?"
                Button {
                    if isPlusActive {
                        showAssist = true
                    } else {
                        purchaseEntryPoint = .assist
                        showPurchase = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Problemas com sua conexão?")
                                .font(.bodyRegularStrong)
                                .foregroundColor(.textPrimary)
                            Text("Consulte o Assist para um diagnóstico detalhado.")
                                .font(.captionSmall)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.brandAccentWarm)
                            .frame(width: 36, height: 36)
                            .background(Color.brandAccentWarm.opacity(0.12), in: Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // 5. Botão Testar Novamente
                Button(action: {
                    startSpeedTest()
                }) {
                    Text("Testar novamente")
                }
                .buttonStyle(.linkaPrimary)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func metricColumn(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
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
                startSpeedTest()
            }) {
                Text("Tentar novamente")
            }
            .buttonStyle(.linkaPrimary)
            .padding(.horizontal, 24)
            .padding(.top, 4)

            Button("Verificar conexão") {
                showConnectivityTriage = true
            }
            .buttonStyle(.linkaSecondary)
            .accessibilityHint("Mostra os fatos de conexão observados neste aparelho")

            Spacer()
        }
    }

    private var connectionChangedView: some View {
        VStack(spacing: 20) {
            Spacer()
            LiveConnectionPathView(kind: viewModel.liveConnectionKind, label: viewModel.liveNetworkLabel)
                .padding(.horizontal, 24)
            VStack(spacing: 8) {
                Text("Conexão alterada")
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                Text("A rede mudou durante a medição. Conecte-se à rede desejada e inicie um novo teste.")
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Button { startSpeedTest() } label: {
                Text("Testar conexão")
            }
            .buttonStyle(.linkaPrimary)
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - Helpers

    private var heroStateTitle: String {
        if viewModel.liveConnectionKind == nil {
            return "Sem conexão"
        }
        return "Tudo parece normal"
    }

    private var heroStateSubtitle: String {
        if viewModel.liveConnectionKind == nil {
            return "Conecte-se a uma rede para analisar"
        }
        return "Nenhum problema detectado"
    }

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
            if !viewModel.liveNetworkLabel.isEmpty && viewModel.liveNetworkLabel != "Rede móvel" {
                return viewModel.liveNetworkLabel
            }
            return "Rede móvel"
        } else if viewModel.connectionKind == .ethernet {
            return "Ethernet"
        }
        return nil
    }

    private var liveConnectionType: String {
        switch viewModel.liveConnectionKind {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Rede móvel"
        case .ethernet: return "Ethernet"
        case .other: return "Conexão de rede"
        case nil: return "Sem conexão"
        }
    }

    private var liveConnectionName: String {
        viewModel.liveNetworkLabel.isEmpty ? "Conexão atual" : viewModel.liveNetworkLabel
    }

    private var liveConnectionIcon: String {
        switch viewModel.liveConnectionKind {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        case nil: return "wifi.exclamationmark"
        }
    }

    private var ringValue: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Preparando"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .uploading, .done:
            return String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ",")
        case .error, .connectionChanged:
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
        case .error, .connectionChanged:
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
        case .error, .connectionChanged:
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

    private func startSpeedTest() {
        if viewModel.liveConnectionKind == .wifi, advancedWiFiConfigured, advancedWiFiEnabled {
            triggerWiFiAdvancedShortcut()
        }
        withAnimation {
            viewModel.startTest()
        }
    }

    private func triggerWiFiAdvancedShortcut() {
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(LinkaAdvancedWiFiIntegration.runShortcutURL) {
            UIApplication.shared.open(LinkaAdvancedWiFiIntegration.runShortcutURL, options: [:], completionHandler: nil)
        }
        #endif
    }
}

private struct ResultUsageCasesView: View {
    let videoCall: (label: String, color: Color)
    let gaming: (label: String, color: Color)
    let streaming: (label: String, color: Color)

    var body: some View {
        HStack(spacing: 12) {
            usageNode(
                title: "Chamadas de vídeo",
                icon: "video",
                result: videoCall.label,
                color: videoCall.color
            )
            usageNode(
                title: "Jogo online",
                icon: "gamecontroller",
                result: gaming.label,
                color: gaming.color
            )
            usageNode(
                title: "Streaming",
                icon: "play.tv",
                result: streaming.label,
                color: streaming.color
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .linkaCard(cornerRadius: LinkaRadius.lg)
    }

    private func usageNode(title: String, icon: String, result: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(width: 44, height: 44)
                .background(Color.surfacePage, in: Circle())

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 28)

            LinkaStatusBadge(result, color: color)
        }
        .frame(maxWidth: .infinity)
    }
}

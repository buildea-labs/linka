#if os(macOS)
import SwiftUI
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaEntitlements
import LinkaModules
import NetworkConnectivityTriage
import NetworkInsights

/// Shell de navegação exclusivo do Mac (plano `plano-direcao-visual-mac-ios.md`).
///
/// Não é uma adaptação de `MainView`: é uma segunda camada de apresentação
/// sobre os MESMOS view models (`SpeedTestViewModel`, `StoreKitEntitlementProvider`,
/// `AppIntentCoordinator`). O iOS continua usando `MainView` inalterado —
/// este arquivo só existe no target `LinkaApp_macOS`.
///
/// Decisões de produto vindas da Íris (delegação via Codex, 2026-09-12),
/// restritas a esta plataforma:
/// - D1: gauge semicircular único (não o `MetricRing` do iOS).
/// - D2: só 2 pills persistentes (Velocímetro / Histórico); Ajustes, Assist,
///   Usage, Router e Purchase continuam em sheet. Histórico fica visível e
///   desabilitado durante medição ativa.
/// - D3: um único painel-card cobre todos os estados do Velocímetro — a
///   moldura não muda, só o conteúdo dentro dela. Sem dashboard de métricas.
/// - D4: sem ícones de casa/relógio no toolbar; Ajustes em sheet; share só
///   no resultado concluído; sem seleção manual de servidor (o nome do
///   servidor, quando existir, aparece como texto informativo).
private enum MacDestination: Hashable {
    case speedTest
    case history
}

private enum MacSettingsDismissalAction {
    case purchase(PurchaseEntryPoint)
    case subscriptionManagement
}

private enum MacPurchaseDismissalAction {
    case assistProblemSelection
    case subscriptionManagement
}

private enum MacAssistEntryPoint {
    case fresh
    case result(NetworkMeasurement)

    var measurement: NetworkMeasurement? {
        guard case .result(let measurement) = self else { return nil }
        return measurement
    }
}

struct MacMainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared

    @State private var destination: MacDestination = .speedTest
    @State private var showSettings = false
    @State private var showPurchase = false
    @State private var showSubscriptionManagement = false
    @State private var pendingSettingsDismissalAction: MacSettingsDismissalAction?
    @State private var pendingMeasurementStartAfterSettings = false
    @State private var pendingPurchaseDismissalAction: MacPurchaseDismissalAction?
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var assistEntryPoint: MacAssistEntryPoint = .fresh
    @State private var showAssistProblemSelection = false
    @State private var showAssistResult = false
    @State private var pendingAssistMeasurement = false
    @State private var pendingAssistObjective: String?
    @State private var pendingAssistSubcategory: String?
    @State private var pendingAssistReportedProblem: String?
    @State private var showConnectivityTriage = false
    @State private var speedGaugeUpperBound = 1.0
    @State private var selectedHistoricalMeasurement: NetworkMeasurement?
    @State private var showCurrentMeasurementDetails = false
    @State private var showUsageDiagnostics = false
    @State private var showConnectionPath = false
    @State private var showShareSheet = false
    @State private var showAdvancedWiFiUnavailable = false
    @State private var isSettingsHovered = false
    @State private var isMoreHovered = false

    private var isPlusActive: Bool {
        LinkaEntitlementPolicy.decision(for: .assist, snapshot: entitlements.snapshot, at: Date()).isGranted
    }

    private var currentMeasurement: NetworkMeasurement? {
        guard viewModel.uiPhase == .done else { return nil }
        return viewModel.latestFinishedMeasurement
    }

    private var latestMeasurementForIntent: NetworkMeasurement? {
        viewModel.latestFinishedMeasurement ?? viewModel.recentMeasurements.first
    }

    private var connectionPathReport: ConnectionPathReport? {
        guard let currentMeasurement else { return nil }
        return ConnectionPathEvaluator().evaluate(currentMeasurement)
    }

    private var assistMeasurement: NetworkMeasurement? {
        switch assistEntryPoint {
        case .result(let measurement):
            return measurement
        case .fresh:
            return pendingAssistMeasurement ? nil : currentMeasurement
        }
    }

    private var isMeasuring: Bool {
        switch viewModel.uiPhase {
        case .connecting, .downloading, .uploading:
            return true
        default:
            return false
        }
    }

    private var canStartAdvancedWiFiMeasurement: Bool {
        guard viewModel.liveConnectionKind == .wifi,
              LinkaWiFiPreferences.isAdvancedDiagnosticsEnabled else { return false }
        return LinkaEntitlementPolicy.decision(
            for: .advancedWiFiDiagnostics,
            snapshot: entitlements.snapshot,
            at: Date()
        ).isGranted
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Group {
                switch destination {
                case .speedTest:
                    speedTestPane
                case .history:
                    historyPane
                }
            }
        }
        .frame(minWidth: 780, minHeight: 560)
        .background(Color.surfacePage)
        .sheet(isPresented: $showSettings, onDismiss: handleSettingsDismissal) {
            NavigationStack {
                SettingsView(
                    onPurchaseRequest: presentPurchaseFromSettings,
                    onSubscriptionManagementRequest: presentSubscriptionManagementFromSettings
                )
                    .environmentObject(entitlements)
            }
            .frame(width: 540, height: 640)
        }
        .sheet(isPresented: $showPurchase, onDismiss: handlePurchaseDismissal) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                if purchaseEntryPoint == .assist {
                    pendingPurchaseDismissalAction = .assistProblemSelection
                } else if purchaseEntryPoint == .settings {
                    pendingPurchaseDismissalAction = .subscriptionManagement
                }
            }
            .environmentObject(entitlements)
        }
        .sheet(isPresented: $showSubscriptionManagement) {
            SubscriptionManagementSheet()
                .environmentObject(entitlements)
        }
        .sheet(isPresented: $showAssistProblemSelection, onDismiss: beginPendingAssistCollection) {
            AssistProblemSelectionView(
                currentMeasurement: assistEntryPoint.measurement,
                recentMeasurements: [],
                onStartFreshMeasurement: { objective, subcategory, reportedProblem in
                    pendingAssistObjective = objective
                    pendingAssistSubcategory = subcategory
                    pendingAssistReportedProblem = reportedProblem
                    pendingAssistMeasurement = true
                },
                entitlements: entitlements
            )
        }
        .sheet(isPresented: $showAssistResult) {
            AssistView(
                currentMeasurement: assistMeasurement,
                recentMeasurements: [],
                isCollectingMeasurement: pendingAssistMeasurement,
                objective: pendingAssistObjective,
                subcategory: pendingAssistSubcategory,
                reportedProblem: pendingAssistReportedProblem,
                onRetry: { pendingAssistMeasurement = true; viewModel.startTest() },
                onShowDetails: {},
                entitlements: entitlements
            )
        }
        .sheet(isPresented: $showConnectivityTriage) {
            ConnectivityTriageView(onRetry: { viewModel.startTest() })
        }
        .sheet(item: $selectedHistoricalMeasurement) { measurement in
            NavigationStack {
                HistoricalMeasurementDetailView(
                    measurement: measurement,
                    onStartNewMeasurement: startMeasurementFromHistory,
                    onStartNewMeasurementWithAdvancedWiFi: startMeasurementWithAdvancedWiFi
                )
            }
            .environmentObject(entitlements)
            .frame(minWidth: 620, minHeight: 680)
        }
        .sheet(isPresented: $showCurrentMeasurementDetails) {
            NavigationStack {
                MeasurementDetailView(
                    measurement: currentMeasurement,
                    duration: viewModel.testDuration
                )
                .environmentObject(entitlements)
            }
            .frame(minWidth: 620, minHeight: 680)
        }
        .sheet(isPresented: $showUsageDiagnostics) {
            UsageDiagnosticsView(measurement: currentMeasurement)
                .frame(minWidth: 560, minHeight: 580)
        }
        .sheet(isPresented: $showConnectionPath) {
            if let connectionPathReport {
                ConnectionPathDetailView(report: connectionPathReport)
                    .frame(minWidth: 560, minHeight: 580)
            }
        }
        .shareMeasurementSheet(isPresented: $showShareSheet, measurement: currentMeasurement)
        .alert("Detalhes de Wi-Fi indisponíveis", isPresented: $showAdvancedWiFiUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("O Mac não informou detalhes suficientes do Wi-Fi agora. Nenhuma medição foi iniciada.")
        }
        .onChange(of: viewModel.downloadSpeed) { speed in
            guard viewModel.uiPhase == .downloading, speed > speedGaugeUpperBound else { return }
            speedGaugeUpperBound = Self.speedGaugeScale(for: speed)
        }
        .onChange(of: viewModel.uiPhase) { phase in
            intentCoordinator.setMeasurementActive(isMeasuring)
            if phase == .connecting {
                speedGaugeUpperBound = 1
            }
            guard phase == .done, pendingAssistMeasurement else { return }
            pendingAssistMeasurement = false
            showAssistResult = true
        }
        .onChange(of: intentCoordinator.pendingStartSpeedTest) { pending in
            guard pending else { return }
            guard !isMeasuring else {
                intentCoordinator.consumeStartSpeedTestRequest()
                return
            }
            destination = .speedTest
            if showSettings {
                pendingMeasurementStartAfterSettings = true
                showSettings = false
            } else {
                viewModel.startTest()
            }
            intentCoordinator.consumeStartSpeedTestRequest()
        }
        .onChange(of: intentCoordinator.pendingOpenHistory) { pending in
            handleOpenHistoryRequest(pending)
        }
        .onChange(of: intentCoordinator.pendingPurchasePrompt) { pending in
            guard pending else { return }
            guard !isMeasuring else {
                intentCoordinator.consumePurchasePrompt()
                return
            }
            purchaseEntryPoint = .shortcut
            showPurchase = true
            intentCoordinator.consumePurchasePrompt()
        }
        .onChange(of: intentCoordinator.pendingOpenLatestMeasurement) { pending in
            handleOpenLatestMeasurementRequest(pending)
        }
        .onChange(of: intentCoordinator.pendingCancelMeasurement) { pending in
            guard pending else { return }
            if isMeasuring { viewModel.skipOrCancel() }
            intentCoordinator.consumeCancelMeasurement()
        }
        .onChange(of: intentCoordinator.pendingOpenSettings) { pending in
            guard pending else { return }
            if !isMeasuring { showSettings = true }
            intentCoordinator.consumeOpenSettings()
        }
        .onAppear {
            intentCoordinator.setMeasurementActive(isMeasuring)
            viewModel.refreshLiveNetwork()
        }
        .onDisappear { intentCoordinator.setMeasurementActive(false) }
    }

    // MARK: - Header (D2, D4)

    private var header: some View {
        ZStack {
            HStack(spacing: 2) {
                pillButton(title: "Velocímetro", isActive: destination == .speedTest, isEnabled: true) {
                    destination = .speedTest
                }
                pillButton(title: "Histórico", isActive: destination == .history, isEnabled: !isMeasuring) {
                    destination = .history
                }
            }
            .padding(3)
            .background(Color.surfaceCard, in: Capsule())
            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isMeasuring)
                .opacity(isMeasuring ? 0.4 : 1)
                .background(isSettingsHovered ? Color.brandSurface.opacity(0.55) : .clear, in: RoundedRectangle(cornerRadius: 8))
                .onHover { isSettingsHovered = $0 }
                .help("Ajustes")
                .accessibilityLabel("Ajustes")
                .accessibilityHint(isMeasuring ? "Indisponível durante a medição" : "")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func pillButton(title: String, isActive: Bool, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.captionStrong)
                .foregroundColor(isActive ? .brandOnSurface : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isActive ? Color.brandSurface : Color.clear, in: Capsule())
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    // MARK: - Painel Velocímetro (D3)

    private var speedTestPane: some View {
        GeometryReader { proxy in
            ScrollView {
                mainCard(isWide: proxy.size.width >= 1120)
                    .frame(maxWidth: 1120)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func mainCard(isWide: Bool) -> some View {
        if isWide {
            HStack(alignment: .top, spacing: 32) {
                measurementContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isFinalResult {
                    Divider()
                    supplementalContent
                        .frame(width: 280, alignment: .leading)
                }
            }
            .padding(28)
            .linkaCard(cornerRadius: LinkaRadius.lg)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                measurementContent
                if isFinalResult {
                    Divider()
                    supplementalContent
                }
            }
            .padding(24)
            .linkaCard(cornerRadius: LinkaRadius.lg)
        }
    }

    private var measurementContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                SemicircularGauge(
                    fraction: gaugeFraction,
                    centerLabel: gaugeCenterLabel,
                    centerValue: gaugeCenterValue,
                    centerUnit: gaugeCenterUnit,
                    isActive: isDownloading
                )
                    .frame(width: 280, height: 220)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Velocímetro de download")
                    .accessibilityValue(gaugeAccessibilityValue)
                if isUploading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.brandAccentWarm)
                        Text("Medindo upload")
                            .font(.bodySmallStrong)
                            .foregroundColor(.textPrimary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Upload em andamento")
                }
                Text(phaseMessage)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 18)
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            if showsFinalStats {
                statsRow
                    .padding(.vertical, 14)
                    .overlay(
                        VStack {
                            Divider()
                            Spacer()
                            Divider()
                        }
                    )
            }

            actionRow
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(title: "Upload", value: finalStatValue(viewModel.uploadSpeed, measured: viewModel.hasMeasuredUpload), unit: isFinalResult && viewModel.hasMeasuredUpload ? "Mbps" : nil)
            statColumn(title: "Latência", value: finalStatValue(Double(viewModel.ping), measured: viewModel.hasMeasuredPing), unit: isFinalResult && viewModel.hasMeasuredPing ? "ms" : nil)
            statColumn(title: "Perdas", value: finalPacketLossValue, unit: isFinalResult && viewModel.packetLossPercent != nil ? "%" : nil)
        }
    }

    private func statColumn(title: String, value: String, unit: String?) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.captionStrong)
                    .foregroundColor(.textPrimary)
                if let unit {
                    Text(unit)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }
            Text(title)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        switch viewModel.uiPhase {
        case .idle:
            return AnyView(
                VStack(spacing: 10) {
                    Button("Testar velocidade") { startMeasurement() }
                        .buttonStyle(.linkaPrimary)
                        .frame(maxWidth: 280)
                        .keyboardShortcut("r", modifiers: .command)
                }
            )
        case .connecting, .downloading, .uploading:
            return AnyView(
                Button("Cancelar") { viewModel.skipOrCancel() }
                    .buttonStyle(.linkaSecondary)
                    .keyboardShortcut(".", modifiers: .command)
            )
        case .done:
            return AnyView(
                HStack(spacing: 10) {
                    Button("Testar novamente") { startMeasurement() }
                        .buttonStyle(.linkaPrimary)
                        .frame(maxWidth: 280)
                        .keyboardShortcut("r", modifiers: .command)
                    Button {
                        requestAssistFromResult()
                    } label: {
                        Label("Assist", systemImage: "sparkles")
                    }
                    .buttonStyle(.linkaSecondary)
                    Menu {
                        Button("Detalhes da medição") {
                            showCurrentMeasurementDetails = true
                        }
                        Button("Qualidade de uso") {
                            showUsageDiagnostics = true
                        }
                        if connectionPathReport != nil {
                            Button("Caminho da conexão") {
                                showConnectionPath = true
                            }
                        }
                        Button("Compartilhar resultado") {
                            showShareSheet = true
                        }
                    } label: {
                        Label("Mais", systemImage: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .onHover { isMoreHovered = $0 }
                    .help("Mais ações para este resultado")
                    .background(isMoreHovered ? Color.brandSurface.opacity(0.55) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
            )
        case .error:
            return AnyView(
                HStack(spacing: 10) {
                    Button("Tentar novamente") { startMeasurement() }
                        .buttonStyle(.linkaPrimary)
                        .frame(maxWidth: 280)
                        .keyboardShortcut("r", modifiers: .command)
                    Button("Verificar conexão") { showConnectivityTriage = true }
                        .buttonStyle(.linkaSecondary)
                }
            )
        case .connectionChanged:
            return AnyView(
                Button("Testar conexão") { startMeasurement() }
                    .buttonStyle(.linkaPrimary)
                    .frame(maxWidth: 280)
                    .keyboardShortcut("r", modifiers: .command)
            )
        }
    }

    // MARK: - Contexto secundário do mesmo painel

    private var supplementalContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Detalhes técnicos") {
                VStack(spacing: 0) {
                    techDetailRow(label: "Jitter", value: currentMeasurement?.jitterMs.map { "\(Int(round($0))) ms" } ?? "—")
                    techDetailRow(label: "Faixa Wi‑Fi", value: wifiBandLabel ?? "—")
                    techDetailRow(label: "Duração do teste", value: isFinalResult ? (viewModel.testDuration.isEmpty ? "—" : viewModel.testDuration) : "—")
                }
                .padding(.top, 8)
            }
            Divider()
            DisclosureGroup("Últimas medições") {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.recentMeasurements.isEmpty {
                        Text("Ainda sem medições.")
                            .font(.captionMedium)
                            .foregroundColor(.textSecondary)
                    } else {
                        ForEach(viewModel.recentMeasurements.prefix(2)) { measurement in
                            recentMeasurementRow(measurement)
                        }
                    }
                    Button("Ver histórico completo") { destination = .history }
                        .buttonStyle(.linkaSecondary)
                        .disabled(isMeasuring)
                }
                .padding(.top, 8)
            }
        }
    }

    private func techDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.captionStrong)
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) { Divider() }
    }

    private func recentMeasurementRow(_ measurement: NetworkMeasurement) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: measurement.measuredAt))
                    .font(.captionMedium)
                    .foregroundColor(.textPrimary)
                Text(networkLabel(for: measurement))
                    .font(.monoCaption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let down = measurement.downloadMbps {
                    Text("\(Int(round(down))) Mbps")
                        .font(.captionStrong)
                        .foregroundColor(.textPrimary)
                }
                if let up = measurement.uploadMbps, let ping = measurement.latencyMs {
                    Text("\(Int(round(up))) Mbps · \(Int(round(ping))) ms")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) { Divider() }
        .contextMenu {
            Button("Abrir detalhes") { selectedHistoricalMeasurement = measurement }
            Button("Testar novamente") { startMeasurement() }
        }
    }

    // MARK: - Painel Histórico (D2)

    private var historyPane: some View {
        NavigationStack {
            HistoryView { measurement in
                selectedHistoricalMeasurement = measurement
            }
        }
    }

    // MARK: - Assist (reaproveita o mesmo fluxo do iOS, camada de apresentação própria)

    private func requestAssist(from entryPoint: MacAssistEntryPoint) {
        assistEntryPoint = entryPoint
        if isPlusActive {
            showAssistProblemSelection = true
        } else {
            purchaseEntryPoint = .assist
            showPurchase = true
        }
    }

    private func requestAssistFromResult() {
        guard let measurement = currentMeasurement else { return }
        requestAssist(from: .result(measurement))
    }

    private func startMeasurementFromHistory() {
        selectedHistoricalMeasurement = nil
        destination = .speedTest
        DispatchQueue.main.async {
            startMeasurement()
        }
    }

    /// A coleta avançada é uma preferência de Ajustes, não um segundo modo
    /// de teste. Quando elegível, ela apenas acompanha a medição única.
    private func startMeasurement() {
        guard !isMeasuring else { return }
        let diagnostics = canStartAdvancedWiFiMeasurement
            ? MacAdvancedWiFiDiagnosticsProvider().capture(entitlement: entitlements.snapshot)
            : nil
        viewModel.startTest(advancedWiFiDiagnostics: diagnostics)
    }

    private func startMeasurementWithAdvancedWiFi() {
        guard !isMeasuring else { return }
        selectedHistoricalMeasurement = nil
        destination = .speedTest
        guard let diagnostics = MacAdvancedWiFiDiagnosticsProvider().capture(entitlement: entitlements.snapshot) else {
            showAdvancedWiFiUnavailable = true
            return
        }
        DispatchQueue.main.async {
            viewModel.startTest(advancedWiFiDiagnostics: diagnostics)
        }
    }

    private func presentPurchaseFromSettings(_ entryPoint: PurchaseEntryPoint) {
        pendingSettingsDismissalAction = .purchase(entryPoint)
        showSettings = false
    }

    private func presentSubscriptionManagementFromSettings() {
        pendingSettingsDismissalAction = .subscriptionManagement
        showSettings = false
    }

    private func handleSettingsDismissal() {
        if pendingMeasurementStartAfterSettings {
            pendingMeasurementStartAfterSettings = false
            viewModel.startTest()
            return
        }
        guard let action = pendingSettingsDismissalAction else { return }
        pendingSettingsDismissalAction = nil
        switch action {
        case .purchase(let entryPoint):
            purchaseEntryPoint = entryPoint
            showPurchase = true
        case .subscriptionManagement:
            showSubscriptionManagement = true
        }
    }

    private func handlePurchaseDismissal() {
        guard let action = pendingPurchaseDismissalAction else { return }
        pendingPurchaseDismissalAction = nil
        switch action {
        case .assistProblemSelection:
            showAssistProblemSelection = true
        case .subscriptionManagement:
            showSubscriptionManagement = true
        }
    }

    private func handleOpenHistoryRequest(_ pending: Bool) {
        guard pending else { return }
        guard !isMeasuring else {
            intentCoordinator.consumeOpenHistory()
            return
        }
        destination = .history
        intentCoordinator.consumeOpenHistory()
    }

    private func handleOpenLatestMeasurementRequest(_ pending: Bool) {
        guard pending else { return }
        defer { intentCoordinator.consumeOpenLatestMeasurement() }
        guard !isMeasuring else { return }
        guard isPlusActive else {
            purchaseEntryPoint = .shortcut
            showPurchase = true
            return
        }
        guard let latest = latestMeasurementForIntent else { return }
        selectedHistoricalMeasurement = latest
    }

    private func beginPendingAssistCollection() {
        guard pendingAssistMeasurement, !showAssistResult else { return }
        showAssistResult = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard pendingAssistMeasurement else { return }
            viewModel.startTest()
        }
    }

    // MARK: - Formatação (apresentação, sem lógica de motor)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM · HH:mm"
        return formatter
    }()

    private func networkLabel(for measurement: NetworkMeasurement) -> String {
        switch measurement.connectionKind {
        case .wifi:
            let ssid = measurement.wifiContext?.ssid ?? "Wi-Fi"
            return ssid
        case .cellular:
            return "Rede móvel"
        case .ethernet:
            return "Ethernet"
        case .other, nil:
            return "Rede"
        }
    }

    private var wifiBandLabel: String? {
        guard isFinalResult, let band = currentMeasurement?.wifiBandGHz else { return nil }
        let formatted = band.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", band) : String(format: "%.1f", band)
        return "\(formatted) GHz"
    }

    private var isFinalResult: Bool {
        viewModel.uiPhase == .done
    }

    private var showsFinalStats: Bool {
        isFinalResult
    }

    private func finalStatValue(_ value: Double, measured: Bool) -> String {
        isFinalResult && measured ? "\(Int(round(value)))" : "—"
    }

    private var finalPacketLossValue: String {
        guard isFinalResult, let packetLoss = viewModel.packetLossPercent else { return "—" }
        return "\(Int(round(packetLoss)))"
    }

    private var gaugeFraction: Double {
        guard let value = downloadGaugeValue else { return 0 }
        let currentScale = max(speedGaugeUpperBound, Self.speedGaugeScale(for: value))
        return max(0, min(1, value / currentScale))
    }

    private var gaugeAccessibilityValue: String {
        switch viewModel.uiPhase {
        case .idle:
            return "Pronto para medir"
        case .connecting:
            return "Conectando ao servidor"
        case .downloading:
            return "Download: \(gaugeCenterValue) megabits por segundo, medição em andamento"
        case .uploading:
            return "Download medido: \(gaugeCenterValue) megabits por segundo. Medindo upload"
        case .done:
            return "Download: \(gaugeCenterValue) megabits por segundo. Medição concluída"
        case .error:
            return "Medição indisponível"
        case .connectionChanged:
            return "Medição interrompida porque a rede mudou"
        }
    }

    private var isDownloading: Bool {
        viewModel.uiPhase == .downloading
    }

    private var isUploading: Bool {
        viewModel.uiPhase == .uploading
    }

    private var downloadGaugeValue: Double? {
        switch viewModel.uiPhase {
        case .downloading:
            return viewModel.downloadSpeed
        case .uploading, .done:
            return viewModel.downloadSpeed
        case .idle, .connecting, .error, .connectionChanged:
            return nil
        }
    }

    private var gaugeCenterLabel: String? {
        downloadGaugeValue == nil ? nil : "DOWNLOAD"
    }

    private var gaugeCenterValue: String {
        guard let value = downloadGaugeValue else {
            switch viewModel.uiPhase {
            case .idle:
                return "Pronto para medir"
            case .connecting:
                return "Conectando…"
            case .error:
                return "Indisponível"
            case .connectionChanged:
                return "Rede alterada"
            case .downloading, .uploading, .done:
                return ""
            }
        }
        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private var gaugeCenterUnit: String? {
        downloadGaugeValue == nil ? nil : "Mbps"
    }

    private static func speedGaugeScale(for value: Double) -> Double {
        guard value > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(value)))
        for multiplier in [1.0, 2.0, 5.0, 10.0] {
            let candidate = multiplier * magnitude
            if value <= candidate {
                return candidate
            }
        }
        return 10 * magnitude
    }

    private var phaseMessage: String {
        switch viewModel.uiPhase {
        case .idle:
            return "Pronto para medir."
        case .connecting:
            return "Conectando ao servidor mais próximo…"
        case .downloading:
            return "Medindo velocidade de download…"
        case .uploading:
            return "Download concluído. Medindo velocidade de upload…"
        case .done:
            return "Sua conexão está pronta."
        case .error:
            return viewModel.failureReason == .offline ? "Sem conexão com a internet." : "Não foi possível medir."
        case .connectionChanged:
            return "A rede mudou durante a medição."
        }
    }
}

/// Velocímetro de download. O arco usa apenas a maior amostra real da rodada
/// como escala dinâmica; não comunica capacidade contratada nem progresso.
private struct SemicircularGauge: View {
    var fraction: Double
    var centerLabel: String?
    var centerValue: String
    var centerUnit: String?
    var isActive: Bool

    private var clamped: Double { max(0, min(1, fraction)) }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height * 2)
            let lineWidth: CGFloat = 12
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.borderDefault, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .frame(width: diameter, height: diameter)

                Circle()
                    .trim(from: 0, to: 0.5 * clamped)
                    .stroke(Color.brandAccentWarm, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .frame(width: diameter, height: diameter)
                    .opacity(isActive || clamped > 0 ? 1 : 0)

                VStack(spacing: 2) {
                    if let centerLabel {
                        Text(centerLabel)
                            .font(.monoCaption)
                            .foregroundColor(.textSecondary)
                    }
                    Text(centerValue)
                        .font(centerUnit == nil ? .captionStrong : .heroValueHuge)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    if let centerUnit {
                        Text(centerUnit)
                            .font(.captionMedium)
                            .foregroundColor(.textSecondary)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: diameter * 0.8)
                .padding(.top, diameter * 0.28)
                .frame(width: diameter, alignment: .top)
            }
            .frame(width: diameter, height: diameter, alignment: .top)
        }
    }
}
#endif

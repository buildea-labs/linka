#if os(macOS)
import SwiftUI
import AppKit
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaEntitlements
import LinkaModules
import NetworkConnectivityTriage
import NetworkInsights

private enum MacDestination: Hashable {
    case speedTest
    case history
    case settings
}

private enum MacPurchaseDismissalAction {
    case assistProblemSelection
    case subscriptionManagement
}

private enum MacAssistEntryPoint {
    case fresh
    case result(NetworkMeasurement)

    var measurement: NetworkMeasurement? {
        guard case .result(let m) = self else { return nil }
        return m
    }
}

private enum DotPhase { case pending, active, done }

// MARK: - MacMainView

struct MacMainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared

    @State private var destination: MacDestination = .speedTest
    @State private var showPurchase = false
    @State private var showSubscriptionManagement = false
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

    // MARK: Computed

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
        guard let m = currentMeasurement else { return nil }
        return ConnectionPathEvaluator().evaluate(m)
    }

    private var assistMeasurement: NetworkMeasurement? {
        switch assistEntryPoint {
        case .result(let m): return m
        case .fresh: return pendingAssistMeasurement ? nil : currentMeasurement
        }
    }

    private var isMeasuring: Bool {
        switch viewModel.uiPhase {
        case .connecting, .downloading, .uploading: return true
        default: return false
        }
    }

    private var isFinalResult: Bool { viewModel.uiPhase == .done }
    private var isDownloading: Bool { viewModel.uiPhase == .downloading }

    private var canStartAdvancedWiFiMeasurement: Bool {
        guard viewModel.liveConnectionKind == .wifi,
              LinkaWiFiPreferences.isAdvancedDiagnosticsEnabled else { return false }
        return LinkaEntitlementPolicy.decision(
            for: .advancedWiFiDiagnostics,
            snapshot: entitlements.snapshot,
            at: Date()
        ).isGranted
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            Group {
                switch destination {
                case .speedTest:
                    HStack(spacing: 0) {
                        mainStage
                        Divider()
                        rightPanel
                            .frame(width: 320)
                    }
                case .history:
                    historyView
                case .settings:
                    settingsView
                }
            }
        }
        .frame(minWidth: 900, minHeight: 560)
        .background(Color.surfacePage)
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
                MeasurementDetailView(measurement: currentMeasurement, duration: viewModel.testDuration)
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
            if phase == .connecting { speedGaugeUpperBound = 1 }
            guard phase == .done, pendingAssistMeasurement else { return }
            pendingAssistMeasurement = false
            showAssistResult = true
        }
        .onChange(of: intentCoordinator.pendingStartSpeedTest) { pending in
            guard pending else { return }
            guard !isMeasuring else { intentCoordinator.consumeStartSpeedTestRequest(); return }
            destination = .speedTest
            viewModel.startTest()
            intentCoordinator.consumeStartSpeedTestRequest()
        }
        .onChange(of: intentCoordinator.pendingOpenHistory) { pending in
            handleOpenHistoryRequest(pending)
        }
        .onChange(of: intentCoordinator.pendingPurchasePrompt) { pending in
            guard pending else { return }
            guard !isMeasuring else { intentCoordinator.consumePurchasePrompt(); return }
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
            if !isMeasuring { destination = .settings }
            intentCoordinator.consumeOpenSettings()
        }
        .onAppear {
            intentCoordinator.setMeasurementActive(isMeasuring)
            viewModel.refreshLiveNetwork()
        }
        .onDisappear { intentCoordinator.setMeasurementActive(false) }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 10)
                .padding(.bottom, 28)

            sidebarGroupLabel("Testes")
            sidebarNavItem("Velocímetro", systemImage: "gauge.medium", dest: .speedTest, disabled: false)
            sidebarNavItem("Histórico", systemImage: "chart.bar", dest: .history, disabled: isMeasuring)

            sidebarGroupLabel("App").padding(.top, 8)
            sidebarNavItem("Configurações", systemImage: "gearshape", dest: .settings, disabled: isMeasuring)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 40)
        .frame(width: 240)
    }

    private func sidebarGroupLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.textSecondary)
            .tracking(1.1)
            .padding(.horizontal, 10)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func sidebarNavItem(_ title: String, systemImage: String, dest: MacDestination, disabled: Bool) -> some View {
        Button { destination = dest } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: destination == dest ? .semibold : .medium))
                .foregroundColor(destination == dest ? .brandAccentWarm : .textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    destination == dest ? Color.brandAccentWarm.opacity(0.12) : Color.clear,
                    in: RoundedRectangle(cornerRadius: LinkaRadius.sm, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(destination == dest ? .isSelected : [])
    }

    // MARK: - Main Stage

    private var mainStage: some View {
        VStack(spacing: 0) {
            // Network info header
            HStack {
                Text(liveConnectionName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)

            Spacer()

            // Hero: phase dots + ring + status
            VStack(spacing: 40) {
                phaseDots

                MacMetricRing(
                    isConnecting: viewModel.uiPhase == .connecting,
                    progress: gaugeFraction,
                    value: macRingValue,
                    unit: macRingUnit
                )
                .frame(width: 220, height: 220)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Velocímetro de download")
                .accessibilityValue(gaugeAccessibilityValue)

                statusPill
            }

            Spacer()

            // Metrics footer
            HStack(spacing: 48) {
                footerStatBlock(label: "Ping",     value: pingFooterValue,     unit: "ms")
                footerStatBlock(label: "Download", value: downloadFooterValue, unit: "Mbps")
                footerStatBlock(label: "Upload",   value: uploadFooterValue,   unit: "Mbps")
            }
            .padding(.bottom, 28)

            // Actions
            actionRow
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Phase Dots

    private var phaseDots: some View {
        HStack(spacing: 28) {
            phaseDot(label: "Ping",     state: pingDotState)
            phaseDot(label: "Download", state: downloadDotState)
            phaseDot(label: "Upload",   state: uploadDotState)
        }
    }

    private func phaseDot(label: String, state: DotPhase) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(dotFill(state))
                    .frame(width: 22, height: 22)
                Circle()
                    .strokeBorder(dotBorder(state), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.brandOnSurface)
                }
            }
            Text(label)
                .font(.system(size: 12, weight: state == .active ? .semibold : .medium))
                .foregroundColor(state == .active ? .textPrimary : .textSecondary)
        }
    }

    private func dotFill(_ state: DotPhase) -> Color {
        switch state {
        case .pending: return .clear
        case .active:  return .brandAccentWarm
        case .done:    return .brandSurface
        }
    }

    private func dotBorder(_ state: DotPhase) -> Color {
        switch state {
        case .pending: return .borderDefault
        case .active:  return .brandAccentWarm
        case .done:    return .brandSurface
        }
    }

    private var pingDotState: DotPhase {
        switch viewModel.uiPhase {
        case .connecting: return .active
        case .downloading, .uploading, .done: return .done
        default: return .pending
        }
    }

    private var downloadDotState: DotPhase {
        switch viewModel.uiPhase {
        case .downloading: return .active
        case .uploading, .done: return .done
        default: return .pending
        }
    }

    private var uploadDotState: DotPhase {
        switch viewModel.uiPhase {
        case .uploading: return .active
        case .done: return .done
        default: return .pending
        }
    }

    // MARK: Status pill

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 6, height: 6)
            Text(phaseMessage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.surfaceCard, in: Capsule())
    }

    private var statusDotColor: Color {
        switch viewModel.uiPhase {
        case .connecting, .downloading, .uploading: return .brandAccentWarm
        case .done: return .statusGood
        case .error: return .statusCritical
        case .connectionChanged: return .statusAttention
        case .idle: return .textSecondary
        }
    }

    // MARK: Footer stat blocks

    private func footerStatBlock(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var pingFooterValue: String {
        viewModel.hasMeasuredPing ? "\(viewModel.ping)" : "—"
    }
    private var downloadFooterValue: String {
        viewModel.downloadSpeed > 0 ? String(format: "%.1f", viewModel.downloadSpeed) : "—"
    }
    private var uploadFooterValue: String {
        viewModel.hasMeasuredUpload ? String(format: "%.1f", viewModel.uploadSpeed) : "—"
    }

    // MARK: - Action Row

    private var actionRow: some View {
        switch viewModel.uiPhase {
        case .idle:
            return AnyView(
                Button("Testar velocidade") { startMeasurement() }
                    .buttonStyle(.linkaPrimary)
                    .frame(maxWidth: 280)
                    .keyboardShortcut("r", modifiers: .command)
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
                    Button { requestAssistFromResult() } label: {
                        Label("Assist", systemImage: "sparkles")
                    }
                    .buttonStyle(.linkaSecondary)
                    Menu {
                        Button("Detalhes da medição")  { showCurrentMeasurementDetails = true }
                        Button("Qualidade de uso")      { showUsageDiagnostics = true }
                        if connectionPathReport != nil {
                            Button("Caminho da conexão") { showConnectionPath = true }
                        }
                        Button("Compartilhar resultado") { showShareSheet = true }
                    } label: {
                        Label("Mais", systemImage: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .help("Mais ações para este resultado")
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

    // MARK: - Right Panel

    private var rightPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Qualidade")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.bottom, 16)

                qualityCard
                    .padding(.bottom, 40)

                Text("Últimas Medições")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.bottom, 12)

                recentMeasurementsList
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .background(Color.surfaceCard)
    }

    private var qualityCard: some View {
        VStack(spacing: 0) {
            qualityRow(key: "Latência Média", value: latencyQualityValue)
            Divider().padding(.horizontal, 16)
            qualityRow(key: "Jitter", value: jitterQualityValue)
            Divider().padding(.horizontal, 16)
            qualityRow(key: "Perda de Pacotes", value: lossQualityValue)
            Divider().padding(.horizontal, 16)
            HStack {
                Text("Estabilidade")
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
                Spacer()
                stabilityBadge
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.surfacePage, in: RoundedRectangle(cornerRadius: LinkaRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LinkaRadius.md, style: .continuous)
                .stroke(Color.borderDefault, lineWidth: 0.5)
        )
    }

    private func qualityRow(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var latencyQualityValue: String {
        guard isFinalResult, let ms = currentMeasurement?.latencyMs else { return "—" }
        return "\(Int(round(ms))) ms"
    }
    private var jitterQualityValue: String {
        guard isFinalResult, let ms = currentMeasurement?.jitterMs else { return "—" }
        return String(format: "%.1f ms", ms)
    }
    private var lossQualityValue: String {
        guard isFinalResult, let loss = viewModel.packetLossPercent else { return "—" }
        return String(format: "%.1f%%", loss)
    }

    private var stabilityBadge: some View {
        let (label, color): (String, Color) = {
            guard isFinalResult,
                  let ping = currentMeasurement?.latencyMs,
                  let jitter = currentMeasurement?.jitterMs else { return ("—", .textSecondary) }
            let loss = viewModel.packetLossPercent ?? 0
            if ping <= 30 && jitter <= 5  && loss < 0.5 { return ("Excelente", .statusGood) }
            if ping <= 60 && jitter <= 15 && loss < 2   { return ("Boa",       .statusGood) }
            if ping <= 120               && loss < 5    { return ("Regular",   .statusAttention) }
            return ("Instável", .statusCritical)
        }()
        return AnyView(LinkaStatusBadge(label, color: color))
    }

    private var recentMeasurementsList: some View {
        VStack(spacing: 0) {
            if viewModel.recentMeasurements.isEmpty {
                Text("Ainda sem medições.")
                    .font(.captionSmall)
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(viewModel.recentMeasurements.prefix(5))) { m in
                    recentRow(m)
                }
            }
            Button("Ver histórico completo") { destination = .history }
                .buttonStyle(.linkaSecondary)
                .disabled(isMeasuring)
                .padding(.top, 12)
        }
    }

    private func recentRow(_ m: NetworkMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Self.dateFormatter.string(from: m.measuredAt))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(networkLabel(for: m))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            HStack(spacing: 16) {
                miniStatCell(label: "Down", value: m.downloadMbps.map { "\(Int(round($0)))" } ?? "—")
                miniStatCell(label: "Up",   value: m.uploadMbps.map   { "\(Int(round($0)))" } ?? "—")
                miniStatCell(label: "Ping", value: m.latencyMs.map    { "\(Int(round($0)))ms" } ?? "—")
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider() }
        .contextMenu {
            Button("Abrir detalhes")   { selectedHistoricalMeasurement = m }
            Button("Testar novamente") { startMeasurement() }
        }
    }

    private func miniStatCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: - History View (full width)

    private var historyView: some View {
        NavigationStack {
            HistoryView { measurement in
                selectedHistoricalMeasurement = measurement
            }
        }
    }

    // MARK: - Settings View (full width, inline)

    private var settingsView: some View {
        NavigationStack {
            SettingsView(
                onPurchaseRequest: { entryPoint in
                    destination = .speedTest
                    purchaseEntryPoint = entryPoint
                    showPurchase = true
                },
                onSubscriptionManagementRequest: {
                    destination = .speedTest
                    showSubscriptionManagement = true
                }
            )
            .environmentObject(entitlements)
        }
    }

    // MARK: - Assist

    private func requestAssist(from entryPoint: MacAssistEntryPoint) {
        assistEntryPoint = entryPoint
        if isPlusActive { showAssistProblemSelection = true }
        else { purchaseEntryPoint = .assist; showPurchase = true }
    }

    private func requestAssistFromResult() {
        guard let m = currentMeasurement else { return }
        requestAssist(from: .result(m))
    }

    private func startMeasurementFromHistory() {
        selectedHistoricalMeasurement = nil
        destination = .speedTest
        DispatchQueue.main.async { startMeasurement() }
    }

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
        DispatchQueue.main.async { viewModel.startTest(advancedWiFiDiagnostics: diagnostics) }
    }

    private func handlePurchaseDismissal() {
        guard let action = pendingPurchaseDismissalAction else { return }
        pendingPurchaseDismissalAction = nil
        switch action {
        case .assistProblemSelection: showAssistProblemSelection = true
        case .subscriptionManagement: showSubscriptionManagement = true
        }
    }

    private func handleOpenHistoryRequest(_ pending: Bool) {
        guard pending else { return }
        guard !isMeasuring else { intentCoordinator.consumeOpenHistory(); return }
        destination = .history
        intentCoordinator.consumeOpenHistory()
    }

    private func handleOpenLatestMeasurementRequest(_ pending: Bool) {
        guard pending else { return }
        defer { intentCoordinator.consumeOpenLatestMeasurement() }
        guard !isMeasuring else { return }
        guard isPlusActive else { purchaseEntryPoint = .shortcut; showPurchase = true; return }
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

    // MARK: - Formatação

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d MMM · HH:mm"
        return f
    }()

    private func networkLabel(for m: NetworkMeasurement) -> String {
        switch m.connectionKind {
        case .wifi:     return m.wifiContext?.ssid ?? "Wi-Fi"
        case .cellular: return "Rede móvel"
        case .ethernet: return "Ethernet"
        default:        return "Rede"
        }
    }

    private var liveConnectionName: String {
        viewModel.liveNetworkLabel.isEmpty ? "Conexão atual" : viewModel.liveNetworkLabel
    }

    // MARK: - Gauge helpers

    private var gaugeFraction: Double {
        guard let value = downloadGaugeValue else { return 0 }
        let scale = max(speedGaugeUpperBound, Self.speedGaugeScale(for: value))
        return max(0, min(1, value / scale))
    }

    private var downloadGaugeValue: Double? {
        switch viewModel.uiPhase {
        case .downloading, .uploading, .done: return viewModel.downloadSpeed
        default: return nil
        }
    }

    private var macRingValue: String {
        guard downloadGaugeValue != nil else { return "" }
        return String(format: "%.2f", viewModel.downloadSpeed)
    }

    private var macRingUnit: String? {
        downloadGaugeValue != nil ? "Mbps" : nil
    }

    private var gaugeAccessibilityValue: String {
        switch viewModel.uiPhase {
        case .idle:             return "Pronto para medir"
        case .connecting:       return "Conectando ao servidor"
        case .downloading:      return "Download: \(Int(round(viewModel.downloadSpeed))) Mbps, medição em andamento"
        case .uploading:        return "Download medido: \(Int(round(viewModel.downloadSpeed))) Mbps. Medindo upload"
        case .done:             return "Download: \(Int(round(viewModel.downloadSpeed))) Mbps. Medição concluída"
        case .error:            return "Medição indisponível"
        case .connectionChanged:return "Medição interrompida porque a rede mudou"
        }
    }

    private var phaseMessage: String {
        switch viewModel.uiPhase {
        case .idle:             return "Pronto para medir."
        case .connecting:       return "Conectando ao servidor mais próximo…"
        case .downloading:      return "Medindo Download…"
        case .uploading:        return "Medindo Upload…"
        case .done:             return "Medição concluída."
        case .error:            return viewModel.failureReason == .offline ? "Sem conexão com a internet." : "Não foi possível medir."
        case .connectionChanged:return "A rede mudou durante a medição."
        }
    }

    private static func speedGaugeScale(for value: Double) -> Double {
        guard value > 0 else { return 1 }
        let mag = pow(10, floor(log10(value)))
        for m in [1.0, 2.0, 5.0, 10.0] {
            let c = m * mag; if value <= c { return c }
        }
        return 10 * mag
    }
}

// MARK: - MacMetricRing

private struct MacMetricRing: View {
    var isConnecting: Bool
    var progress: Double
    var value: String
    var unit: String?

    private var clamped: Double { max(0, min(1, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.borderDefault, lineWidth: 10)

            if !isConnecting {
                Circle()
                    .trim(from: 0, to: max(0.001, clamped))
                    .stroke(Color.brandAccentWarm, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.08), value: clamped)
            }

            VStack(spacing: 4) {
                if isConnecting {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.brandAccentWarm)
                } else if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 42, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let unit {
                        Text(unit.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .tracking(0.8)
                    }
                }
            }
        }
    }
}
#endif

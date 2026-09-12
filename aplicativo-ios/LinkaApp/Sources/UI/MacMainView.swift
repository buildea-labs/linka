#if os(macOS)
import SwiftUI
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaEntitlements
import LinkaModules
import NetworkConnectivityTriage

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

    private var isPlusActive: Bool {
        LinkaEntitlementPolicy.decision(for: .assist, snapshot: entitlements.snapshot, at: Date()).isGranted
    }

    private var currentMeasurement: NetworkMeasurement? {
        guard viewModel.uiPhase == .done else { return nil }
        return viewModel.latestFinishedMeasurement
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
        .onChange(of: viewModel.uiPhase) { phase in
            guard phase == .done, pendingAssistMeasurement else { return }
            pendingAssistMeasurement = false
            showAssistResult = true
        }
        .onChange(of: intentCoordinator.pendingStartSpeedTest) { pending in
            guard pending else { return }
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
        .onAppear {
            viewModel.refreshLiveNetwork()
        }
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
                Divider()
                supplementalContent
                    .frame(width: 280, alignment: .leading)
            }
            .padding(28)
            .linkaCard(cornerRadius: LinkaRadius.lg)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                measurementContent
                Divider()
                supplementalContent
            }
            .padding(24)
            .linkaCard(cornerRadius: LinkaRadius.lg)
        }
    }

    private var measurementContent: some View {
        VStack(spacing: 0) {
            cardHeaderRow

            VStack(spacing: 8) {
                SemicircularGauge(fraction: gaugeFraction)
                    .frame(width: 240, height: 120)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Progresso da medição")
                    .accessibilityValue(gaugeAccessibilityValue)
                Text(phaseMessage)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 18)
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            statsRow
                .padding(.vertical, 14)
                .overlay(
                    VStack {
                        Divider()
                        Spacer()
                        Divider()
                    }
                )

            actionRow
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var cardHeaderRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(activeMetricValue)
                        .font(.heroValueHuge)
                        .foregroundColor(.textPrimary)
                    Text("Mbps")
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
                Text(activeMetricTitle)
                    .font(.monoCaption)
                    .textCase(.uppercase)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            if let serverLabel {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Servidor")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                    Text(serverLabel)
                        .font(.captionStrong)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.surfacePage, in: Capsule())
            }
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
                Button("Testar velocidade") { viewModel.startTest() }
                    .buttonStyle(.linkaPrimary)
                    .frame(maxWidth: 280)
            )
        case .connecting, .downloading, .uploading:
            return AnyView(
                Button("Cancelar") { viewModel.skipOrCancel() }
                    .buttonStyle(.linkaSecondary)
            )
        case .done:
            return AnyView(
                HStack(spacing: 10) {
                    Button("Testar novamente") { viewModel.startTest() }
                        .buttonStyle(.linkaPrimary)
                        .frame(maxWidth: 280)
                    Button {
                        requestAssistFromResult()
                    } label: {
                        Label("Assist", systemImage: "sparkles")
                    }
                    .buttonStyle(.linkaSecondary)
                }
            )
        case .error:
            return AnyView(
                HStack(spacing: 10) {
                    Button("Tentar novamente") { viewModel.startTest() }
                        .buttonStyle(.linkaPrimary)
                        .frame(maxWidth: 280)
                    Button("Verificar conexão") { showConnectivityTriage = true }
                        .buttonStyle(.linkaSecondary)
                }
            )
        case .connectionChanged:
            return AnyView(
                Button("Testar conexão") { viewModel.startTest() }
                    .buttonStyle(.linkaPrimary)
                    .frame(maxWidth: 280)
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
    }

    // MARK: - Painel Histórico (D2)

    private var historyPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.recentMeasurements.isEmpty {
                    LinkaUnavailableState(
                        title: "Nenhuma medição ainda",
                        message: "Teste sua velocidade para ver o histórico aqui.",
                        systemImage: "clock"
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentMeasurements) { measurement in
                            recentMeasurementRow(measurement)
                        }
                    }
                    .padding(20)
                    .linkaCard()
                }
            }
            .padding(28)
            .frame(maxWidth: 760)
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

    private var serverLabel: String? {
        guard isFinalResult else { return nil }
        if let identifier = currentMeasurement?.serverIdentifier, !identifier.isEmpty {
            return identifier
        }
        return nil
    }

    private var wifiBandLabel: String? {
        guard isFinalResult, let band = currentMeasurement?.wifiBandGHz else { return nil }
        let formatted = band.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", band) : String(format: "%.1f", band)
        return "\(formatted) GHz"
    }

    private var isFinalResult: Bool {
        viewModel.uiPhase == .done
    }

    private func finalStatValue(_ value: Double, measured: Bool) -> String {
        isFinalResult && measured ? "\(Int(round(value)))" : "—"
    }

    private var finalPacketLossValue: String {
        guard isFinalResult, let packetLoss = viewModel.packetLossPercent else { return "—" }
        return "\(Int(round(packetLoss)))"
    }

    private var activeMetricTitle: String {
        switch viewModel.uiPhase {
        case .uploading:
            return "Upload"
        default:
            return "Download"
        }
    }

    private var activeMetricValue: String {
        switch viewModel.uiPhase {
        case .idle, .connecting, .error, .connectionChanged:
            return "—"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .uploading:
            return String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ",")
        case .done:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        }
    }

    private var gaugeFraction: Double {
        switch viewModel.uiPhase {
        case .idle, .error, .connectionChanged:
            return 0
        case .connecting, .downloading, .uploading, .done:
            return max(0, min(1, viewModel.progress))
        }
    }

    private var gaugeAccessibilityValue: String {
        switch viewModel.uiPhase {
        case .idle:
            return "Medição pronta para iniciar"
        case .connecting:
            return "Conectando ao servidor"
        case .downloading, .uploading:
            return "\(activeMetricTitle), \(Int(round(gaugeFraction * 100))) por cento concluído"
        case .done:
            return "Medição concluída"
        case .error:
            return "Medição indisponível"
        case .connectionChanged:
            return "Medição interrompida porque a rede mudou"
        }
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
            return "Medindo velocidade de upload…"
        case .done:
            return "Sua conexão está pronta."
        case .error:
            return viewModel.failureReason == .offline ? "Sem conexão com a internet." : "Não foi possível medir."
        case .connectionChanged:
            return "A rede mudou durante a medição."
        }
    }
}

/// Gauge semicircular de progresso: a extensão do arco representa apenas a
/// fase atual da medição, nunca uma escala de Mbps.
private struct SemicircularGauge: View {
    var fraction: Double

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

            }
            .frame(width: diameter, height: diameter, alignment: .top)
        }
    }
}
#endif

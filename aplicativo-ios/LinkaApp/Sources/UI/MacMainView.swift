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
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(entitlements)
            }
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                if purchaseEntryPoint == .assist { showAssistProblemSelection = true }
            }
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
            viewModel.startTest()
            intentCoordinator.consumeStartSpeedTestRequest()
        }
        .onChange(of: intentCoordinator.pendingOpenHistory) { pending in
            guard pending else { return }
            destination = .history
            intentCoordinator.consumeOpenHistory()
        }
        .onAppear {
            viewModel.refreshLiveNetwork()
        }
    }

    // MARK: - Header (D2, D4)

    private var header: some View {
        HStack {
            Spacer()
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
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustes")
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
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    // MARK: - Painel Velocímetro (D3)

    private var speedTestPane: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 18) {
                mainCard
                    .frame(maxWidth: .infinity)
                sideColumn
                    .frame(width: 300)
            }
            .padding(28)
        }
    }

    private var mainCard: some View {
        VStack(spacing: 0) {
            cardHeaderRow

            VStack(spacing: 8) {
                SemicircularGauge(fraction: gaugeFraction)
                    .frame(width: 240, height: 120)
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
        }
        .padding(24)
        .linkaCard(cornerRadius: LinkaRadius.lg)
    }

    private var cardHeaderRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(heroValueText)
                        .font(.heroValueHuge)
                        .foregroundColor(.textPrimary)
                    Text("Mbps")
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
                Text("Download")
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
            statColumn(title: "Upload", value: statValue(viewModel.uploadSpeed, measured: viewModel.hasMeasuredUpload), unit: viewModel.hasMeasuredUpload ? "Mbps" : nil)
            statColumn(title: "Latência", value: statValue(Double(viewModel.ping), measured: viewModel.hasMeasuredPing), unit: viewModel.hasMeasuredPing ? "ms" : nil)
            statColumn(title: "Perdas", value: viewModel.packetLossPercent.map { "\(Int(round($0)))" } ?? "—", unit: viewModel.packetLossPercent == nil ? nil : "%")
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
                    Button("Verificar conexão") { showConnectivityTriage = true }
                        .buttonStyle(.linkaSecondary)
                }
            )
        case .connectionChanged:
            return AnyView(
                Button("Testar conexão") { viewModel.startTest() }
                    .buttonStyle(.linkaPrimary)
            )
        }
    }

    // MARK: - Coluna lateral

    private var sideColumn: some View {
        VStack(spacing: 16) {
            techDetailsCard
            recentMeasurementsCard
        }
    }

    private var techDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalhes técnicos")
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
            VStack(spacing: 0) {
                techDetailRow(label: "Jitter", value: currentMeasurement?.jitterMs.map { "\(Int(round($0))) ms" } ?? "—")
                techDetailRow(label: "Faixa Wi-Fi", value: wifiBandLabel ?? "—")
                techDetailRow(label: "Duração do teste", value: viewModel.testDuration.isEmpty ? "—" : viewModel.testDuration)
            }
        }
        .padding(18)
        .linkaCard()
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

    private var recentMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Últimas medições")
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
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
        .padding(18)
        .linkaCard()
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
        if let identifier = currentMeasurement?.serverIdentifier, !identifier.isEmpty {
            return identifier
        }
        if !viewModel.liveNetworkLabel.isEmpty {
            return viewModel.liveNetworkLabel
        }
        return nil
    }

    private var wifiBandLabel: String? {
        guard let band = currentMeasurement?.wifiBandGHz ?? viewModel.wifiBandGHz else { return nil }
        let formatted = band.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", band) : String(format: "%.1f", band)
        return "\(formatted) GHz"
    }

    private func statValue(_ value: Double, measured: Bool) -> String {
        measured ? "\(Int(round(value)))" : "—"
    }

    private var heroValueText: String {
        switch viewModel.uiPhase {
        case .idle:
            return "—"
        case .connecting:
            return "—"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .uploading, .done:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .error, .connectionChanged:
            return "—"
        }
    }

    private var gaugeFraction: Double {
        let maxValue = 300.0
        switch viewModel.uiPhase {
        case .idle, .connecting, .error, .connectionChanged:
            return 0
        case .downloading, .uploading, .done:
            return max(0, min(1, viewModel.downloadSpeed / maxValue))
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

/// Gauge semicircular (D1) — decisão da Íris de unificar a forma em vez de
/// manter dois componentes de métrica divergentes por plataforma. Só usado
/// pelo Mac nesta entrega; não está integrado ao Design System compartilhado
/// para não introduzir um componente novo que o iOS ainda não usa.
private struct SemicircularGauge: View {
    var fraction: Double

    private var clamped: Double { max(0, min(1, fraction)) }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height * 2)
            let lineWidth: CGFloat = 12
            let needleLength = diameter / 2 - lineWidth - 10

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

                Capsule()
                    .fill(Color.textPrimary)
                    .frame(width: 2, height: needleLength)
                    .offset(y: -needleLength / 2)
                    .rotationEffect(.degrees(-90 + 180 * clamped), anchor: .bottom)
                    .frame(width: diameter, height: diameter)

                Circle()
                    .fill(Color.textPrimary)
                    .frame(width: 7, height: 7)
                    .frame(width: diameter, height: diameter)
            }
            .frame(width: diameter, height: diameter, alignment: .top)
        }
    }
}
#endif

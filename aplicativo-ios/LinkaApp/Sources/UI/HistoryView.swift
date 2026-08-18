// Justificativa de Arquitetura (validarModularidade):
// Este arquivo contém tanto a listagem quanto a renderização do mapa em uma só tela.
// Manter junto facilita transições de dados e escopo de binding do histórico.
import SwiftUI
import MapKit
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules

enum HistoryDisplayMode {
    case list
    case map
}

struct HistoryView: View {
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var measurements: [NetworkMeasurement] = []
    @State private var isLoading = true
    @State private var hasPlus = false
    @State private var showAssist = false
    @State private var showPurchase = false
    @State private var insightText: String?
    @State private var displayMode: HistoryDisplayMode = .list

    // Computada (não `let`) de propósito: `entitlements` vem de
    // `@EnvironmentObject` e ainda não está disponível no momento em que
    // as outras propriedades armazenadas desta `View` seriam inicializadas
    // — uma `let` aqui referenciando `entitlements` não compilaria.
    private var repository: any MeasurementHistoryRepository {
        LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
    }

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
                        showPurchase = true
                    }
                    .font(.buttonLabel)
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
                VStack(spacing: 0) {
                    HStack {
                        Text("Histórico")
                            .font(.displayTitle)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .background(Color.surfacePage)

                    if displayMode == .list {
                    List {
                        // Assist Insight Card — text only when we have something to say,
                    // but the "Perguntar ao Assist" CTA is always available so the
                    // user can reach the Assist even before enough data exists for
                    // a weekly insight.
                    Section {
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24))
                                .foregroundColor(.brandAccentWarm)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Insight da Semana")
                                    .font(.bodyRegularStrong)
                                    .foregroundColor(.textPrimary)

                                if let insightText {
                                    Text(insightText)
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    Text("Ainda não há dados suficientes para um resumo semanal — faça alguns testes ao longo dos dias.")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Button(action: {
                                    // Assist é Plus. Free vai direto pra
                                    // tela de assinatura em vez de sheet.
                                    let assistDecision = LinkaEntitlementPolicy.decision(
                                        for: .assist,
                                        snapshot: entitlements.snapshot,
                                        at: Date()
                                    )
                                    if assistDecision.isGranted {
                                        showAssist = true
                                    } else {
                                        showPurchase = true
                                    }
                                }) {
                                    Text("Perguntar ao Assist")
                                        .font(.captionSmallStrong)
                                        .foregroundColor(.brandAccentWarm)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.surfaceCard)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

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
                                    .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                #if canImport(UIKit)
                .listStyle(.plain)
                #else
                // `.insetGrouped` é iOS-only (issue #108); no macOS o estilo
                // padrão da `List` já se comporta como sidebar/inset nativo,
                // sem equivalente 1:1 que valha a pena forçar aqui.
                .listStyle(.automatic)
                #endif
                .scrollContentBackground(.hidden)
                .background(Color.surfacePage)
                    } else {
                        MapHistoryView(measurements: measurements)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hasPlus {
                if FeatureFlags.isCoverageMapEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Picker("Modo", selection: $displayMode) {
                            Image(systemName: "list.bullet").tag(HistoryDisplayMode.list)
                            Image(systemName: "map").tag(HistoryDisplayMode.map)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }
                }
            }
        }
        #if canImport(UIKit)
        // `navigationBarTitleDisplayMode` não existe no macOS — lá a
        // titlebar não tem os modos large/inline do UIKit (issue #108).
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(isPresented: $showAssist) {
            // `onRetry` fica de fora deliberadamente (issue #58): esta tela
            // só olha medições passadas, sem caminho de início de teste
            // disponível no contexto. Sem esse closure, `AssistView` nem
            // calcula a sugestão `.retryMeasurement` — decisão explícita no
            // adapter, não um botão escondido depois de calculado.
            AssistView(
                currentMeasurement: measurements.first,
                recentMeasurements: Array(measurements.dropFirst().prefix(19)),
                entitlements: entitlements
            )
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet()
                .environmentObject(entitlements)
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        Task {
            let decision = LinkaEntitlementPolicy.decision(
                for: .history,
                snapshot: entitlements.snapshot,
                at: Date()
            )

            hasPlus = decision.isGranted

            // Usuário Free tentando acessar Histórico: abre a tela de
            // assinatura direto em cima do upsell — evita fricção de dois
            // toques ("entrei em Histórico, agora leio o texto, agora aperto
            // o botão"). O upsell continua embaixo como fallback caso o
            // usuário feche o sheet e queira voltar.
            if !hasPlus {
                showPurchase = true
            }

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

        // Insights (comparação de períodos) é uma capacidade Plus própria,
        // separada de `.history` — consulta a mesma fonte de entitlement
        // antes de calcular, sem duplicar a regra de acesso aqui.
        let insightsAnalyzer = EntitlementGatedNetworkInsightsAnalyzer(
            wrapping: BasicNetworkInsightsAnalyzer(),
            snapshot: entitlements.snapshot
        )

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
        .environmentObject(StoreKitEntitlementProvider())
    }
}

struct HistoryRow: View {
    let measurement: NetworkMeasurement
    @State private var isExpanded = false
    @State private var showShareSheet = false

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
                            Image(systemName: connectionIconName(for: measurement.connectionKind))
                                .font(.captionSmallStrong)
                            Text(connectionLabel(for: measurement.connectionKind))
                                .font(.monoCaption)
                        }
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.monoEyebrow)
                                .foregroundColor(.brandAccentWarm)
                            Text(formatSpeed(measurement.downloadMbps))
                                .font(.monoEyebrow)
                                .foregroundColor(.textPrimary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.monoEyebrow)
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

                    HStack(alignment: .top) {
                        DetailItem(
                            label: "PING",
                            value: formatPing(measurement.latencyMs),
                            explanation: measurement.latencyMs != nil ? MetricExplanation.ping : nil
                        )
                        Spacer()
                        DetailItem(
                            label: "JITTER",
                            value: formatPing(measurement.jitterMs),
                            explanation: measurement.jitterMs != nil ? MetricExplanation.jitter : nil
                        )
                        Spacer()
                        DetailItem(
                            label: "PERDA",
                            value: measurement.packetLossPercent != nil ? "\(Int(measurement.packetLossPercent!))%" : "--",
                            explanation: measurement.packetLossPercent != nil ? MetricExplanation.packetLoss : nil
                        )
                    }

                    // Latência sob carga (issue #53) — dado já era salvo desde
                    // a issue #52, só nunca tinha superfície de leitura no
                    // Histórico. `nil` some, sem "--" ao lado de explicação.
                    if let loadedLatencyMs = measurement.loadedLatencyMs {
                        HStack {
                            DetailItem(
                                label: "LATÊNCIA SOB CARGA",
                                value: String(format: "%.0f ms", loadedLatencyMs),
                                explanation: MetricExplanation.loadedLatency
                            )
                            Spacer()
                        }
                    }

                    HStack {
                        DetailItem(label: "SERVIDOR", value: measurement.serverIdentifier ?? "Automático")
                        Spacer()
                        // Duração real do teste (issue #50) — fato que o
                        // motor já media e a ViewModel descartava antes de
                        // chegar ao registro salvo. `nil` continua `nil`
                        // (registro legado ou teste sem duração reportada),
                        // nunca inferido.
                        DetailItem(label: "DURAÇÃO", value: formatDuration(measurement.durationMs))
                        Spacer()
                        // Banda Wi-Fi confirmada pelo sistema (issue #51) —
                        // só aparece quando a plataforma realmente informou
                        // (hoje, Mac via CoreWLAN); ausência é normal e não
                        // renderiza nada, sem competir por espaço.
                        if let wifiBandGHz = measurement.wifiBandGHz {
                            DetailItem(label: "BANDA WI-FI", value: formatBand(wifiBandGHz))
                        }
                    }
                }
                .padding(.bottom, 8)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        // Compartilhar esta medição do Histórico (issue #54) — ação por
        // linha, sem afetar o resto da lista nem competir com o toque que
        // expande/recolhe os detalhes.
        .swipeActions(edge: .trailing) {
            Button {
                showShareSheet = true
            } label: {
                Label("Compartilhar", systemImage: "square.and.arrow.up")
            }
            .tint(Color.brandAccentWarm)
        }
        .shareMeasurementSheet(isPresented: $showShareSheet, measurement: measurement)
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

    /// Issue #51: antes disso, Ethernet nunca era produzido de fato — o
    /// ícone caía sempre no `else` de celular. Agora que Ethernet é uma
    /// amostra real (`SpeedTestViewModel`), o ícone precisa refletir isso.
    private func connectionIconName(for kind: NetworkConnectionKind?) -> String {
        switch kind {
        case .wifi: return "wifi"
        case .cellular: return "cellularbars"
        case .ethernet: return "cable.connector"
        case .other, .none: return "questionmark.circle"
        }
    }

    /// Issue #50: `durationMs` só existe em registros salvos depois da
    /// correção — `nil` é o estado normal para histórico antigo e continua
    /// exibindo "--", sem inventar valor.
    private func formatDuration(_ durationMs: Int?) -> String {
        guard let durationMs = durationMs else { return "--" }
        return String(format: "%.1fs", Double(durationMs) / 1000.0).replacingOccurrences(of: ".", with: ",")
    }

    private func formatBand(_ ghz: Double) -> String {
        let value = ghz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", ghz)
            : String(format: "%.1f", ghz)
        return "\(value)GHz"
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    /// Explicação curta opcional (issue #53). `nil` quando a métrica não tem
    /// explicação (ex.: SERVIDOR, DURAÇÃO, BANDA WI-FI) ou quando o valor
    /// subjacente é ausente — nunca aparece ao lado de "--".
    var explanation: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.monoCaption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.bodySmall.weight(.medium))
                .foregroundColor(.textPrimary)
            if let explanation {
                Text(explanation)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let explanation else { return "\(label): \(value)" }
        return "\(label): \(value). \(explanation)"
    }
}



struct MapLocationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct MapHistoryView: View {
    let measurements: [NetworkMeasurement]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.55052, longitude: -46.633308),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var locationItems: [MapLocationItem] {
        measurements.compactMap { m in
            if let loc = m.location {
                return MapLocationItem(id: m.id, coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), title: m.serverIdentifier ?? "Medição")
            }
            return nil
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locationItems) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Circle()
                    .fill(Color.brandAccentWarm)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .onAppear {
            if let first = locationItems.first {
                region.center = first.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        }
    }
}


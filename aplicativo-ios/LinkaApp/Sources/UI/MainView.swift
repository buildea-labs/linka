// Justificativa de Arquitetura (validarModularidade):
// Este arquivo coordena a hierarquia principal da interface de medição e a disposição dos painéis auxiliares.
// Dividi-lo criaria complexidade de injeção de estado desnecessária na raiz do aplicativo.
import SwiftUI
import AudioToolbox
import LinkaEngine
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    // Ponte para o pedido de "Testar" vindo do Widget/Siri/Shortcuts via
    // `StartSpeedTestIntent` (issue #55) — ver `AppIntentCoordinator`.
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared
    @State private var detailsOpen: Bool = false
    @State private var showPurchase: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @Namespace private var animation
    // Sinal de ciclo de vida (issue #65) — `@Environment(\.scenePhase)` é
    // cross-platform SwiftUI e cobre iPhone, iPad e Mac com o mesmo código,
    // sem `#if os(iOS)` espalhado (AGENTS.md §2: Mac é destino de primeira
    // classe, não Catalyst-gambiarra). Toda a decisão do que fazer com a
    // mudança de fase vive em `viewModel.handleScenePhaseChange(_:)` — esta
    // view só repassa o valor.
    @Environment(\.scenePhase) private var scenePhase

    private var currentMeasurement: NetworkMeasurement? {
        guard viewModel.uiPhase == .done else { return nil }
        return NetworkMeasurement(
            outcome: .complete,
            downloadMbps: viewModel.downloadSpeed,
            uploadMbps: viewModel.uploadSpeed,
            latencyMs: Double(viewModel.ping),
            jitterMs: viewModel.jitter,
            packetLossPercent: viewModel.packetLossPercent,
            // Issue #51: usa a amostra real do próprio `viewModel` (início vs.
            // fim do teste, via `NWPathMonitor` independente do motor) em vez
            // de rederivar de `networkType` (string legada de exibição). Os
            // dois caminhos divergiam antes — este era o único que mapeava
            // qualquer string desconhecida para `.cellular`, mesmo num Mac
            // cabeado (Ethernet nunca era produzido).
            connectionKind: viewModel.connectionKind,
            wifiBandGHz: viewModel.wifiBandGHz,
            networkIdentifier: viewModel.provider.isEmpty ? nil : viewModel.provider
        )
    }

    /// Suprime anúncios para quem tem Linka Plus ativo agora. "Sem anúncios"
    /// não é uma `LinkaCapability` própria, mas a checagem de "Plus ativo
    /// agora" precisa ser a mesma em todo o app — por isso delega para
    /// `LinkaEntitlementPolicy.decision`, usando `.history` (capability
    /// exclusiva do plano Plus) como proxy, em vez de reimplementar a
    /// leitura de `status`/`validUntil` aqui. Ler `snapshot.status` sozinho
    /// não revalida `validUntil` contra o relógio atual; `decision` faz isso.
    private var isPlusActive: Bool {
        LinkaEntitlementPolicy.decision(
            for: .assist,
            snapshot: entitlements.snapshot,
            at: Date()
        ).isGranted
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePage.ignoresSafeArea()
                
                VStack(spacing: 0) {

                    Spacer()
                    
                    if viewModel.uiPhase == .error {
                        // Error UI (issue #66) — motor parou e cancelou
                        // sozinho. Sem ring/PhaseDots animando: o estado é
                        // "parado", não "medindo". Copy curta mapeada de
                        // `failureReason` vive só aqui; motor só expõe fato
                        // tipado (AGENTS.md §8).
                        VStack(spacing: 20) {
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
                        }
                    } else if viewModel.uiPhase != .done {
                        // Measuring UI
                        VStack(spacing: 0) {
                            MetricRing(
                                connecting: viewModel.uiPhase == .connecting || viewModel.uiPhase == .idle,
                                progress: viewModel.progress,
                                value: ringValue,
                                unit: (viewModel.uiPhase == .connecting || viewModel.uiPhase == .idle) ? nil : "Mbps",
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

                            // Saída única do teste em andamento (issue #47).
                            // "Pular" (primeira medição automática) e
                            // "Cancelar" (reteste) são o mesmo botão e a
                            // mesma chamada técnica — só o texto muda,
                            // derivado de `hasValidResult`. Secundário de
                            // propósito: texto pequeno, sem fundo, sem
                            // competir com o MetricRing.
                            //
                            // Quando o teste já foi pulado e uiPhase caiu em
                            // `.idle` sem snapshot para restaurar, o botão
                            // vira "Testar" acionando startTest() — dá a saída
                            // explícita que o R3 tinha tentado resolver com
                            // auto-restart (que confundia: parecia que Pular
                            // não fazia nada porque o teste reiniciava sozinho).
                            if viewModel.uiPhase == .idle && !viewModel.hasValidResult && !viewModel.isTesting {
                                Button(action: {
                                    viewModel.startTest()
                                }) {
                                    Text("Testar")
                                        .font(.buttonLabel)
                                        .foregroundColor(Color.surfacePage)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                            } else {
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
                            }
                        }
                        // removed transition to allow fluid geometry effect
                    } else {
                        // Result UI
                        VStack(spacing: 0) {
                            MetricRing(
                                connecting: false,
                                // No resultado, o arco deixa de representar
                                // progresso e passa a ser a moldura estável
                                // da medição concluída.
                                progress: 1.0,
                                value: String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ","),
                                unit: "Mbps",
                                size: 210,
                                animation: animation,
                                matchedId: "downloadValue"
                            )
                            .padding(.bottom, 24)
                            
                            Text("DOWNLOAD")
                                .font(.monoEyebrow)
                                .foregroundColor(.textSecondary)
                                .tracking(1.0)
                                .padding(.bottom, 8)
                            
                            HStack(spacing: 6) {
                                Text(String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ","))
                                    .font(.metricSecondary)
                                    .foregroundColor(.textPrimary)
                                Text("Mbps upload")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                
                                Text("·")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                Text("\(viewModel.ping)")
                                    .font(.metricSecondary)
                                    .foregroundColor(.textPrimary)
                                Text("ms ping")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)

                                Text("·")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 4)

                                Text(String(format: "%.0f", viewModel.jitter))
                                    .font(.metricSecondary)
                                    .foregroundColor(.textPrimary)
                                Text("ms jitter")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Upload, \(formatted(viewModel.uploadSpeed)) megabits por segundo. Ping, \(viewModel.ping) milissegundos. Jitter, \(String(format: "%.0f", viewModel.jitter)) milissegundos.")
                            .padding(.bottom, 14)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(reduceMotion ? nil : LinkaMotion.spring) {
                                        detailsOpen.toggle()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Text(detailsOpen ? "Ocultar detalhes" : "Ver detalhes")
                                            .font(.bodySmallStrong)

                                        Image(systemName: "chevron.down")
                                            .font(.captionStrong)
                                            .rotationEffect(.degrees(detailsOpen ? 180 : 0))
                                    }
                                    .foregroundColor(.textPrimary)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 16)

                            if detailsOpen {
                                InlineResultDetails(
                                    operatorName: viewModel.networkType.isEmpty ? "--" : viewModel.networkType,
                                    provider: viewModel.provider.isEmpty ? "--" : viewModel.provider,
                                    duration: viewModel.testDuration.isEmpty ? "--" : viewModel.testDuration,
                                    ping: viewModel.ping,
                                    wifiBandGHz: viewModel.wifiBandGHz,
                                    jitter: viewModel.jitter,
                                    packetLossPercent: viewModel.packetLossPercent,
                                    loadedLatencyMs: viewModel.loadedLatencyMs,
                                    loadedLatencyUploadMs: viewModel.loadedLatencyUploadMs
                                )
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // O resultado não duplica a medição em uma linha
                            // de "Último teste" nem promete uma resposta do
                            // Assist por meio de skeleton. O Assist continua
                            // disponível para Plus como ação secundária,
                            // somente quando pode ser aberto de verdade.
                            if isPlusActive {
                                NavigationLink {
                                    AssistView(
                                        currentMeasurement: currentMeasurement,
                                        recentMeasurements: viewModel.recentMeasurements,
                                        onRetry: { viewModel.startTest() },
                                        entitlements: entitlements
                                    )
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                        Text("Abrir Assist")
                                            .font(.bodySmallStrong)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.captionStrong)
                                    }
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 32)
                                .padding(.top, 4)
                            }
                            
                            Spacer(minLength: 16)

                            if !isPlusActive && FeatureFlags.isAdsEnabled {
                                BannerView()
                                    .padding(.bottom, 8)
                            }

                            // Bottom Action Button
                            Button(action: {
                                detailsOpen = false
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
                            .padding(.bottom, 24)
                        }
                    }

                    if viewModel.uiPhase != .done {
                        Spacer()
                    }
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.uiPhase == .idle || viewModel.uiPhase == .connecting || viewModel.uiPhase == .done || viewModel.uiPhase == .error {
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
                #else
                ToolbarItemGroup {
                    if viewModel.uiPhase == .idle || viewModel.uiPhase == .connecting || viewModel.uiPhase == .done || viewModel.uiPhase == .error {
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
                #endif
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onAppear {
            // Início e carga de histórico controlados por SpeedTestViewModel.init()
        }
        // Widget/Siri/Shortcuts pediram uma medição (issue #55): se o app
        // já estava aberto (foreground), `.onAppear` acima não dispara de
        // novo — é este `onChange` que garante que "Testar" no widget
        // sempre inicia o teste. Se o app estava fechado, o cold launch já
        // chama `.onAppear` → `startTest()`; `startTest()` é idempotente
        // (`guard !isTesting`), então rodar os dois caminhos junto é
        // inofensivo, nunca duplica o teste.
        .onChange(of: intentCoordinator.pendingStartSpeedTest) { pending in
            guard pending else { return }
            viewModel.startTest()
            intentCoordinator.consumeStartSpeedTestRequest()
        }
        .onChange(of: intentCoordinator.pendingPurchasePrompt) { pending in
            guard pending else { return }
            // Widget/Siri disparado por usuário Free (decisão do Luiz
            // 2026-08-15: acionar via integração Apple é Plus-only) — abre
            // paywall em vez de rodar medição.
            showPurchase = true
            intentCoordinator.consumePurchasePrompt()
        }
        // Compartilhar continua disponível como swipe-action no Histórico
        // (feedback do Luiz: tela de resultado carregada demais). A UX de
        // compartilhar por medição individual vive só lá agora.
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet()
                .environmentObject(entitlements)
        }
        .animation(reduceMotion ? nil : LinkaMotion.spring, value: viewModel.uiPhase)
        .onChange(of: scenePhase) { newPhase in
            // Mesmo padrão de `.onChange` de parâmetro único já usado neste
            // arquivo (issue #65) — mantém compatibilidade com o
            // deployment target atual, sem migrar para a assinatura de dois
            // parâmetros do iOS 17.
            viewModel.handleScenePhaseChange(newPhase)
        }
        .onChange(of: viewModel.uiPhase) { newPhase in
            switch newPhase {
            case .uploading:
                // Momento de transição download→upload: haptic médio + tick +
                // pulse rápido do ring pra tornar a mudança de fase perceptível.
                #if canImport(UIKit)
                // `UIImpactFeedbackGenerator` é iOS-only (issue #112); o
                // macOS não tem haptics de toque — o tick sonoro abaixo
                // já sinaliza a transição de fase lá.
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                AudioServicesPlaySystemSound(1104)
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
                // Mesmo motivo do haptic médio acima (issue #112): sem
                // equivalente no macOS.
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #else
                break
                #endif
            default:
                break
            }
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
        case .error:
            // Não exibido: a fase `.error` usa seu próprio branch visual,
            // sem `MetricRing` (ver `body`). Caso nunca chegue a alcançar.
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

    /// Título curto da falha fatal (issue #66). Copy vive só aqui — o motor
    /// só expõe `EngineFailureReason`, um fato tipado, nunca texto
    /// (AGENTS.md §8). Nunca culpa Wi-Fi ou provedor: descreve o fato
    /// (sem rede / conexão caiu), não a causa.
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
}

private struct InlineResultDetails: View {
    let operatorName: String
    let provider: String
    let duration: String
    let ping: Int
    let wifiBandGHz: Double?
    let jitter: Double
    let packetLossPercent: Double?
    let loadedLatencyMs: Double?
    /// Latência sob carga durante upload (issue #128) — mesmo tratamento de
    /// `loadedLatencyMs`: `nil` some, sem "--".
    let loadedLatencyUploadMs: Double?

    /// Categoria de responsividade sob carga (issue #128) — `nil`
    /// (`.notAssessed`) some da tela, mesmo padrão de qualquer métrica
    /// insuficiente aqui: nunca um estado fabricado.
    private var responsiveness: LoadResponsivenessCategory? {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: Double(ping),
            loadedDownloadLatencyMs: loadedLatencyMs,
            loadedUploadLatencyMs: loadedLatencyUploadMs
        )
        return result.category == .notAssessed ? nil : result.category
    }

    private var networkLabel: String {
        guard let wifiBandGHz else { return operatorName }
        let band = wifiBandGHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", wifiBandGHz)
            : String(format: "%.1f", wifiBandGHz)
        return "\(operatorName) · \(band) GHz"
    }

    var body: some View {
        VStack(spacing: 0) {
            InlineResultDetailRow(label: "Rede", value: networkLabel)
            InlineResultDetailRow(label: "Provedor", value: provider)
            InlineResultDetailRow(label: "Duração", value: duration)
            InlineResultDetailRow(label: "Ping", value: "\(ping) ms")
            InlineResultDetailRow(label: "Jitter", value: String(format: "%.0f ms", jitter))

            if let packetLossPercent {
                InlineResultDetailRow(label: "Perda de pacotes", value: "\(Int(packetLossPercent))%")
            }

            if let loadedLatencyMs {
                InlineResultDetailRow(label: "Latência sob carga (download)", value: String(format: "%.0f ms", loadedLatencyMs))
            }

            if let loadedLatencyUploadMs {
                InlineResultDetailRow(label: "Latência sob carga (upload)", value: String(format: "%.0f ms", loadedLatencyUploadMs))
            }

            if let responsiveness {
                InlineResultDetailRow(label: "Responsividade sob carga", value: LoadResponsivenessCopy.label(for: responsiveness))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderDefault, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct InlineResultDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

import SwiftUI
import AudioToolbox
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaEntitlements

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    // Ponte para o pedido de "Testar" vindo do Widget/Siri/Shortcuts via
    // `StartSpeedTestIntent` (issue #55) — ver `AppIntentCoordinator`.
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared
    @State private var detailsOpen: Bool = false
    @State private var showAssist: Bool = false
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
            for: .history,
            snapshot: entitlements.snapshot,
            at: Date()
        ).isGranted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePage.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Safe Area Padding
                    Color.clear.frame(height: 80)
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
                                progress: viewModel.progress,
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
                            }
                            .padding(.bottom, 24)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    detailsOpen = true
                                }) {
                                    HStack(spacing: 6) {
                                        Text("Ver detalhes")
                                            .font(.bodySmall)

                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .rotationEffect(.degrees(detailsOpen ? 180 : 0))
                                    }
                                    .foregroundColor(.textPrimary)
                                }
                                .buttonStyle(.plain)

                                Text("·")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)

                                Button(action: {
                                    // Assist é feature Plus. Usuário Free vai
                                    // direto para a tela de assinatura em vez
                                    // de abrir o sheet e receber mensagem
                                    // "faz parte do Plus" no meio da conversa.
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
                                    HStack(spacing: 6) {
                                        Text("Perguntar ao Assist")
                                            .font(.bodySmall)

                                        Image(systemName: "sparkles")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.textPrimary)
                                }
                                .buttonStyle(.plain)

                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            

                            
                            // Último teste Glass Pill
                            NavigationLink(destination: HistoryView()) {
                                HStack {
                                    Text("Último teste")
                                        .font(.bodySmall.weight(.medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.lastTestSpeedString ?? "Nenhum teste anterior")
                                        .font(.monoCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .padding(.horizontal, 32)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 24)
                            
                            Spacer(minLength: 16)

                            if !isPlusActive {
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
            .overlay(alignment: .topTrailing) {
                // Settings & History Glass Pills
                if viewModel.uiPhase == .idle || viewModel.uiPhase == .connecting || viewModel.uiPhase == .done || viewModel.uiPhase == .error {
                    HStack(spacing: 12) {
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        
                        NavigationLink(destination: SettingsSheet()) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
            }
            #if os(iOS)
            // `for: .navigationBar` é iOS-only (issue #112) — no macOS a
            // navigation bar tem semântica diferente (titlebar da janela) e
            // este overload de `.toolbar(.hidden, for:)` não existe.
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .onAppear {
            viewModel.startTest()
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
        .sheet(isPresented: $showAssist) {
            // `onRetry` reusa o mesmo `viewModel.startTest()` do botão
            // "Testar novamente"/"Tentar novamente" (issue #58) — nunca uma
            // nova chamada ao motor. `failureSignal` ainda não é passado
            // aqui (fiação ponta-a-ponta pendente de outro passo da cadeia,
            // ver comentário em `AssistSheet.failureSignal`); sem ele, a
            // sugestão `.retryMeasurement` nunca chega a ser calculada por
            // falta de `investigation`, então este closure fica pronto sem
            // efeito colateral até essa fiação fechar.
            AssistSheet(
                currentMeasurement: currentMeasurement,
                onRetry: { viewModel.startTest() },
                entitlements: entitlements
            )
        }
        // Compartilhar continua disponível como swipe-action no Histórico
        // (feedback do Luiz: tela de resultado carregada demais). A UX de
        // compartilhar por medição individual vive só lá agora.
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet()
                .environmentObject(entitlements)
        }
        .sheet(isPresented: $detailsOpen) {
            DetailsDisclosure(
                operatorName: viewModel.networkType.isEmpty ? "--" : viewModel.networkType,
                provider: viewModel.provider.isEmpty ? "--" : viewModel.provider,
                duration: viewModel.testDuration.isEmpty ? "--" : viewModel.testDuration,
                ping: viewModel.ping,
                wifiBandGHz: viewModel.wifiBandGHz,
                jitter: viewModel.jitter,
                packetLossPercent: viewModel.packetLossPercent,
                loadedLatencyMs: viewModel.loadedLatencyMs,
                downloadMbps: viewModel.downloadSpeed,
                uploadMbps: viewModel.uploadSpeed
            )
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
        .animation(LinkaMotion.spring, value: viewModel.uiPhase)
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
                withAnimation(LinkaMotion.pulse) {
                    ringScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(LinkaMotion.pulse) {
                        ringScale = 1.0
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

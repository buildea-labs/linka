// Justificativa de Arquitetura (validarModularidade):
// Este arquivo coordena a hierarquia principal da interface de medição e a disposição dos painéis auxiliares.
// Dividi-lo criaria complexidade de injeção de estado desnecessária na raiz do aplicativo.
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
    // Ponte para o pedido de "Testar" vindo do Widget/Siri/Shortcuts via
    // `StartSpeedTestIntent` (issue #55) — ver `AppIntentCoordinator`.
    @ObservedObject private var intentCoordinator = AppIntentCoordinator.shared
    @State private var detailsOpen: Bool = false
    @State private var showPurchase: Bool = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showAssist: Bool = false
    @State private var showConnectivityTriage: Bool = false
    @State private var showUsageDiagnostics: Bool = false
    @State private var showExpertModeMigrationBanner: Bool = false
    @State private var connectionPathExpanded: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @Namespace private var animation
    // Sinal de ciclo de vida (issue #65) — `@Environment(\.scenePhase)` é
    // cross-platform SwiftUI e cobre iPhone, iPad e Mac com o mesmo código,
    // sem `#if os(iOS)` espalhado (AGENTS.md §2: Mac é destino de primeira
    // classe, não Catalyst-gambiarra). Toda a decisão do que fazer com a
    // mudança de fase vive em `viewModel.handleScenePhaseChange(_:)` — esta
    // view só repassa o valor.
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

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

    private var canUseAdvancedWiFiDiagnostics: Bool {
        LinkaEntitlementPolicy.decision(
            for: .advancedWiFiDiagnostics,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    /// Gate de "Modo Expert" (jitter, perda de pacotes, DNS) — issue
    /// Expert Mode. Hoje só controla a exibição da linha de DNS (nova, sem
    /// risco de sensação de downgrade). Jitter/perda de pacotes continuam
    /// visíveis para todos até que o re-gate deles seja aprovado
    /// explicitamente (ver `plano-valor-linka.md` e checkpoint de produto).
    private var canUseExpertMode: Bool {
        LinkaEntitlementPolicy.decision(
            for: .expertMode,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    /// Gate da tela de diagnóstico de uso completo (`UsageDiagnosticsView`,
    /// um veredito por `UsageCase`) — capability nova e independente do
    /// Assist, mesmo quando hoje as duas vivem no mesmo plano Plus.
    private var canUseUsageDiagnostics: Bool {
        LinkaEntitlementPolicy.decision(
            for: .usageDiagnostics,
            snapshot: entitlements.snapshot
        ).isGranted
    }

    /// Evidência estruturada de adequação por uso, fundamentada na medição
    /// atual, entregue ao Assist via `NetworkAssistContext.usageContext` —
    /// issue Expert Mode/diagnóstico de uso. `nil` sem a capability (o
    /// Assist responde sem esse insumo extra, como hoje) ou sem medição.
    /// Caminho da Conexão (issue Caminho da Conexão, 2026-08-29) — leitura
    /// simplificada de onde a conexão provavelmente está falhando,
    /// derivada só dos fatos já medidos (`ConnectionPathEvaluator`, puro,
    /// em `NetworkInsights`). Disponível no Linka gratuito: ajuda a
    /// diferenciar o produto de um speed test comum sem depender de
    /// assinatura. `nil` sem medição concluída.
    private var connectionPathReport: ConnectionPathReport? {
        if viewModel.uiPhase == .done, let currentMeasurement {
            return ConnectionPathEvaluator().evaluate(currentMeasurement)
        }
        if let last = viewModel.latestFinishedMeasurement {
            return ConnectionPathEvaluator().evaluate(last)
        }
        return nil
    }

    private var statusTitle: String {
        guard let report = connectionPathReport else {
            return "Pronto para testar"
        }
        switch report.category {
        case .healthy: return "Conexão excelente"
        case .inconclusive: return "Conexão instável"
        case .local: return "Aparelho instável"
        case .wifi: return "Wi-Fi instável"
        case .carrier: return "Operadora instável"
        case .external: return "Internet oscilando"
        }
    }


    private var statusCircleColor: Color {
        guard let report = connectionPathReport else {
            return .textSecondary.opacity(0.15)
        }
        let statuses = report.stages.map { $0.status }
        if statuses.contains(.likelyProblem) {
            return .statusCritical
        } else if statuses.contains(.attention) {
            return .statusAttention
        } else {
            return .statusGood
        }
    }

    private var statusGlyphName: String {
        guard let report = connectionPathReport else {
            return "play.fill"
        }
        let statuses = report.stages.map { $0.status }
        if statuses.contains(.likelyProblem) {
            return "exclamationmark"
        } else if statuses.contains(.attention) {
            return "exclamationmark"
        } else {
            return "checkmark"
        }
    }

    /// Relatório de adequação por uso, calculado uma única vez e
    /// reaproveitado por `usageContextForAssist` e `usageQualityLevel`
    /// (issue "qualidade de uso Boa/Média/Ruim", 2026-08-29) — evita rodar
    /// `UsageSuitabilityEvaluator` duas vezes sobre a mesma medição.
    private var usageSuitabilityReport: UsageSuitabilityReport? {
        guard canUseUsageDiagnostics, let currentMeasurement else { return nil }
        return UsageSuitabilityEvaluator().evaluate(currentMeasurement)
    }

    private var usageContextForAssist: String? {
        guard let usageSuitabilityReport else { return nil }
        return UsageDiagnosticsAssistBridge.assistSummary(for: usageSuitabilityReport)
    }

    /// Nível agregado (Boa/Média/Ruim) exibido na linha "Qualidade de uso"
    /// — issue 2026-08-29. Proporção de casos `.adequate` entre os casos
    /// que puderam ser avaliados (`.notAssessed` não entra na conta: falta
    /// de dado não é "ruim", é "não sabemos", mesmo princípio de
    /// `ConnectionPathStageStatus.unavailable`). `nil` quando não há
    /// nenhum caso avaliável ainda — a linha não mostra nível nesse caso.
    private var usageQualityLevel: UsageQualityLevel? {
        guard let usageSuitabilityReport else { return nil }
        return UsageSuitabilityCopy.qualityLevel(for: usageSuitabilityReport)
    }

    /// Issue "Hero do resultado" (2026-08-29): jitter saiu da linha de
    /// destaque (fica só em "Ver detalhes"), então o rótulo de
    /// acessibilidade não precisa mais da ramificação condicional que
    /// motivava extrair isto do `body` — mantido como computed property
    /// só por organização.
    private var heroMetricsAccessibilityLabel: String {
        "Upload, \(formatted(viewModel.uploadSpeed)) megabits por segundo. Ping, \(viewModel.ping) milissegundos."
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

                            Button("Verificar conexão") {
                                showConnectivityTriage = true
                            }
                            .font(.bodySmallStrong)
                            .foregroundColor(.textPrimary)
                            .frame(minHeight: 44)
                            .accessibilityHint("Mostra os fatos de conexão observados neste aparelho")
                        }
                    } else if viewModel.uiPhase == .idle {
                        // New Idle (Início) UI inspired by SignallQ (Apple style, vertical centering)
                        VStack(spacing: 0) {
                            // 1. Caminho da Conexão no topo (se houver histórico)
                            if let connectionPathReport {
                                ConnectionPathView(report: connectionPathReport, expanded: $connectionPathExpanded)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                            
                            Spacer()
                            
                            // 2. Círculo de Status Central
                            ZStack {
                                Circle()
                                    .stroke(statusCircleColor.opacity(0.12), lineWidth: 8)
                                    .frame(width: 140, height: 140)
                                
                                Circle()
                                    .fill(statusCircleColor.opacity(0.06))
                                    .frame(width: 124, height: 124)
                                
                                Image(systemName: statusGlyphName)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(statusCircleColor)
                            }
                            .padding(.bottom, 12)
                            
                            // 3. Veredito em texto grande
                            Text(statusTitle)
                                .font(.heroConclusion)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            // 4. Botão de Ação Primário
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
                            .padding(.bottom, viewModel.hasValidResult ? 0 : 24)
                            
                            // 5. Card de Atalho para o Assist (se houver histórico)
                            if viewModel.hasValidResult {
                                Button(action: {
                                    showAssist = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.brandAccentWarm)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(Color.brandAccentWarm.opacity(0.12)))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Assistente de Conexão")
                                                .font(.bodySmallStrong)
                                                .foregroundColor(.textPrimary)
                                            Text("Entenda o diagnóstico e veja sugestões de melhoria")
                                                .font(.captionSmall)
                                                .foregroundColor(.textSecondary)
                                        }
                                        .multilineTextAlignment(.leading)
                                        
                                        Spacer(minLength: 0)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.captionSmall)
                                            .foregroundColor(.textSecondary.opacity(0.6))
                                    }
                                    .padding(.all, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.surfaceCard)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.borderDefault, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                                .padding(.bottom, 24)
                            }
                        }
                    } else if viewModel.uiPhase == .connecting || viewModel.uiPhase == .downloading || viewModel.uiPhase == .uploading {
                        // Measuring UI
                        VStack(spacing: 0) {
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
                        }
                        // removed transition to allow fluid geometry effect
                    } else {
                        // Result UI — issue UI Polish v2: o ring é uma
                        // moldura de progresso, faz sentido só enquanto o
                        // teste está em andamento. No resultado, ele
                        // desaparece (via `.animation` já aplicado a
                        // `uiPhase` no fim deste `body`) e o número de
                        // download vira conteúdo solto, protagonista —
                        // não um número dentro de um componente só porque
                        // o componente existe.
                        //
                        // `ScrollView` (issue Caminho da Conexão): o
                        // conteúdo do resultado cresceu (Caminho da
                        // Conexão + detalhes agrupados) e passou a
                        // estourar a altura da tela em telas menores ou
                        // com "Ver detalhes" expandido — sem isto, o
                        // conteúdo sobrepunha a barra de navegação em vez
                        // de rolar. Quando cabe na tela, o `Spacer()`
                        // logo acima continua empurrando o conteúdo para
                        // baixo como antes; só passa a rolar quando não
                        // cabe.
                        ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Hero — issue "Hero do resultado" (2026-08-29):
                            // a conclusão do diagnóstico abre a tela (não
                            // fica presa embaixo do Caminho da Conexão),
                            // texto solto sobre o fundo, sem card/banner.
                            // Muda conforme o diagnóstico real — reaproveita
                            // a mesma frase de `ConnectionPathCopy`, não
                            // duplica lógica de conclusão.
                            if let connectionPathReport {
                                Text(ConnectionPathCopy.conclusion(for: connectionPathReport))
                                    .font(.heroConclusion)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .accessibilityAddTraits(.isHeader)
                                    .padding(.bottom, 30)
                            }

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
                                .padding(.top, 4)

                            // Discreto de propósito — a pessoa já sabe que
                            // o número gigante é o resultado principal; o
                            // rótulo não precisa competir com a hero.
                            Text("DOWNLOAD")
                                .font(.heroText15)
                                .foregroundColor(.textSecondary.opacity(0.6))
                                .tracking(1.0)
                                .padding(.top, 6)
                                .padding(.bottom, 32)

                            // Upload/Ping com mais presença (issue "Hero do
                            // resultado") — jitter sai daqui, fica só em
                            // "Ver detalhes"; duas métricas secundárias
                            // ficam mais elegantes que três espremidas.
                            HStack(alignment: .top, spacing: 0) {
                                Spacer(minLength: 0)
                                secondaryMetricBlock(value: formatted(viewModel.uploadSpeed), unit: "Mbps", label: "Upload")
                                Spacer(minLength: 0)
                                secondaryMetricBlock(value: "\(viewModel.ping)", unit: "ms", label: "Ping")
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(heroMetricsAccessibilityLabel)
                            .padding(.bottom, 34)

                            // Contexto de rede — alinhado à esquerda de
                            // propósito (issue "Hero do resultado"): centralizar
                            // demais lê como painel, não como conteúdo de
                            // página comum.
                            if wifiContextLine != nil || providerLine != nil {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let wifiContextLine {
                                        Text(wifiContextLine)
                                            .font(.heroText17Semibold)
                                            .foregroundColor(.textPrimary)
                                    }
                                    if let providerLine {
                                        Text(providerLine)
                                            .font(.heroText17)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                            }

                            // Caminho da Conexão — só a representação
                            // visual aqui (sem título, sem repetir a
                            // conclusão, que já abriu a tela). Quase sem
                            // card: fundo da página, divisores sutis.
                            if let connectionPathReport {
                                ConnectionPathView(report: connectionPathReport, expanded: $connectionPathExpanded)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 26)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

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
                            .padding(.bottom, 22)

                            if detailsOpen {
                                InlineResultDetails(
                                    operatorName: viewModel.networkType.isEmpty ? "--" : viewModel.networkType,
                                    provider: viewModel.provider.isEmpty ? "--" : viewModel.provider,
                                    duration: viewModel.testDuration.isEmpty ? "--" : viewModel.testDuration,
                                    ping: viewModel.ping,
                                    connectionKind: viewModel.connectionKind,
                                    wifiBandGHz: viewModel.wifiBandGHz,
                                    wifiContext: viewModel.wifiContext,
                                    advancedWiFiDiagnostics: viewModel.advancedWiFiDiagnostics,
                                    advancedWiFiEnabled: canUseAdvancedWiFiDiagnostics,
                                    jitter: viewModel.jitter,
                                    packetLossPercent: viewModel.packetLossPercent,
                                    loadedLatencyMs: viewModel.loadedLatencyMs,
                                    loadedLatencyUploadMs: viewModel.loadedLatencyUploadMs,
                                    dnsResolutionMs: viewModel.dnsResolutionMs,
                                    expertModeEnabled: canUseExpertMode,
                                    onIdentifyNetwork: WiFiNetworkPermission.requestIdentification,
                                    onRunAdvancedWiFi: {
                                        if let url = URL(string: "shortcuts://") { openURL(url) }
                                    },
                                    onUnlockExpertMode: {
                                        purchaseEntryPoint = .settings
                                        showPurchase = true
                                    },
                                    onUnlockAdvancedWiFi: {
                                        purchaseEntryPoint = .advancedWiFi
                                        showPurchase = true
                                    }
                                )
                                .padding(.horizontal, 24)
                                .padding(.bottom, 22)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Button {
                                if isPlusActive {
                                    showAssist = true
                                } else {
                                    purchaseEntryPoint = .assist
                                    showPurchase = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    // Ícone trocado de "sparkles" (issue
                                    // "ícone do Assist", 2026-08-29) —
                                    // `sparkles` virou símbolo genérico de
                                    // "qualquer coisa com IA"; perfil +
                                    // cérebro comunica interpretação/
                                    // raciocínio, mais alinhado ao papel
                                    // do Assist no Linka. SF Symbol nativo,
                                    // não um ativo de marca novo (a única
                                    // fonte de verdade de ícones continua
                                    // `design_system/assets/icons/`,
                                    // AGENTS.md §7).
                                    Image(systemName: "brain.head.profile")
                                    Text("Entender este resultado").font(.bodySmallStrong)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.captionStrong)
                                }
                                .foregroundColor(.textPrimary)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 32)

                            Button {
                                if canUseUsageDiagnostics {
                                    showUsageDiagnostics = true
                                } else {
                                    purchaseEntryPoint = .settings
                                    showPurchase = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                    // Issue "ajuste fino do hero" (2026-08-29):
                                    // "Diagnóstico de uso" soava nome de
                                    // ferramenta interna. A função responde
                                    // "essa conexão serve pro que eu preciso
                                    // fazer" (streaming/jogo/trabalho) —
                                    // copy nova reflete isso. Mais curta que
                                    // "Qualidade para o meu uso" de propósito:
                                    // com o rótulo "Linka Plus" ao lado, a
                                    // versão longa quebrava em duas linhas e
                                    // desalinhava com "Entender este resultado".
                                    Text("Qualidade de uso").font(.bodySmallStrong)
                                    Spacer()
                                    // Issue "qualidade de uso Boa/Média/Ruim"
                                    // (2026-08-29): quem tem Plus vê o
                                    // resumo de leitura rápida em vez de só
                                    // um chevron sem contexto; quem não tem,
                                    // o badge deixa claro que é uma ação
                                    // bloqueada (mesmo padrão do card de
                                    // detalhes), não um valor do campo.
                                    if let usageQualityLevel {
                                        Text(usageQualityLevel.label)
                                            .font(.captionStrong)
                                            .foregroundColor(usageQualityLevel.color)
                                    } else if !canUseUsageDiagnostics {
                                        PlusBadge()
                                    }
                                    Image(systemName: "chevron.right").font(.captionStrong)
                                }
                                .foregroundColor(.textPrimary)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 32)
                            .padding(.bottom, !isPlusActive && FeatureFlags.isAdsEnabled ? 16 : 38)

                            if !isPlusActive && FeatureFlags.isAdsEnabled {
                                BannerView()
                                    .padding(.bottom, 22)
                            }

                            // Bottom Action Button — issue "Hero do
                            // resultado": entra no fluxo normal da tela em
                            // vez de ficar colado artificialmente no
                            // rodapé via `Spacer()`. Em telas grandes ele
                            // ainda acaba perto do fim por consequência do
                            // layout; em telas pequenas, a `ScrollView`
                            // simplesmente rola até ele.
                            Button(action: {
                                detailsOpen = false
                                connectionPathExpanded = false
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
            .navigationDestination(isPresented: $showAssist) {
                AssistProblemSelectionView(
                    currentMeasurement: currentMeasurement,
                    recentMeasurements: viewModel.recentMeasurements,
                    usageContext: usageContextForAssist,
                    onRetry: { viewModel.startTest() },
                    onShowDetails: { detailsOpen = true },
                    entitlements: entitlements
                )
            }
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
        .onChange(of: intentCoordinator.pendingAdvancedWiFiDiagnosticsImport) { pending in
            guard pending else { return }
            viewModel.consumePendingAdvancedWiFiDiagnostics()
            intentCoordinator.consumeAdvancedWiFiDiagnosticsImport()
        }
        .onChange(of: intentCoordinator.pendingPurchasePrompt) { pending in
            guard pending else { return }
            // Widget/Siri disparado por usuário Free (decisão do Luiz
            // 2026-08-15: acionar via integração Apple é Plus-only) — abre
            // paywall em vez de rodar medição.
            purchaseEntryPoint = .settings
            showPurchase = true
            intentCoordinator.consumePurchasePrompt()
        }
        // Compartilhar continua disponível como swipe-action no Histórico
        // (feedback do Luiz: tela de resultado carregada demais). A UX de
        // compartilhar por medição individual vive só lá agora.
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
        .sheet(isPresented: $showUsageDiagnostics) {
            NavigationStack {
                UsageDiagnosticsView(measurement: currentMeasurement)
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
        .animation(reduceMotion ? nil : LinkaMotion.spring, value: viewModel.uiPhase)
        .onChange(of: scenePhase) { newPhase in
            // Mesmo padrão de `.onChange` de parâmetro único já usado neste
            // arquivo (issue #65) — mantém compatibilidade com o
            // deployment target atual, sem migrar para a assinatura de dois
            // parâmetros do iOS 17.
            viewModel.handleScenePhaseChange(newPhase)
        }
        .onChange(of: viewModel.uiPhase) { newPhase in
            if newPhase != .error {
                showConnectivityTriage = false
            }
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
                // Issue UI Polish v2 (2026-08-29): removido o som de sistema
                // na transição de fase — um app utilitário de medição não
                // precisa de "PLIM!" no meio de um teste, o haptic acima já
                // é sinal suficiente (e funciona no bolso/mochila, sem som).
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

            // Aviso único de reorganização do Modo Expert — só depois do
            // primeiro resultado (nunca durante a medição), só para quem
            // não tem Plus (quem já é Plus não perdeu nada) e só uma vez
            // por instalação.
            if newPhase == .done, !isPlusActive, !ExpertModeMigrationBannerState.hasBeenSeen() {
                showExpertModeMigrationBanner = true
            }

            // Caminho da Conexão: haptic discreto extra só quando há algo
            // que mereça atenção — sucesso silencioso não precisa de
            // reforço tátil além do haptic leve já disparado acima.
            if newPhase == .done,
               let category = connectionPathReport?.category,
               category != .healthy {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                #endif
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

    /// Bloco de métrica secundária respirando, com mais presença (issue
    /// "Hero do resultado", 2026-08-29) — valor, rótulo e unidade
    /// empilhados, fontes do hero (`heroValueLarge`/`heroText17`/
    /// `heroText15`), não os tokens genéricos de corpo.
    @ViewBuilder
    private func secondaryMetricBlock(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.heroValueLarge)
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.heroText17)
                .foregroundColor(.textSecondary)
            Text(unit)
                .font(.heroText15)
                .foregroundColor(.textSecondary)
        }
    }

    /// Linha "Wi-Fi · SSID · banda" — separada de `providerLine` (issue
    /// "Hero do resultado") para que a UI possa estilizar as duas com
    /// pesos diferentes (título semibold vs. provedor secundário), em vez
    /// de um único texto multi-linha com um só estilo. `nil` quando a
    /// conexão não é Wi-Fi.
    private var wifiContextLine: String? {
        guard viewModel.connectionKind == .wifi else { return nil }
        var line = "Wi-Fi"
        if let ssid = viewModel.wifiContext?.ssid {
            line += " · \(ssid)"
        }
        if let band = viewModel.wifiBandGHz {
            let bandStr = band.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", band)
                : String(format: "%.1f", band)
            line += " · \(bandStr) GHz"
        }
        return line
    }

    private var providerLine: String? {
        viewModel.provider.isEmpty ? nil : viewModel.provider
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
    let connectionKind: NetworkConnectionKind?
    let wifiBandGHz: Double?
    let wifiContext: WiFiNetworkContext?
    let advancedWiFiDiagnostics: AdvancedWiFiDiagnostics?
    let advancedWiFiEnabled: Bool
    let jitter: Double
    let packetLossPercent: Double?
    let loadedLatencyMs: Double?
    /// Latência sob carga durante upload (issue #128) — mesmo tratamento de
    /// `loadedLatencyMs`: `nil` some, sem "--".
    let loadedLatencyUploadMs: Double?
    /// Tempo de resolução DNS (ms) — Expert Mode. `nil` quando o motor não
    /// conseguiu resolver (falha/timeout), não quando a métrica está
    /// travada por entitlement — nesse caso a linha aparece bloqueada.
    let dnsResolutionMs: Double?
    let expertModeEnabled: Bool
    let onIdentifyNetwork: () -> Void
    let onRunAdvancedWiFi: () -> Void
    /// Issue "polimento do card de detalhes" (2026-08-29): as linhas
    /// bloqueadas agora são tocáveis e abrem o paywall, em vez de só
    /// mostrar "Linka Plus" como texto passivo.
    let onUnlockExpertMode: () -> Void
    let onUnlockAdvancedWiFi: () -> Void

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

    /// Issue UI Polish v2 / "polimento do card de detalhes": agrupado em
    /// seções lógicas (CONEXÃO/QUALIDADE/WI-FI/DESEMPENHO SOB CARGA), com
    /// respiro vertical generoso entre elas — o card não deve ler como uma
    /// tabela contínua, mesmo sendo só um card (não removido, só menos
    /// "ficha técnica").
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailSectionHeader("CONEXÃO")
            VStack(spacing: 0) {
                if connectionKind == .wifi {
                    if let ssid = wifiContext?.ssid {
                        InlineResultDetailRow(label: "Rede Wi-Fi", value: ssid)
                        if let security = wifiContext?.securityType {
                            InlineResultDetailRow(label: "Segurança", value: security.displayLabel)
                        }
                    } else {
                        // Rótulo empilhado sobre o valor, não lado a lado
                        // (issue "polimento do card de detalhes") — "Rede
                        // Wi-Fi" + "Não identificada" numa linha só
                        // competia por espaço com "Identificar rede" e
                        // lia estranho. "Identificar rede" ganhou chevron
                        // para parecer ação, não campo perdido no meio.
                        VStack(alignment: .leading, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rede Wi-Fi")
                                    .font(.bodySmall)
                                    .foregroundColor(.textPrimary.opacity(0.7))
                                Text("Não identificada")
                                    .font(.bodySmallStrong)
                                    .foregroundColor(.textPrimary)
                            }
                            Button(action: onIdentifyNetwork) {
                                HStack(spacing: 4) {
                                    Text("Identificar rede")
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmall)
                                }
                            }
                            .font(.bodySmallStrong)
                            .foregroundColor(.brandAccentWarm)
                            .frame(minHeight: 44)
                        }
                        .padding(.vertical, 4)
                        // Bug encontrado testando no simulador: sem isto,
                        // o bloco (dois `Text` soltos, sem `Spacer` que
                        // force largura cheia como `InlineResultDetailRow`
                        // tem) ficava centralizado sob o `VStack(spacing:
                        // 0)` padrão da seção em vez de alinhado à
                        // esquerda com o resto do card.
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                InlineResultDetailRow(label: "Rede", value: networkLabel)
                // Fonte um pouco menor no valor (issue "polimento do card
                // de detalhes") — razão social de provedor pode ser
                // grande e não deve dominar visualmente o card inteiro.
                InlineResultDetailRow(label: "Provedor", value: provider, valueFont: .captionStrong)
                InlineResultDetailRow(label: "Duração", value: duration)
            }

            detailSectionHeader("QUALIDADE")
            VStack(spacing: 0) {
                InlineResultDetailRow(label: "Ping", value: "\(ping) ms")

                // Modo Expert (jitter, perda de pacotes, DNS) — decisão de
                // produto de 2026-08-29: reorganizado atrás do Plus. Free
                // vê uma única linha bloqueada, tocável, em vez de três
                // métricas "sumindo" separadamente.
                if expertModeEnabled {
                    InlineResultDetailRow(label: "Jitter", value: String(format: "%.0f ms", jitter))
                    if let packetLossPercent {
                        InlineResultDetailRow(label: "Perda de pacotes", value: "\(Int(packetLossPercent))%")
                    }
                    if let dnsResolutionMs {
                        InlineResultDetailRow(label: "Resolução DNS", value: String(format: "%.0f ms", dnsResolutionMs))
                    }
                } else {
                    LockedDetailRow(label: "Qualidade avançada", action: onUnlockExpertMode)
                }
            }

            if connectionKind == .wifi {
                detailSectionHeader("WI-FI")
                VStack(spacing: 0) {
                    if let advancedWiFiDiagnostics {
                        advancedWiFiRows(advancedWiFiDiagnostics)
                    } else if advancedWiFiEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            InlineResultDetailRow(label: "Wi-Fi avançado", value: "Não executado")
                            #if os(iOS)
                            Button(action: onRunAdvancedWiFi) {
                                HStack(spacing: 4) {
                                    Text("Obter detalhes Wi-Fi")
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmall)
                                }
                            }
                            .font(.bodySmallStrong)
                            .foregroundColor(.brandAccentWarm)
                            .frame(minHeight: 44)
                            #endif
                        }
                        .padding(.vertical, 4)
                    } else {
                        LockedDetailRow(label: "Wi-Fi avançado", action: onUnlockAdvancedWiFi)
                    }
                }
            }

            if loadedLatencyMs != nil || loadedLatencyUploadMs != nil || responsiveness != nil {
                detailSectionHeader("DESEMPENHO SOB CARGA")
                VStack(spacing: 0) {
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
            }
        }
        // Issue "polimento do card de detalhes" (2026-08-29): padding
        // horizontal um pouco menor, vertical (entre grupos) maior —
        // parece contraditório, mas dá mais respiro sem alargar o card.
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderDefault, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }

    private func detailSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.monoCaption)
            .foregroundColor(.textSecondary)
            .tracking(0.5)
            .padding(.top, 22)
            .padding(.bottom, 6)
    }

    @ViewBuilder
    private func advancedWiFiRows(_ diagnostics: AdvancedWiFiDiagnostics) -> some View {
        if let standard = diagnostics.wifiStandard {
            InlineResultDetailRow(label: "Padrão", value: standard)
        }
        if let rssi = diagnostics.rssiDbm {
            InlineResultDetailRow(label: "Sinal", value: String(format: "%.0f dBm", rssi))
        }
        if let noise = diagnostics.noiseDbm {
            InlineResultDetailRow(label: "Ruído", value: String(format: "%.0f dBm", noise))
        }
        if let snr = diagnostics.snrDb {
            InlineResultDetailRow(label: "SNR", value: String(format: "%.0f dB", snr))
        }
        if let channel = diagnostics.channelNumber {
            InlineResultDetailRow(label: "Canal", value: "\(channel)")
        }
        if diagnostics.txRateMbps != nil || diagnostics.rxRateMbps != nil {
            let tx = diagnostics.txRateMbps.map { String(format: "TX %.0f Mbps", $0) }
            let rx = diagnostics.rxRateMbps.map { String(format: "RX %.0f Mbps", $0) }
            InlineResultDetailRow(label: "Taxa Wi-Fi", value: [tx, rx].compactMap { $0 }.joined(separator: " · "))
        }
    }
}

extension WiFiSecurityType {
    var displayLabel: String {
        switch self {
        case .open: return "Aberta"
        case .wep: return "WEP"
        case .personal: return "Rede pessoal protegida"
        case .enterprise: return "Rede corporativa"
        case .unknown: return "Não informada"
        }
    }
}

private struct InlineResultDetailRow: View {
    let label: String
    let value: String
    /// Fonte do valor — override para linhas cujo valor pode ficar muito
    /// longo (ex.: razão social do provedor), issue "polimento do card de
    /// detalhes" (2026-08-29): um valor gigante dominava o card inteiro.
    var valueFont: Font = .bodySmallStrong

    var body: some View {
        // `.fixedSize(horizontal: false, vertical: true)` em ambos os
        // textos (issue Caminho da Conexão — bug encontrado testando no
        // simulador): sem isso, um valor longo (ex.: nome de provedor)
        // truncava com "…" em vez de quebrar linha — piorou depois da
        // revisão de escala tipográfica (texto maior, menos espaço
        // sobrando). Agora quebra para uma segunda linha em vez de cortar
        // informação real.
        HStack(alignment: .top, spacing: 12) {
            // Issue "polimento do card de detalhes" (2026-08-29): rótulo
            // com mais contraste que `textSecondary` puro — o card estava
            // com sensação de ficha técnica cinza demais.
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textPrimary.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(valueFont)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Badge "Plus" tipográfico (issue "polimento do card de detalhes",
/// 2026-08-29) — usado em linhas bloqueadas para deixar claro que é uma
/// ação disponível na assinatura, não o valor do campo (antes "Linka Plus"
/// aparecia como se fosse a resposta de "Jitter, perda de pacotes, DNS").
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

/// Linha bloqueada tocável (issue "polimento do card de detalhes") — rótulo
/// + badge Plus + chevron, toque abre o paywall. Substitui o padrão antigo
/// de `InlineResultDetailRow(value: "Linka Plus")`, que lia como par
/// chave/valor em vez de ação.
private struct LockedDetailRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.bodySmall)
                    .foregroundColor(.textPrimary.opacity(0.7))
                Spacer(minLength: 8)
                PlusBadge()
                Image(systemName: "chevron.right")
                    .font(.captionSmall)
                    .foregroundColor(.textSecondary)
            }
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label): recurso Plus")
        .accessibilityHint("Toque para conhecer o Linka Plus")
    }
}

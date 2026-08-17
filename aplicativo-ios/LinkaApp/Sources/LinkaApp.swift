import SwiftUI
#if canImport(UIKit)
import GoogleMobileAds
#endif
import LinkaEntitlements
import AppIntents
import LinkaAppIntents
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaWidgetShared
import WidgetKit
import LinkaModules

@main
struct LinkaApp: App {
    @State private var showSplash = true
    @AppStorage("appAppearance") private var appAppearance: String = "system"

    // Fonte única de entitlement do app: StoreKit 2 real, nunca um flag
    // local. Injetado via `.environmentObject` para toda a árvore de views
    // (issue #60 — substitui o antigo `@AppStorage("isPro")`).
    @StateObject private var entitlements = StoreKitEntitlementProvider()

    init() {
        #if canImport(UIKit)
        // Native ads exigem inicialização explícita do SDK antes do primeiro
        // GADAdLoader.load(). Sem isso o carregamento falha silenciosamente.
        // `GoogleMobileAds` é iOS-only (issue #75): sem ads no macOS nativo,
        // não há SDK para inicializar.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
    }

    var colorScheme: ColorScheme? {
        if appAppearance == "light" { return .light }
        if appAppearance == "dark" { return .dark }
        return nil
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    })
                } else {
                    MainView()
                        .transition(.opacity)
                }
            }
            .environmentObject(entitlements)
            .preferredColorScheme(colorScheme)
            .task {
                await entitlements.refreshSnapshot()
            }
            .task {
                await registerAppIntentExecutor()
            }
        }
    }

    /// Conecta `StartSpeedTestIntent` (Siri/Shortcuts/Widget — issue #55)
    /// a uma execução real pela primeira vez. Antes desta issue nenhum
    /// lugar do app registrava um `LinkaAppIntentExecutor` via
    /// `AppDependencyManager`; só existia `LinkaAppIntentExecutor
    /// .unconfigured`, que falha fechado para toda ação
    /// (`LinkaAppIntentExecutionError.notConfigured`) — qualquer intent
    /// disparado por Siri/Shortcuts/Widget travava.
    ///
    /// Só `.startSpeedTest` está fiado de verdade aqui: sinaliza
    /// `AppIntentCoordinator`, que `MainView` traduz em
    /// `SpeedTestViewModel.startTest()` real — nenhuma medição roda dentro
    /// da extensão de widget nem é duplicada aqui.
    ///
    /// **Decisão do Luiz (2026-08-15)**: Widget/Siri/App Intents são
    /// exclusivos do Linka Plus. Usuário Free tocando "Testar" no widget
    /// abre o app e cai direto na tela de assinatura (via
    /// `AppIntentCoordinator.requestPurchasePrompt`), NÃO roda medição —
    /// medir pelo app continua grátis por princípio (AGENTS.md §6), só o
    /// acionamento via integração Apple é gate Plus.
    ///
    /// `openLatestMeasurement`, `openHistory` e `getLatestResult`
    /// continuam fora do escopo desta issue — nenhuma superfície real os
    /// aciona ainda — e seguem falhando fechado com `.notConfigured`, em
    /// vez de travar sem erro tipado como antes.
    private func registerAppIntentExecutor() async {
        let entitlements = self.entitlements
        let executor = LinkaAppIntentExecutor { action in
            switch action {
            case .startSpeedTest:
                let decision = await MainActor.run {
                    LinkaEntitlementPolicy.decision(
                        for: .appleIntegrations,
                        snapshot: entitlements.snapshot,
                        at: Date()
                    )
                }
                if decision.isGranted {
                    await AppIntentCoordinator.shared.requestStartSpeedTest()
                } else {
                    // Free: app abre (openAppWhenRun=true) e cai direto no
                    // paywall. Não roda medição — decisão Plus-only do Luiz.
                    await AppIntentCoordinator.shared.requestPurchasePrompt()
                }
                return LinkaSystemActionResponse(action: .startSpeedTest)
            
            case .measureNetworkSilently:
                let decision = await MainActor.run {
                    LinkaEntitlementPolicy.decision(
                        for: .appleIntegrations,
                        snapshot: entitlements.snapshot,
                        at: Date()
                    )
                }
                guard decision.isGranted else {
                    return LinkaSystemActionResponse(action: .measureNetworkSilently, value: "Assine o Linka Plus para automatizar medições.")
                }

                let engine = SpeedTestCore()
                var finalState: MeasurementState?
                for try await state in await engine.runTest() {
                    if state.phase == .result || state.phase == .error {
                        finalState = state
                    }
                }
                
                guard let state = finalState, state.phase == .result else {
                    return LinkaSystemActionResponse(action: .measureNetworkSilently, value: "Erro ao medir a rede.")
                }
                
                let m = NetworkMeasurement(
                    outcome: .complete,
                    downloadMbps: state.downloadSpeed ?? 0,
                    uploadMbps: state.uploadSpeed ?? 0,
                    latencyMs: state.ping ?? 0,
                    jitterMs: state.jitter ?? 0,
                    packetLossPercent: state.packetLossPercent ?? 0,
                    loadedLatencyMs: state.loadedLatencyMs,
                    durationMs: state.duration.map { Int(($0 * 1000).rounded()) },
                    connectionKind: state.networkType == "Wi-Fi" ? .wifi : (state.networkType == "Rede móvel" ? .cellular : .other),
                    wifiBandGHz: nil,
                    networkIdentifier: state.provider ?? "",
                    location: state.location.map { MeasurementLocation(latitude: $0.latitude, longitude: $0.longitude) }
                )
                let repo = LinkaMeasurementHistory.makeRepository(entitlements: StoreKitEntitlementProvider())
                try? await repo.save(m)
                
                LinkaWidgetShared.writeLatestSummary(
                    LinkaWidgetShared.LatestMeasurementSummary(
                        downloadMbps: state.downloadSpeed ?? 0,
                        uploadMbps: state.uploadSpeed ?? 0,
                        latencyMs: state.ping ?? 0,
                        measuredAt: m.measuredAt
                    )
                )
                WidgetCenter.shared.reloadTimelines(ofKind: LinkaWidgetShared.widgetKind)
                
                let dl = String(format: "%.1f", state.downloadSpeed ?? 0).replacingOccurrences(of: ".", with: ",")
                let ul = String(format: "%.1f", state.uploadSpeed ?? 0).replacingOccurrences(of: ".", with: ",")
                let p = Int(state.ping ?? 0)
                let net = state.networkType ?? "Desconhecido"
                
                let text = "Medição concluída. Download: \(dl) Mega, Upload: \(ul) Mega, Ping: \(p) milissegundos. Rede: \(net)"
                return LinkaSystemActionResponse(action: .measureNetworkSilently, value: text)

            case .openLatestMeasurement, .openHistory, .getLatestResult:
                throw LinkaAppIntentExecutionError.notConfigured
            }
        }
        await AppDependencyManager.shared.add(dependency: executor)
    }
}

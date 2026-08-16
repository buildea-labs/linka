import SwiftUI
import GoogleMobileAds
import LinkaEntitlements
import AppIntents
import LinkaAppIntents

@main
struct LinkaApp: App {
    @State private var showSplash = true
    @AppStorage("appAppearance") private var appAppearance: String = "system"

    // Fonte única de entitlement do app: StoreKit 2 real, nunca um flag
    // local. Injetado via `.environmentObject` para toda a árvore de views
    // (issue #60 — substitui o antigo `@AppStorage("isPro")`).
    @StateObject private var entitlements = StoreKitEntitlementProvider()

    init() {
        // Native ads exigem inicialização explícita do SDK antes do primeiro
        // GADAdLoader.load(). Sem isso o carregamento falha silenciosamente.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
            case .openLatestMeasurement, .openHistory, .getLatestResult:
                throw LinkaAppIntentExecutionError.notConfigured
            }
        }
        await AppDependencyManager.shared.add(dependency: executor)
    }
}

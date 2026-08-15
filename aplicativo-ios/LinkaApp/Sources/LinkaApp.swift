import SwiftUI
import GoogleMobileAds
import LinkaEntitlements

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
        }
    }
}

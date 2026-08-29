import SwiftUI
import AppIntents
#if canImport(UIKit)
import GoogleMobileAds
#endif
import LinkaEntitlements
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaModules
import LinkaAppIntents

@main
struct LinkaApp: App {
    @State private var showSplash = true
    @StateObject private var entitlements: StoreKitEntitlementProvider
    @AppStorage("appAppearance") private var appAppearance = "system"

    init() {
        let entitlementProvider = StoreKitEntitlementProvider()
        _entitlements = StateObject(wrappedValue: entitlementProvider)

        let executor = LinkaAppIntentExecutor { action in
            let snapshot = await MainActor.run { entitlementProvider.snapshot }
            let decision = LinkaEntitlementPolicy.decision(
                for: .appleIntegrations,
                snapshot: snapshot
            )

            guard decision.isGranted else {
                await MainActor.run {
                    AppIntentCoordinator.shared.requestPurchasePrompt()
                }
                return LinkaSystemActionResponse(action: action)
            }

            guard action == .startSpeedTest else {
                throw LinkaAppIntentExecutionError.notConfigured
            }

            await MainActor.run {
                AppIntentCoordinator.shared.requestStartSpeedTest()
            }
            return LinkaSystemActionResponse(action: .startSpeedTest)
        }
        AppDependencyManager.shared.add(dependency: executor)
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
            .preferredColorScheme(preferredColorScheme)
            .onOpenURL { url in
                guard url.scheme?.lowercased() == "linka",
                      url.host == "wifi-advanced",
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value else { return }
                if (try? AdvancedWiFiDiagnosticsInbox.importPayload(payload, entitlement: entitlements.snapshot)) != nil {
                    AppIntentCoordinator.shared.requestAdvancedWiFiDiagnosticsImport()
                }
            }
            .task {
                await entitlements.refreshSnapshot()
                #if DEBUG
                // O build de desenvolvimento começa simulando Plus. O
                // cenário Free fica disponível apenas no menu DEBUG interno.
                entitlements.debugForcePlus()
                #endif
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}

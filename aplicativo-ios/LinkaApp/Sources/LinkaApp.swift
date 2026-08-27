import SwiftUI
#if canImport(UIKit)
import GoogleMobileAds
#endif
import LinkaEntitlements
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaModules

@main
struct LinkaApp: App {
    @State private var showSplash = true
    @StateObject private var entitlements = StoreKitEntitlementProvider()

    init() {
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
}

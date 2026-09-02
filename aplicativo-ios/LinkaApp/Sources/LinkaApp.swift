import SwiftUI
import AppIntents
import LinkaEntitlements
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaModules
import LinkaAppIntents

@main
struct LinkaApp: App {
    @StateObject private var entitlements: StoreKitEntitlementProvider
    @AppStorage("appAppearance") private var appAppearance = "system"

    init() {
        let entitlementProvider = StoreKitEntitlementProvider()
        _entitlements = StateObject(wrappedValue: entitlementProvider)

        let executor = LinkaAppIntentExecutor { action in
            let snapshot = await MainActor.run { entitlementProvider.snapshot }
            
            switch action {
            case .startSpeedTest:
                await MainActor.run {
                    AppIntentCoordinator.shared.requestStartSpeedTest()
                }
                return LinkaSystemActionResponse(action: .startSpeedTest)
                
            case .getLatestResult:
                let repository = LinkaMeasurementHistory.makeRepository(entitlements: entitlementProvider)
                let query = MeasurementQuery(limit: 1, sortOrder: .newestFirst)
                if let latest = try? await repository.measurements(matching: query).first {
                    var parts: [String] = []
                    if let down = latest.downloadMbps {
                        parts.append("\(Int(round(down))) Mbps de download")
                    }
                    if let up = latest.uploadMbps {
                        parts.append("\(Int(round(up))) Mbps de upload")
                    }
                    if let ping = latest.latencyMs {
                        parts.append("ping \(Int(round(ping))) ms")
                    }
                    
                    let resultString = parts.joined(separator: ", ")
                    return LinkaSystemActionResponse(action: .getLatestResult, value: resultString)
                }
                return LinkaSystemActionResponse(action: .getLatestResult, value: "Você ainda não tem uma medição no Linka.")
                
            default:
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
                
                if action == .openHistory {
                    await MainActor.run {
                        AppIntentCoordinator.shared.requestOpenHistory()
                    }
                    return LinkaSystemActionResponse(action: .openHistory)
                } else if action == .openLatestMeasurement {
                    await MainActor.run {
                        AppIntentCoordinator.shared.requestOpenLatestMeasurement()
                    }
                    return LinkaSystemActionResponse(action: .openLatestMeasurement)
                } else {
                    throw LinkaAppIntentExecutionError.notConfigured
                }
            }
        }
        AppDependencyManager.shared.add(dependency: executor)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
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
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        LinkaAppearancePreference(rawValue: appAppearance)?.colorScheme
    }
}

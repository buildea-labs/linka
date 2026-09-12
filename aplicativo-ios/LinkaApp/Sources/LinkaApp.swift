import SwiftUI
import AppIntents
import LinkaEntitlements
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaModules
import LinkaAppIntents
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import LinkaWidgetShared
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct LinkaApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(LinkaPushRegistrationDelegate.self) private var pushRegistrationDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(LinkaPushRegistrationDelegate.self) private var pushRegistrationDelegate
    #endif
    @StateObject private var entitlements: StoreKitEntitlementProvider
    @StateObject private var serviceStatus = ServiceStatusStore()
    @AppStorage("appAppearance") private var appAppearance = "system"
    @AppStorage(LinkaLanguagePreference.storageKey) private var languagePreference = LinkaLanguagePreference.system.rawValue

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

            case .openHistory:
                // Histórico básico é Free; só insights e automações premium
                // continuam protegidos pela capability de integração Apple.
                await MainActor.run {
                    AppIntentCoordinator.shared.requestOpenHistory()
                }
                return LinkaSystemActionResponse(action: .openHistory)

            case .openPurchase:
                await MainActor.run {
                    AppIntentCoordinator.shared.requestPurchasePrompt()
                }
                return LinkaSystemActionResponse(action: .openPurchase)
                
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
                
                if action == .openLatestMeasurement {
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
            rootView
                .environmentObject(entitlements)
                .environmentObject(serviceStatus)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, effectiveLocale)
            .alert("Instabilidade em serviço", isPresented: Binding(
                get: { serviceStatus.popupIncident != nil },
                set: { if !$0 { serviceStatus.popupIncident = nil } }
            ), presenting: serviceStatus.popupIncident) { _ in
                Button("Entendi", role: .cancel) {}
            } message: { incident in
                Text(incident.title)
            }
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
                await serviceStatus.refresh()
                syncWidgetLanguagePreference()
            }
            .onChange(of: languagePreference) { _ in syncWidgetLanguagePreference() }
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        .commands { LinkaMacCommands() }
        #endif
    }

    private var preferredColorScheme: ColorScheme? {
        LinkaAppearancePreference(rawValue: appAppearance)?.colorScheme
    }

    /// Único ponto de bifurcação por plataforma (plano
    /// `plano-direcao-visual-mac-ios.md`): o Mac usa a nova direção visual
    /// em `MacMainView`; o iOS continua com `MainView`, inalterado.
    @ViewBuilder
    private var rootView: some View {
        #if os(macOS)
        MacMainView()
        #else
        MainView()
        #endif
    }

    private var effectiveLocale: Locale {
        LinkaLanguagePreference.fromStoredValue(languagePreference).locale
    }

    private func syncWidgetLanguagePreference() {
        LinkaWidgetShared.writeLanguagePreference(
            LinkaLanguagePreference.fromStoredValue(languagePreference).rawValue
        )
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: LinkaWidgetShared.widgetKind)
        #endif
    }
}

#if os(macOS)
private struct LinkaMacCommands: Commands {
    @ObservedObject private var coordinator = AppIntentCoordinator.shared

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            if coordinator.isMeasurementActive {
                Button("Cancelar medição") { coordinator.requestCancelMeasurement() }
                    .keyboardShortcut(".", modifiers: .command)
            } else {
                Button("Testar velocidade") { coordinator.requestStartSpeedTest() }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
        CommandGroup(after: .appSettings) {
            Button("Ajustes…") { coordinator.requestOpenSettings() }
                .keyboardShortcut(",", modifiers: .command)
                .disabled(coordinator.isMeasurementActive)
        }
    }
}
#endif

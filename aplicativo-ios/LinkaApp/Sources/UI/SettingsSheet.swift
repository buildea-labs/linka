import SwiftUI
import StoreKit
import LinkaEntitlements
import LinkaModules
#if canImport(CoreLocation) && os(iOS)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @Environment(\.openURL) private var openURL
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showPurchase = false
    @State private var showSubscriptionManagement = false
    @State private var showWiFiExplanation = false
    @State private var showAdvancedActions = false
    @AppStorage("appAppearance") private var appAppearance = "system"
    @AppStorage(LinkaWiFiPreferences.identificationEnabledKey) private var networkIdentificationEnabled = true
    @AppStorage(LinkaWiFiPreferences.advancedConfiguredKey) private var advancedWiFiConfigured = false
    @AppStorage(LinkaWiFiPreferences.advancedDiagnosticsEnabledKey) private var advancedWiFiEnabled = true

    var body: some View {
        Form {
            Section("Linka Plus") {
                Button(action: openSubscription) {
                    settingsRow(title: "Linka Plus", value: subscriptionStatusText, systemImage: "sparkles")
                }
            }

            #if os(iOS)
            Section("Rede e diagnóstico") {
                Button(action: openNetworkIdentification) {
                    settingsRow(title: "Identificação da rede Wi-Fi", value: WiFiNetworkPermission.statusText(enabled: networkIdentificationEnabled), systemImage: "wifi")
                }
                Button(action: openAdvancedWiFi) {
                    settingsRow(title: "Diagnóstico Wi-Fi avançado", value: advancedWiFiStatusText, systemImage: "waveform.path.ecg")
                }
            }
            #endif

            Section("Preferências") {
                Picker("Aparência", selection: $appAppearance) {
                    Text("Sistema").tag("system")
                    Text("Claro").tag("light")
                    Text("Escuro").tag("dark")
                }
            }

            Section("Sobre o Linka") {
                Link(destination: LinkaExternalLinks.about) {
                    Label("Sobre o Linka", systemImage: "info.circle")
                }
                Link(destination: LinkaExternalLinks.howWeMeasure) {
                    Label("Como medimos", systemImage: "speedometer")
                }
                Link(destination: LinkaExternalLinks.privacy) {
                    Label("Privacidade", systemImage: "hand.raised")
                }
                Link(destination: LinkaExternalLinks.terms) {
                    Label("Termos de Uso", systemImage: "doc.text")
                }
                Link(destination: LinkaExternalLinks.support) {
                    Label("Suporte", systemImage: "questionmark.circle")
                }
            }

            #if DEBUG
            Section {
                Button("Simular Linka Free (DEBUG)") { entitlements.debugResetToFree() }
                Button("Simular Linka Plus (DEBUG)") { entitlements.debugForcePlus() }
            } header: {
                Text("Debug interno").foregroundColor(.brandAccentWarm)
            }
            #endif

            Section {
                Text("Versão \(appVersion)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showPurchase) { PurchaseSheet(entryPoint: purchaseEntryPoint) }
        .sheet(isPresented: $showSubscriptionManagement) { SubscriptionManagementSheet() }
        .task {
            await entitlements.refreshSnapshot()
            await entitlements.loadProduct()
        }
        .confirmationDialog("Identificação da rede Wi-Fi", isPresented: $showWiFiExplanation, titleVisibility: .visible) {
            switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
            case .permissionDenied:
                Button("Abrir Ajustes do iPhone") {
                    networkIdentificationEnabled = true
                    WiFiNetworkPermission.openSystemSettings()
                }
            case .active:
                Button("Desativar identificação", role: .destructive) {
                    networkIdentificationEnabled = false
                }
            case .disabledByUser, .permissionRequired:
                Button("Ativar identificação") {
                    networkIdentificationEnabled = true
                    WiFiNetworkPermission.requestIdentification()
                }
            case .unavailable:
                EmptyView()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(networkIdentificationMessage)
        }
        .confirmationDialog("Diagnóstico Wi-Fi avançado", isPresented: $showAdvancedActions, titleVisibility: .visible) {
            switch advancedWiFiState {
            case .requiresPlus:
                Button("Conhecer Linka Plus") {
                    purchaseEntryPoint = .advancedWiFi
                    showPurchase = true
                }
            case .needsConfiguration:
                Button("Configurar no Atalhos") { openShortcuts() }
            case .active:
                Button("Executar diagnóstico Wi-Fi") { runAdvancedWiFiShortcut() }
                Button("Atualizar atalho") { openShortcuts() }
                Button("Desativar integração", role: .destructive) { advancedWiFiEnabled = false }
            case .disabled:
                Button("Ativar integração") { advancedWiFiEnabled = true }
                Button("Atualizar atalho") { openShortcuts() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(advancedWiFiMessage)
        }
    }

    private func settingsRow(title: String, value: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.textSecondary.opacity(0.6))
        }
    }

    private var appVersion: String {
        LinkaAppVersion.displayString()
    }

    private var subscriptionStatusText: String {
        if entitlements.isRefreshingSnapshot { return "Verificando" }
        switch entitlements.snapshot.plan {
        case .free:
            return "Conhecer o Linka Plus"
        case .plus:
            return entitlements.snapshot.status == .active ? "Ativo" : "Assinatura inativa"
        }
    }

    private var advancedWiFiState: LinkaAdvancedWiFiSettingsState {
        let decision = LinkaEntitlementPolicy.decision(for: .advancedWiFiDiagnostics, snapshot: entitlements.snapshot)
        return .state(
            hasEntitlement: decision.isGranted,
            configured: advancedWiFiConfigured,
            enabled: advancedWiFiEnabled
        )
    }

    private var advancedWiFiStatusText: String {
        advancedWiFiState.statusText
    }

    private var networkIdentificationMessage: String {
        switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
        case .active:
            return "O Linka pode mostrar o nome da rede usada nas medições. Você pode desativar isso aqui."
        case .disabledByUser, .permissionRequired:
            return "O Linka usa essa permissão apenas para mostrar o nome da rede Wi-Fi nas medições e no histórico."
        case .permissionDenied:
            return "A permissão foi negada no iPhone. Para identificar a rede, abra Ajustes e permita localização para o Linka."
        case .unavailable:
            return "A identificação da rede Wi-Fi não está disponível nesta plataforma."
        }
    }

    private var advancedWiFiMessage: String {
        switch advancedWiFiState {
        case .requiresPlus:
            return "O diagnóstico Wi-Fi avançado faz parte do Linka Plus."
        case .needsConfiguration:
            return "Configure o atalho oficial para importar dados extras quando você executar uma medição."
        case .active:
            return "O Atalhos fornece dados extras quando você executa a integração."
        case .disabled:
            return "A integração está configurada, mas não roda antes das medições."
        }
    }

    private func openSubscription() {
        guard entitlements.snapshot.plan == .plus, entitlements.snapshot.status == .active else {
            purchaseEntryPoint = .settings; showPurchase = true; return
        }
        showSubscriptionManagement = true
    }

    private func openNetworkIdentification() {
        switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
        case .active, .disabledByUser, .permissionRequired, .permissionDenied:
            showWiFiExplanation = true
        case .unavailable:
            break
        }
    }

    private func openAdvancedWiFi() {
        let decision = LinkaEntitlementPolicy.decision(for: .advancedWiFiDiagnostics, snapshot: entitlements.snapshot)
        guard decision.isGranted else {
            purchaseEntryPoint = .advancedWiFi; showPurchase = true; return
        }
        if advancedWiFiConfigured && advancedWiFiEnabled {
            showAdvancedActions = true
        } else if advancedWiFiConfigured {
            showAdvancedActions = true
        } else {
            advancedWiFiEnabled = true
            openShortcuts()
        }
    }

    private func openShortcuts() {
        openURL(LinkaAdvancedWiFiIntegration.shortcutsAppURL)
    }

    private func runAdvancedWiFiShortcut() {
        openURL(LinkaAdvancedWiFiIntegration.runShortcutURL)
    }
}

typealias SettingsSheet = SettingsView

struct SubscriptionManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var isRestoring = false
    @State private var message: String?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    #if canImport(UIKit)
                    Button("Gerenciar assinatura", action: manageSubscription)
                    #else
                    Link("Gerenciar assinatura", destination: LinkaExternalLinks.subscriptionManagement)
                    #endif
                    Button(isRestoring ? "Restaurando…" : "Restaurar compra", action: restore)
                        .disabled(isRestoring)
                } footer: {
                    Text("A renovação e o cancelamento são gerenciados pela Apple.")
                }
                if let message { Section { Text(message).foregroundColor(.textSecondary) } }
            }
            .linkaSheetToolbar(title: "Linka Plus") { dismiss() }
        }
    }

    #if canImport(UIKit)
    private func manageSubscription() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        Task { try? await AppStore.showManageSubscriptions(in: scene) }
    }
    #endif

    private func restore() {
        isRestoring = true; message = nil
        Task {
            do {
                let restored = try await entitlements.restore()
                isRestoring = false
                message = restored ? "Compra restaurada." : "Nenhuma compra ativa foi encontrada."
            } catch {
                isRestoring = false; message = "Não foi possível restaurar a compra agora."
            }
        }
    }
}

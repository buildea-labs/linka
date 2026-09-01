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
    @AppStorage("linka.advanced-wifi.configured.v1") private var advancedWiFiConfigured = false
    @AppStorage(LinkaWiFiPreferences.advancedDiagnosticsEnabledKey) private var advancedWiFiEnabled = true

    var body: some View {
        Form {
            Section("Linka Plus") {
                Button(action: openSubscription) {
                    settingsRow(title: "Linka Plus", value: subscriptionStatusText)
                }
            }

            #if os(iOS)
            Section("Rede e diagnóstico") {
                Button(action: openNetworkIdentification) {
                    settingsRow(title: "Identificação da rede Wi-Fi", value: WiFiNetworkPermission.statusText(enabled: networkIdentificationEnabled))
                }
                Button(action: openAdvancedWiFi) {
                    settingsRow(title: "Diagnóstico Wi-Fi avançado", value: advancedWiFiStatusText)
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
                Link(destination: LinkaExternalLinks.website) {
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
                if let support = LinkaExternalLinks.support {
                    Link(destination: support) {
                        Label("Suporte", systemImage: "questionmark.circle")
                    }
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
        .confirmationDialog("Identificação da rede Wi-Fi", isPresented: $showWiFiExplanation, titleVisibility: .visible) {
            Button("Ativar identificação") {
                networkIdentificationEnabled = true
                WiFiNetworkPermission.requestIdentification()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Mostra o nome da rede usada nas medições e ajuda a identificar padrões no histórico.")
        }
        .confirmationDialog("Diagnóstico Wi-Fi avançado", isPresented: $showAdvancedActions, titleVisibility: .visible) {
            Button("Executar diagnóstico Wi-Fi") { openShortcuts() }
            Button("Atualizar atalho") { openShortcuts() }
            Button("Desativar integração", role: .destructive) { advancedWiFiEnabled = false }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O Atalhos fornece dados extras quando você executa a integração.")
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(value).foregroundColor(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.textSecondary.opacity(0.6))
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (build \(build))"
    }

    private var subscriptionStatusText: String {
        switch entitlements.snapshot.plan {
        case .free: "Conhecer o Linka Plus"
        case .plus: entitlements.snapshot.status == .active ? "Ativo" : "Assinatura inativa"
        }
    }

    private var advancedWiFiStatusText: String {
        let decision = LinkaEntitlementPolicy.decision(for: .advancedWiFiDiagnostics, snapshot: entitlements.snapshot)
        guard decision.isGranted else { return "Linka Plus" }
        return advancedWiFiConfigured && advancedWiFiEnabled ? "Ativo" : "Configurar"
    }

    private func openSubscription() {
        guard entitlements.snapshot.plan == .plus, entitlements.snapshot.status == .active else {
            purchaseEntryPoint = .settings; showPurchase = true; return
        }
        showSubscriptionManagement = true
    }

    private func openNetworkIdentification() {
        if !networkIdentificationEnabled {
            showWiFiExplanation = true
        } else if WiFiNetworkPermission.canOpenSystemSettings {
            WiFiNetworkPermission.openSystemSettings()
        } else if WiFiNetworkPermission.isAuthorized {
            networkIdentificationEnabled = false
        } else {
            WiFiNetworkPermission.requestIdentification()
        }
    }

    private func openAdvancedWiFi() {
        let decision = LinkaEntitlementPolicy.decision(for: .advancedWiFiDiagnostics, snapshot: entitlements.snapshot)
        guard decision.isGranted else {
            purchaseEntryPoint = .advancedWiFi; showPurchase = true; return
        }
        if advancedWiFiConfigured && advancedWiFiEnabled {
            showAdvancedActions = true
        } else {
            advancedWiFiEnabled = true
            openShortcuts()
        }
    }

    private func openShortcuts() {
        guard let url = URL(string: "shortcuts://") else { return }
        openURL(url)
    }
}

typealias SettingsSheet = SettingsView

struct SubscriptionManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var isRestoring = false
    @State private var message: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack { Button("Fechar") { dismiss() }; Spacer(); Text("Linka Plus").font(.headline); Spacer(); Color.clear.frame(width: 52, height: 1) }
                .padding(.horizontal, 20).padding(.vertical, 12)
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

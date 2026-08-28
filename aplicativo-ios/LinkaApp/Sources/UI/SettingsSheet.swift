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

struct SettingsSheet: View {
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @Environment(\.openURL) private var openURL
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showPurchase = false
    @State private var showSubscriptionManagement = false
    @State private var showWiFiExplanation = false
    @State private var showAdvancedActions = false
    @State private var testCount = 0
    @AppStorage("appAppearance") private var appAppearance = "system"
    @AppStorage(LinkaWiFiPreferences.identificationEnabledKey) private var networkIdentificationEnabled = true
    @AppStorage("linka.advanced-wifi.configured.v1") private var advancedWiFiConfigured = false
    @AppStorage(LinkaWiFiPreferences.advancedDiagnosticsEnabledKey) private var advancedWiFiEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SettingsSection(header: "LINKA PLUS") {
                    Button(action: openSubscription) {
                        SettingsRowContent(title: "Linka Plus", subtitle: subscriptionStatusText, showChevron: true)
                    }
                }

                #if os(iOS)
                SettingsSection(header: "REDE E DIAGNÓSTICO") {
                    Button(action: openNetworkIdentification) {
                        SettingsRowContent(title: "Identificação da rede Wi-Fi", subtitle: WiFiNetworkPermission.statusText(enabled: networkIdentificationEnabled), showChevron: true)
                    }
                    Divider().padding(.leading, 16)
                    Button(action: openAdvancedWiFi) {
                        SettingsRowContent(title: "Diagnóstico Wi-Fi avançado", subtitle: advancedWiFiStatusText, showChevron: true)
                    }
                }
                #endif

                SettingsSection(header: "PREFERÊNCIAS") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Aparência").font(.bodyRegular).foregroundColor(.textPrimary)
                        Picker("Aparência", selection: $appAppearance) {
                            Text("Sistema").tag("system")
                            Text("Claro").tag("light")
                            Text("Escuro").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                }

                SettingsSection(header: "ATIVIDADE") {
                    NavigationLink(destination: HistoryView()) {
                        SettingsRowContent(title: "Histórico", subtitle: "\(testCount) testes", showChevron: true)
                    }
                }

                SettingsSection(header: "SOBRE O LINKA") {
                    SettingsRow(icon: "info.circle", title: "Sobre o Linka", url: LinkaExternalLinks.website)
                    Divider().padding(.leading, 56)
                    SettingsRow(icon: "speedometer", title: "Como medimos", url: LinkaExternalLinks.howWeMeasure)
                    Divider().padding(.leading, 56)
                    SettingsRow(icon: "hand.raised", title: "Privacidade", url: LinkaExternalLinks.privacy)
                    Divider().padding(.leading, 56)
                    SettingsRow(icon: "doc.text", title: "Termos de Uso", url: LinkaExternalLinks.terms)
                    if let support = LinkaExternalLinks.support {
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "questionmark.circle", title: "Suporte", url: support)
                    }
                }

                #if DEBUG
                SettingsSection(header: "DEBUG INTERNO", headerColor: .brandAccentWarm) {
                    Button("Simular Linka Free (DEBUG)") { entitlements.debugResetToFree() }
                        .foregroundColor(.textPrimary).frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    Divider().padding(.leading, 16)
                    Button("Simular Linka Plus (DEBUG)") { entitlements.debugForcePlus() }
                        .foregroundColor(.textPrimary).frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }
                #endif

                Text("Versão \(appVersion)")
                    .font(.captionMedium).foregroundColor(.textSecondary)
                    .padding(.top, 4).padding(.bottom, 32)
            }
            .padding(.top, 24)
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Ajustes")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surfacePage, for: .navigationBar)
        #endif
        .onAppear(perform: loadTestCount)
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

    private func loadTestCount() {
        Task { @MainActor in
            let repository = LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
            testCount = (try? await repository.totalCount()) ?? 0
        }
    }
}

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
            .navigationTitle("Linka Plus")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
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

enum WiFiNetworkPermission {
    #if canImport(CoreLocation) && os(iOS)
    private static let manager = CLLocationManager()
    static func statusText(enabled: Bool) -> String {
        guard enabled else { return "Desativada" }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return manager.accuracyAuthorization == .fullAccuracy ? "Ativada" : "Permissão necessária"
        case .denied, .restricted: return "Permissão necessária"
        case .notDetermined: return "Permissão necessária"
        @unknown default: return "Permissão necessária"
        }
    }
    static var canOpenSystemSettings: Bool { manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted }
    static var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }
    @MainActor static func requestIdentification() {
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        else { openSystemSettings() }
    }
    @MainActor static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    #else
    static func statusText(enabled: Bool) -> String { "Não disponível" }
    static var canOpenSystemSettings: Bool { false }
    static var isAuthorized: Bool { false }
    static func requestIdentification() {}
    static func openSystemSettings() {}
    #endif
}

struct SettingsSection<Content: View>: View {
    var header: String
    var headerColor: Color = .textSecondary
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header).font(.monoCaption).foregroundColor(headerColor).padding(.horizontal, 24)
            VStack(spacing: 0) { content }
                .background(Color.surfaceCard).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 24)
        }
    }
}

struct SettingsRowContent: View {
    var title: String
    var subtitle: String?
    var showChevron: Bool
    var body: some View {
        HStack {
            Text(title).foregroundColor(.textPrimary); Spacer()
            if let subtitle { Text(subtitle).foregroundColor(.textSecondary).multilineTextAlignment(.trailing) }
            if showChevron { Image(systemName: "chevron.right").font(.bodySmallStrong).foregroundColor(.textSecondary) }
        }
        .padding(.vertical, 16).padding(.horizontal, 16).contentShape(Rectangle())
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    var url: URL
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 30).foregroundColor(.textSecondary)
                Text(title).foregroundColor(.textPrimary); Spacer()
                Image(systemName: "chevron.right").font(.bodySmallStrong).foregroundColor(.textSecondary)
            }
            .padding(.vertical, 14).padding(.horizontal, 16).contentShape(Rectangle())
        }
    }
}

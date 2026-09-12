import SwiftUI
import StoreKit
import AppIntents
import LinkaEntitlements
import LinkaModules
import NetworkDiagnostics
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .settings
    @State private var showPurchase = false
    @State private var showSubscriptionManagement = false
    @State private var showWiFiExplanation = false
    @State private var showAdvancedActions = false
    @AppStorage("appAppearance") private var appAppearance = "system"
    @AppStorage(LinkaLanguagePreference.storageKey) private var languagePreference = LinkaLanguagePreference.system.rawValue
    @AppStorage(LinkaWiFiPreferences.identificationEnabledKey) private var networkIdentificationEnabled = true
    @AppStorage(LinkaWiFiPreferences.advancedConfiguredKey) private var advancedWiFiConfigured = false
    @AppStorage(LinkaWiFiPreferences.advancedDiagnosticsEnabledKey) private var advancedWiFiEnabled = true
    private let onPurchaseRequest: ((PurchaseEntryPoint) -> Void)?
    private let onSubscriptionManagementRequest: (() -> Void)?

    init(
        onPurchaseRequest: ((PurchaseEntryPoint) -> Void)? = nil,
        onSubscriptionManagementRequest: (() -> Void)? = nil
    ) {
        self.onPurchaseRequest = onPurchaseRequest
        self.onSubscriptionManagementRequest = onSubscriptionManagementRequest
    }

    var body: some View {
        Group {
        #if os(macOS)
        macOSContent
        #else
        Form {
            Section {
                Button(action: openSubscription) {
                    HStack {
                        LinkaPlusWordmarkView(height: 20)
                        Spacer()
                        Text(subscriptionStatusText)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary.opacity(0.6))
                    }
                }
            }

            #if os(iOS)
            Section(LinkaCopy.value("settings.section.network")) {
                Button(action: openNetworkIdentification) {
                    settingsRow(title: LinkaCopy.value("settings.wifiIdentification.title"), value: networkIdentificationStatusText, systemImage: "wifi")
                }
                Button(action: openAdvancedWiFi) {
                    settingsRow(title: LinkaCopy.value("settings.advancedWiFi.title"), value: advancedWiFiStatusText, systemImage: "waveform.path.ecg")
                }
            }

            Section(LinkaCopy.value("settings.section.tools")) {
                NavigationLink(destination: RouterDiscoveryView()) {
                    Label(LinkaCopy.value("settings.routerAccess"), systemImage: "router")
                }
            }
            #endif

            Section(LinkaCopy.value("settings.section.preferences")) {
                Picker(LinkaCopy.value("settings.appearance.title"), selection: $appAppearance) {
                    Text(LinkaCopy.value("settings.appearance.system")).tag("system")
                    Text(LinkaCopy.value("settings.appearance.light")).tag("light")
                    Text(LinkaCopy.value("settings.appearance.dark")).tag("dark")
                }

                Picker(LinkaCopy.value("settings.language.title"), selection: $languagePreference) {
                    ForEach(LinkaLanguagePreference.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .accessibilityHint(LinkaCopy.value("settings.language.hint"))
            }

            Section(LinkaCopy.value("settings.section.serviceStatus")) {
                NavigationLink(destination: ServiceStatusView()) {
                    Label(LinkaCopy.value("settings.serviceStatus"), systemImage: "dot.radiowaves.left.and.right")
                }
            }

            Section(LinkaCopy.value("settings.section.about")) {
                Link(destination: LinkaExternalLinks.about) {
                    Label(LinkaCopy.value("settings.about"), systemImage: "info.circle")
                }
                Link(destination: LinkaExternalLinks.howWeMeasure) {
                    Label(LinkaCopy.value("settings.howWeMeasure"), systemImage: "speedometer")
                }
                Link(destination: LinkaExternalLinks.privacy) {
                    Label(LinkaCopy.value("settings.privacy"), systemImage: "hand.raised")
                }
                Link(destination: LinkaExternalLinks.terms) {
                    Label(LinkaCopy.value("settings.terms"), systemImage: "doc.text")
                }
                Link(destination: LinkaExternalLinks.support) {
                    Label(LinkaCopy.value("settings.support"), systemImage: "questionmark.circle")
                }
                Button {
                    requestReview()
                } label: {
                    Label(LinkaCopy.value("settings.rate"), systemImage: "star")
                }
                Link(destination: LinkaExternalLinks.support) {
                    Label(LinkaCopy.value("settings.feedback"), systemImage: "text.bubble")
                }
            }

            #if DEBUG
            Section {
                Toggle(isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: StoreKitEntitlementProvider.forcePlusKey) },
                    set: { entitlements.setForcePlus($0) }
                )) {
                    Label(LinkaCopy.value("settings.debug.plus"), systemImage: "flask")
                }
                .tint(.brandAccentWarm)
            } header: {
                Text(LinkaCopy.value("settings.debug.title")).foregroundColor(.brandAccentWarm)
            } footer: {
                Text(LinkaCopy.value("settings.debug.footer"))
            }
            #endif

            Section {
                Text(LinkaCopy.format("settings.version", appVersion))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        #endif
        }
        .navigationTitle(LinkaCopy.value("settings.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { dismiss() }
            }
        }
        #endif
        .sheet(isPresented: $showPurchase) { 
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                if purchaseEntryPoint == .advancedWiFi {
                    openAdvancedWiFi()
                } else if purchaseEntryPoint == .settings {
                    showSubscriptionManagement = true
                }
            }
        }
        .sheet(isPresented: $showSubscriptionManagement) { SubscriptionManagementSheet() }
        .task {
            await entitlements.refreshSnapshot()
            await entitlements.loadProduct()
        }
        .confirmationDialog(LinkaCopy.value("settings.wifiIdentification.title"), isPresented: $showWiFiExplanation, titleVisibility: .visible) {
            switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
            case .permissionDenied:
                Button(LinkaCopy.value("settings.wifiIdentification.openSystemSettings")) {
                    networkIdentificationEnabled = true
                    WiFiNetworkPermission.openSystemSettings()
                }
            case .active:
                Button(LinkaCopy.value("settings.wifiIdentification.disable"), role: .destructive) {
                    networkIdentificationEnabled = false
                }
            case .disabledByUser, .permissionRequired:
                Button(LinkaCopy.value("settings.wifiIdentification.enable")) {
                    networkIdentificationEnabled = true
                    WiFiNetworkPermission.requestIdentification()
                }
            case .unavailable:
                EmptyView()
            }
            Button(LinkaCopy.value("common.cancel"), role: .cancel) {}
        } message: {
            Text(networkIdentificationMessage)
        }
        .confirmationDialog(LinkaCopy.value("settings.advancedWiFi.title"), isPresented: $showAdvancedActions, titleVisibility: .visible) {
            switch advancedWiFiState {
            case .requiresPlus:
                Button(LinkaCopy.value("settings.advancedWiFi.learnPlus")) {
                    purchaseEntryPoint = .advancedWiFi
                    showPurchase = true
                }
            case .needsConfiguration:
                Button(LinkaCopy.value("settings.advancedWiFi.addShortcut")) {
                    importAdvancedWiFiShortcut()
                    advancedWiFiEnabled = true
                }
            case .active:
                Button(LinkaCopy.value("settings.advancedWiFi.run")) { runAdvancedWiFiShortcut() }
                Button(LinkaCopy.value("settings.advancedWiFi.updateShortcut")) {
                    importAdvancedWiFiShortcut()
                }
                Button(LinkaCopy.value("settings.advancedWiFi.disable"), role: .destructive) { advancedWiFiEnabled = false }
            case .disabled:
                Button(LinkaCopy.value("settings.advancedWiFi.enable")) { advancedWiFiEnabled = true }
                Button(LinkaCopy.value("settings.advancedWiFi.updateShortcut")) {
                    importAdvancedWiFiShortcut()
                }
            }
            Button(LinkaCopy.value("common.cancel"), role: .cancel) {}
        } message: {
            Text(advancedWiFiMessage)
        }
    }

    #if os(macOS)
    private var macOSContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                macSection {
                    Button(action: openSubscription) {
                        HStack(spacing: 12) {
                            LinkaPlusWordmarkView(height: 20)
                            Spacer()
                            Text(subscriptionStatusText)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.trailing)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Linka Plus, \(subscriptionStatusText)")
                }

                macSection(title: "Preferências") {
                    HStack {
                        Label("Aparência", systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Picker("Aparência", selection: $appAppearance) {
                            Text("Sistema").tag("system")
                            Text("Claro").tag("light")
                            Text("Escuro").tag("dark")
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                }

                macSection(title: "Status de serviços") {
                    NavigationLink(destination: ServiceStatusView()) {
                        macRow("Acompanhar serviços", systemImage: "dot.radiowaves.left.and.right", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                }

                macSection(title: "Rede e diagnóstico") {
                    Toggle(isOn: Binding(
                        get: { advancedWiFiEnabled },
                        set: { enabled in
                            guard macAdvancedWiFiAllowed else {
                                purchaseEntryPoint = .advancedWiFi
                                showPurchase = true
                                return
                            }
                            advancedWiFiEnabled = enabled
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Wi-Fi avançado")
                                .foregroundColor(.textPrimary)
                            Text(macAdvancedWiFiAllowed ? "Coleta detalhes nativos somente quando você iniciar uma medição com detalhes." : "Disponível no Linka Plus.")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .tint(.brandAccentWarm)
                }

                macSection(title: "Ferramentas") {
                    NavigationLink(destination: MacRouterPanelView()) {
                        macRow("Painel do roteador", systemImage: "router", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                }

                macSection(title: "Ajuda") {
                    macLinkRow("Como medimos", systemImage: "speedometer", destination: LinkaExternalLinks.howWeMeasure)
                    Divider()
                    macLinkRow("Suporte", systemImage: "questionmark.circle", destination: LinkaExternalLinks.support)
                    Divider()
                    macLinkRow("Enviar feedback", systemImage: "text.bubble", destination: LinkaExternalLinks.support)
                    Divider()
                    Button { requestReview() } label: {
                        macRow("Avaliar o Linka", systemImage: "star", showsChevron: false)
                    }
                    .buttonStyle(.plain)
                }

                macSection(title: "Sobre e legal") {
                    macLinkRow("Privacidade", systemImage: "hand.raised", destination: LinkaExternalLinks.privacy)
                    Divider()
                    macLinkRow("Termos de Uso", systemImage: "doc.text", destination: LinkaExternalLinks.terms)
                    Divider()
                    macLinkRow("Sobre o Linka", systemImage: "info.circle", destination: LinkaExternalLinks.about)
                    Divider()
                    Text("Versão \(appVersion)")
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: 500, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color.surfacePage)
    }

    private func macSection<Content: View>(title: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.monoCaption)
                    .textCase(.uppercase)
                    .foregroundColor(.textSecondary)
            }
            VStack(alignment: .leading, spacing: 12, content: content)
                .padding(18)
                .linkaCard()
        }
    }

    private func macLinkRow(_ title: String, systemImage: String, destination: URL) -> some View {
        Link(destination: destination) {
            macRow(title, systemImage: systemImage, showsChevron: true)
        }
        .buttonStyle(.plain)
    }

    private func macRow(_ title: String, systemImage: String, showsChevron: Bool) -> some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.textPrimary)
            Spacer()
            if showsChevron {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private var macAdvancedWiFiAllowed: Bool {
        LinkaEntitlementPolicy.decision(
            for: .advancedWiFiDiagnostics,
            snapshot: entitlements.snapshot
        ).isGranted
    }
    #endif

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
        if entitlements.isRefreshingSnapshot { return LinkaCopy.value("settings.subscription.checking") }
        switch entitlements.snapshot.plan {
        case .free:
            return LinkaCopy.value("settings.subscription.learnPlus")
        case .plus:
            return entitlements.snapshot.status == .active ? LinkaCopy.value("settings.subscription.active") : LinkaCopy.value("settings.subscription.inactive")
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
        switch advancedWiFiState {
        case .requiresPlus: return LinkaCopy.value("settings.advancedWiFi.status.requiresPlus")
        case .needsConfiguration: return LinkaCopy.value("settings.advancedWiFi.status.needsConfiguration")
        case .active: return LinkaCopy.value("settings.advancedWiFi.status.active")
        case .disabled: return LinkaCopy.value("settings.advancedWiFi.status.disabled")
        }
    }

    private var networkIdentificationStatusText: String {
        switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
        case .active: return LinkaCopy.value("wifi.identification.active")
        case .disabledByUser: return LinkaCopy.value("wifi.identification.disabled")
        case .permissionRequired: return LinkaCopy.value("wifi.identification.permissionRequired")
        case .permissionDenied: return LinkaCopy.value("wifi.identification.permissionDenied")
        case .unavailable: return LinkaCopy.value("common.unavailable")
        }
    }

    private var networkIdentificationMessage: String {
        switch WiFiNetworkPermission.state(enabled: networkIdentificationEnabled) {
        case .active:
            return LinkaCopy.value("settings.wifiIdentification.message.active")
        case .disabledByUser, .permissionRequired:
            return LinkaCopy.value("settings.wifiIdentification.message.permissionRequired")
        case .permissionDenied:
            return LinkaCopy.value("settings.wifiIdentification.message.permissionDenied")
        case .unavailable:
            return LinkaCopy.value("settings.wifiIdentification.message.unavailable")
        }
    }

    private var advancedWiFiMessage: String {
        switch advancedWiFiState {
        case .requiresPlus:
            return LinkaCopy.value("settings.advancedWiFi.message.requiresPlus")
        case .needsConfiguration:
            return LinkaCopy.value("settings.advancedWiFi.message.needsConfiguration")
        case .active:
            return LinkaCopy.value("settings.advancedWiFi.message.active")
        case .disabled:
            return LinkaCopy.value("settings.advancedWiFi.message.disabled")
        }
    }

    private func openSubscription() {
        if entitlements.snapshot.plan == .plus, entitlements.snapshot.status == .active {
            if let onSubscriptionManagementRequest {
                onSubscriptionManagementRequest()
            } else {
                showSubscriptionManagement = true
            }
        } else if let onPurchaseRequest {
            onPurchaseRequest(.settings)
        } else {
            purchaseEntryPoint = .settings
            showPurchase = true
        }
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
            showAdvancedActions = true
        }
    }

    private func runAdvancedWiFiShortcut() {
        openURL(LinkaAdvancedWiFiIntegration.runShortcutURL)
    }

    private func importAdvancedWiFiShortcut() {
        #if canImport(UIKit)
        // O botão vive em um confirmationDialog. Espera o fechamento da
        // folha antes de pedir a troca para o app Atalhos.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UIApplication.shared.open(LinkaAdvancedWiFiIntegration.importShortcutURL)
        }
        #else
        openURL(LinkaAdvancedWiFiIntegration.importShortcutURL)
        #endif
    }
}

typealias SettingsSheet = SettingsView

#if os(macOS)
private enum MacRouterPanelState: Equatable {
    case idle
    case locating
    case found(GatewayInfo)
    case unavailable
}

/// Localiza somente o gateway da rota ativa. A descoberta canônica vive em
/// `NetworkDiagnostics`: não faz inventário Bonjour, não deduz fabricante e
/// não guarda credenciais.
private struct MacRouterPanelView: View {
    @Environment(\.openURL) private var openURL
    @State private var state: MacRouterPanelState = .idle
    @State private var showOpenConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Painel do roteador")
                .font(.title2.weight(.semibold))

            Group {
                switch state {
                case .idle, .locating:
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Procurando o roteador nesta rede…")
                    }
                    .foregroundColor(.textSecondary)
                case .found(let gateway):
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Painel encontrado", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(gateway.ip)
                            .font(.bodySmallStrong)
                            .foregroundColor(.textPrimary)
                        if gateway.adminURL?.scheme?.lowercased() == "http" {
                            Text("Esta página não usa conexão segura.")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        Button("Abrir painel no navegador") { showOpenConfirmation = true }
                            .buttonStyle(.linkaPrimary)
                    }
                case .unavailable:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Não foi possível localizar um painel nesta rede.")
                            .foregroundColor(.textPrimary)
                        Text("O Linka confirma o painel antes de oferecer a abertura.")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()
            Button(state == .locating ? "Procurando…" : "Localizar painel") {
                Task { await locatePanel() }
            }
            .buttonStyle(.linkaSecondary)
            .disabled(state == .locating)
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 300, alignment: .topLeading)
        .navigationTitle("Painel do roteador")
        .task { await locatePanel() }
        .confirmationDialog("Abrir o painel do roteador?", isPresented: $showOpenConfirmation, titleVisibility: .visible) {
            if case .found(let gateway) = state, let url = gateway.adminURL {
                Button("Abrir no navegador") { openURL(url) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            if case .found(let gateway) = state {
                Text("Você vai abrir a página de administração da sua rede em \(gateway.ip) no navegador. O Linka não acessa nem guarda suas credenciais.")
            }
        }
    }

    @MainActor
    private func locatePanel() async {
        state = .locating
        guard let gatewayIP = await ActiveGatewayDiscovery().discoverGateway() else {
            state = .unavailable
            return
        }
        let gateway = await GatewayProber().probe(gatewayIP: gatewayIP)
        state = gateway.isAccessible && gateway.adminURL != nil ? .found(gateway) : .unavailable
    }
}
#endif

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
                    Button(LinkaCopy.value("settings.subscription.manage"), action: manageSubscription)
                    #else
                    Link(LinkaCopy.value("settings.subscription.manage"), destination: LinkaExternalLinks.subscriptionManagement)
                    #endif
                    Button(isRestoring ? LinkaCopy.value("settings.subscription.restoring") : LinkaCopy.value("settings.subscription.restore"), action: restore)
                        .disabled(isRestoring)
                } footer: {
                    Text(LinkaCopy.value("settings.subscription.footer"))
                }
                if let message { Section { Text(message).foregroundColor(.textSecondary) } }
            }
            .linkaSheetToolbar(title: LinkaCopy.value("linka.plus")) { dismiss() }
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
                message = restored ? LinkaCopy.value("settings.subscription.restored") : LinkaCopy.value("settings.subscription.noPurchase")
            } catch {
                isRestoring = false; message = LinkaCopy.value("settings.subscription.restoreError")
            }
        }
    }
}

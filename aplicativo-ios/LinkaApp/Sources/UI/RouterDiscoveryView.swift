import SwiftUI
import NetworkDiagnostics

#if os(iOS)
private enum RouterPanelState: Equatable {
    case idle
    case locating
    case found(GatewayInfo)
    case unavailable
}

/// Acesso ao roteador, não scanner de rede: há no máximo o gateway da rota
/// ativa, confirmado por HTTP/HTTPS antes de ser oferecido ao usuário.
struct RouterDiscoveryView: View {
    @Environment(\.openURL) private var openURL
    @State private var state: RouterPanelState = .idle
    @State private var showOpenConfirmation = false
    @State private var savedPassword = ""
    @State private var hasSavedPassword = false
    private let service = "com.linka.router"

    var body: some View {
        List {
            Section(LinkaCopy.value("router.panel.title")) {
                switch state {
                case .idle:
                    Text(LinkaCopy.value("router.panel.idle"))
                        .foregroundColor(.secondary)
                case .locating:
                    HStack { ProgressView(); Text(LinkaCopy.value("router.panel.locating")) }
                case .found(let gateway):
                    VStack(alignment: .leading, spacing: 8) {
                        Label(LinkaCopy.value("router.panel.found"), systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(gateway.ip).font(.footnote).foregroundColor(.secondary)
                        Button(LinkaCopy.value("router.panel.open")) { showOpenConfirmation = true }
                    }
                case .unavailable:
                    Text(LinkaCopy.value("router.panel.unavailable"))
                        .foregroundColor(.secondary)
                }

                Button(state == .locating ? LinkaCopy.value("router.panel.locating") : LinkaCopy.value("router.panel.locate")) {
                    Task { await locatePanel() }
                }
                .disabled(state == .locating)
            }

            Section(header: Text(LinkaCopy.value("router.password.title")), footer: Text(LinkaCopy.value("router.password.footer"))) {
                SecureField(LinkaCopy.value("router.password.field"), text: $savedPassword)
                Button(LinkaCopy.value("common.savePassword")) {
                    if let data = savedPassword.data(using: .utf8) {
                        KeychainHelper.shared.save(data, service: service, account: "router_admin")
                        hasSavedPassword = true
                    }
                }
                if hasSavedPassword {
                    Button(LinkaCopy.value("router.password.remove"), role: .destructive) {
                        KeychainHelper.shared.delete(service: service, account: "router_admin")
                        savedPassword = ""
                        hasSavedPassword = false
                    }
                }
            }
        }
        .navigationTitle(LinkaCopy.value("router.title"))
        .onAppear {
            if let data = KeychainHelper.shared.read(service: service, account: "router_admin"),
               let password = String(data: data, encoding: .utf8) {
                savedPassword = password
                hasSavedPassword = true
            }
        }
        .confirmationDialog(LinkaCopy.value("router.panel.confirmation.title"), isPresented: $showOpenConfirmation, titleVisibility: .visible) {
            if case .found(let gateway) = state, let url = gateway.adminURL {
                Button(LinkaCopy.value("router.panel.open")) { openURL(url) }
            }
            Button(LinkaCopy.value("common.cancel"), role: .cancel) {}
        } message: {
            if case .found(let gateway) = state {
                Text(String(format: LinkaCopy.value("router.panel.confirmation.message"), locale: LinkaLanguagePreference.currentLocale, gateway.ip))
            }
        }
    }

    @MainActor
    private func locatePanel() async {
        state = .locating
        guard let ip = await ActiveGatewayDiscovery().discoverGateway() else {
            state = .unavailable
            return
        }
        let gateway = await GatewayProber().probe(gatewayIP: ip)
        state = gateway.isAccessible && gateway.adminURL != nil ? .found(gateway) : .unavailable
    }
}
#endif

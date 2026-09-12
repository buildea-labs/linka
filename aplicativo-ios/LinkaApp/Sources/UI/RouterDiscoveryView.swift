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
            Section("Painel do roteador") {
                switch state {
                case .idle:
                    Text("Localize o painel da rede Wi-Fi atual antes de abri-lo.")
                        .foregroundColor(.secondary)
                case .locating:
                    HStack { ProgressView(); Text("Procurando o painel nesta rede…") }
                case .found(let gateway):
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Painel encontrado", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(gateway.ip).font(.footnote).foregroundColor(.secondary)
                        Button("Abrir no navegador") { showOpenConfirmation = true }
                    }
                case .unavailable:
                    Text("Não foi possível localizar um painel nesta rede.")
                        .foregroundColor(.secondary)
                }

                Button(state == .locating ? "Procurando…" : "Localizar painel") {
                    Task { await locatePanel() }
                }
                .disabled(state == .locating)
            }

            Section(header: Text("Senha do roteador (opcional)"), footer: Text("A senha fica somente no Keychain deste dispositivo.")) {
                SecureField("Senha do roteador", text: $savedPassword)
                Button("Salvar senha") {
                    if let data = savedPassword.data(using: .utf8) {
                        KeychainHelper.shared.save(data, service: service, account: "router_admin")
                        hasSavedPassword = true
                    }
                }
                if hasSavedPassword {
                    Button("Remover senha salva", role: .destructive) {
                        KeychainHelper.shared.delete(service: service, account: "router_admin")
                        savedPassword = ""
                        hasSavedPassword = false
                    }
                }
            }
        }
        .navigationTitle("Acesso ao roteador")
        .onAppear {
            if let data = KeychainHelper.shared.read(service: service, account: "router_admin"),
               let password = String(data: data, encoding: .utf8) {
                savedPassword = password
                hasSavedPassword = true
            }
        }
        .confirmationDialog("Abrir o painel do roteador?", isPresented: $showOpenConfirmation, titleVisibility: .visible) {
            if case .found(let gateway) = state, let url = gateway.adminURL {
                Button("Abrir no navegador") { openURL(url) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            if case .found(let gateway) = state {
                Text("Você vai abrir a página de administração em \(gateway.ip). O Linka não acessa nem guarda as credenciais inseridas nela.")
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

import SwiftUI
import WebKit

#if os(iOS)
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        return WKWebView(frame: .zero, configuration: config)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct RouterWebView: View {
    let ipAddress: String
    @State private var url: URL?

    var body: some View {
        VStack(spacing: 0) {
            Label("Página do fabricante do roteador — fora do controle do Linka", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.15))

            Group {
                if let url = url {
                    WebView(url: url)
                } else {
                    ProgressView("Carregando...")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Acesso ao Roteador")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let parsedURL = URL(string: "http://\(ipAddress)") {
                url = parsedURL
            }
        }
    }
}

struct RouterDiscoveryView: View {
    @StateObject private var scanner = GatewayScanner()
    @State private var savedPassword = ""
    @State private var hasSavedPassword = false
    @State private var gatewayPendingConfirmation: DiscoveredGateway?
    @State private var confirmedGateway: DiscoveredGateway?
    private let service = "com.linka.router"

    var body: some View {
        List {
            Section(header: Text("Gateways Encontrados")) {
                if scanner.isScanning {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Buscando roteadores...")
                    }
                } else if scanner.gateways.isEmpty {
                    Text("Nenhum roteador encontrado na rede local.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(scanner.gateways) { gateway in
                        Button {
                            gatewayPendingConfirmation = gateway
                        } label: {
                            VStack(alignment: .leading) {
                                Text(gateway.manufacturer ?? gateway.hostname ?? "Roteador")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(gateway.ipAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Acesso Rápido")) {
                Button(action: {
                    scanner.startScan()
                }) {
                    Text(scanner.isScanning ? "Buscando..." : "Buscar Novamente")
                }
                .disabled(scanner.isScanning)
            }

            Section(header: Text("Gerenciador de Senha do Roteador (Opcional)"), footer: Text("Senha salva de forma segura usando o Keychain do dispositivo.")) {
                SecureField("Senha do Roteador", text: $savedPassword)
                Button("Salvar Senha") {
                    if let data = savedPassword.data(using: .utf8) {
                        KeychainHelper.shared.save(data, service: service, account: "router_admin")
                        hasSavedPassword = true
                    }
                }
                if hasSavedPassword {
                    Button("Remover Senha Salva", role: .destructive) {
                        KeychainHelper.shared.delete(service: service, account: "router_admin")
                        savedPassword = ""
                        hasSavedPassword = false
                    }
                }
            }

            NavigationLink(
                destination: RouterWebView(ipAddress: confirmedGateway?.ipAddress ?? ""),
                isActive: Binding(
                    get: { confirmedGateway != nil },
                    set: { isActive in
                        if !isActive {
                            confirmedGateway = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("Acesso ao Roteador")
        .onAppear {
            scanner.startScan()
            if let data = KeychainHelper.shared.read(service: service, account: "router_admin"),
               let pwd = String(data: data, encoding: .utf8) {
                savedPassword = pwd
                hasSavedPassword = true
            }
        }
        .alert(item: $gatewayPendingConfirmation) { gateway in
            Alert(
                title: Text("Você vai sair do Linka"),
                message: Text("Isto abre a página de administração do roteador (\(gateway.ipAddress)) fora do controle do Linka, normalmente por uma conexão sem criptografia (HTTP). O Linka não lê nem guarda o conteúdo dessa página."),
                primaryButton: .default(Text("Abrir mesmo assim")) {
                    confirmedGateway = gateway
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
}
#endif

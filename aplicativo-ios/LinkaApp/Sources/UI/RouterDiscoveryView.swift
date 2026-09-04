import SwiftUI
import WebKit

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
        Group {
            if let url = url {
                WebView(url: url)
                    .navigationTitle("Acesso ao Roteador")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ProgressView("Carregando...")
            }
        }
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
                        NavigationLink(destination: RouterWebView(ipAddress: gateway.ipAddress)) {
                            VStack(alignment: .leading) {
                                Text(gateway.manufacturer ?? gateway.hostname ?? "Roteador")
                                    .font(.headline)
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
                    }
                }
            }
        }
        .navigationTitle("Acesso ao Roteador")
        .onAppear {
            scanner.startScan()
            if let data = KeychainHelper.shared.read(service: service, account: "router_admin"),
               let pwd = String(data: data, encoding: .utf8) {
                savedPassword = pwd
            }
        }
    }
}

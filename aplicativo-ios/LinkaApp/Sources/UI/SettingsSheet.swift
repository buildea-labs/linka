import SwiftUI
import LinkaEntitlements
import LinkaModules
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SettingsSheet: View {
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var showPurchase = false
    @State private var testCount: Int = 0
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (build \(build))"
    }
    
    var colorScheme: ColorScheme? {
        if appAppearance == "light" { return .light }
        if appAppearance == "dark" { return .dark }
        return nil
    }
    
    var body: some View {
        List {
            Section(header: Text("ATIVIDADE").font(.monoCaption).foregroundColor(.textSecondary)) {
                NavigationLink(destination: HistoryView()) {
                    HStack {
                        Text("Histórico")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(testCount) testes")
                            .foregroundColor(.textSecondary)
                    }
                }
                .listRowBackground(Color.surfaceCard)
            }

            Section(header: Text("APARÊNCIA").font(.monoCaption).foregroundColor(.textSecondary)) {
                HStack {
                    Text("Aparência")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Picker("Aparência", selection: $appAppearance) {
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                        Text("Sistema").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .listRowBackground(Color.surfaceCard)
            }

            Section(header: Text("ASSINATURA").font(.monoCaption).foregroundColor(.textSecondary)) {
                Button(action: { showPurchase = true }) {
                    HStack {
                        Text("Linka")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(subscriptionStatusText)
                            .foregroundColor(.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.chevronAffordance)
                    }
                }
                .listRowBackground(Color.surfaceCard)
            }

            Section(header: Text("GERAL").font(.monoCaption).foregroundColor(.textSecondary)) {
                Button(action: { /* placeholder */ }) {
                    HStack {
                        Text("Buscar atualização")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("Buscar agora")
                            .foregroundColor(.textSecondary)
                    }
                }
                .listRowBackground(Color.surfaceCard)

                Button(action: { /* placeholder */ }) {
                    HStack {
                        Text("Notas da versão")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("Versão \(appVersion)")
                            .foregroundColor(.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.chevronAffordance)
                    }
                }
                .listRowBackground(Color.surfaceCard)
            }

            Section(header: Text("SOBRE O APP").font(.monoCaption).foregroundColor(.textSecondary)) {
                SettingsRow(icon: "info.circle.fill", color: Color(red: 0.1, green: 0.2, blue: 0.4), title: "Sobre Nós", url: "https://linka-speedtest.web.app")
                SettingsRow(icon: "speedometer", color: .orange, title: "Como medimos", url: "https://linka-speedtest.web.app/como-medimos")
                SettingsRow(icon: "lock.fill", color: .gray, title: "Privacidade & Termos de Uso", url: "https://linka-speedtest.web.app/privacidade")
            }
            .listRowBackground(Color.surfaceCard)

            #if DEBUG
            // Atalhos de desenvolvimento para exercitar a UI Plus sem
            // depender de um StoreKit Configuration file. Compilados
            // apenas em builds DEBUG — não existem no binário de
            // Release (issue #60, requisito de aceite 5).
            Section(header: Text("DEBUG INTERNO").font(.monoCaption).foregroundColor(.brandAccentWarm)) {
                Button(action: { entitlements.debugForcePlus() }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.brandAccentWarm)
                        Text("Forçar Linka Plus (DEBUG)")
                            .foregroundColor(.textPrimary)
                    }
                }

                Button(action: { entitlements.debugResetToFree() }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.brandAccentWarm)
                        Text("Resetar Compra Mockada")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .listRowBackground(Color.surfaceCard)
            #endif

            Section {
                EmptyView()
            } footer: {
                Text("Linka Speedtest · Versão \(appVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        #if canImport(UIKit)
        .listStyle(.insetGrouped)
        #else
        // `.insetGrouped` é iOS-only (issue #114); o estilo padrão da
        // `List` no macOS já se comporta como sidebar/inset nativo, sem
        // equivalente 1:1 que valha a pena forçar aqui (mesmo raciocínio
        // de HistoryView, issue #108).
        .listStyle(.automatic)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Ajustes")
        #if canImport(UIKit)
        // `navigationBarTitleDisplayMode` e o placement `.navigationBar`
        // do toolbar não existem no macOS — lá a titlebar não tem os
        // modos large/inline do UIKit, nem uma navigation bar separada
        // pra colorir (issue #114, mesmo padrão de HistoryView/#108).
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surfacePage, for: .navigationBar)
        #endif
        .onAppear {
            loadTestCount()
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet()
        }
        .id(appAppearance)
        .preferredColorScheme(colorScheme)
    }
    
    private var subscriptionStatusText: String {
        switch entitlements.snapshot.plan {
        case .free:
            return "R$ 34,90/ano"
        case .plus:
            return entitlements.snapshot.status == .active ? "Ativo" : "Expirado"
        }
    }

    private func loadTestCount() {
        Task { @MainActor in
            let repo = LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
            if let count = try? await repo.totalCount() {
                self.testCount = count
            }
        }
    }
}

private extension Color {
    /// Cor de baixa ênfase para o chevron de navegação/afordance.
    /// `UIColor.tertiaryLabel` é iOS-only (issue #114); `NSColor
    /// .tertiaryLabelColor` é o equivalente semântico direto no AppKit,
    /// mesmo papel de "texto terciário" que o macOS já expõe nativamente.
    static var chevronAffordance: Color {
        #if canImport(UIKit)
        Color(UIColor.tertiaryLabel)
        #elseif canImport(AppKit)
        Color(NSColor.tertiaryLabelColor)
        #else
        Color.textSecondary
        #endif
    }
}

struct SettingsRow: View {
    @Environment(\.openURL) var openURL
    var icon: String
    var color: Color
    var title: String
    var url: String?
    
    var body: some View {
        Button(action: {
            if let urlString = url, let dest = URL(string: urlString) {
                openURL(dest)
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.chevronAffordance)
            }
        }
    }
}

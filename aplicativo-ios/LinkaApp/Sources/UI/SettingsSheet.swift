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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Custom Header
                HStack {
                    Text("Ajustes")
                        .font(.displayTitle)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                VStack(spacing: 24) {
                    SettingsSection(header: "ATIVIDADE") {
                        NavigationLink(destination: HistoryView()) {
                            SettingsRowContent(title: "Histórico", subtitle: "\(testCount) testes", showChevron: false)
                        }
                    }

                    SettingsSection(header: "ASSINATURA") {
                        Button(action: { showPurchase = true }) {
                            SettingsRowContent(title: "Linka Plus", subtitle: subscriptionStatusText, showChevron: true)
                        }
                    }

                    SettingsSection(header: "SOBRE O APP") {
                        SettingsRow(icon: "info.circle.fill", color: Color(red: 0.1, green: 0.2, blue: 0.4), title: "Sobre o Linka", url: "https://linka-speedtest.web.app")
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "speedometer", color: .orange, title: "Como medimos", url: "https://linka-speedtest.web.app/como-medimos")
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "lock.fill", color: .gray, title: "Privacidade & Termos", url: "https://linka-speedtest.web.app/privacidade")
                    }

                    #if DEBUG
                    SettingsSection(header: "DEBUG INTERNO", headerColor: .brandAccentWarm) {
                        Button(action: { entitlements.debugForcePlus() }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.brandAccentWarm)
                                Text("Forçar Linka Plus (DEBUG)")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                        Divider().padding(.leading, 16)
                        Button(action: { entitlements.debugResetToFree() }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.brandAccentWarm)
                                Text("Resetar Compra Mockada")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                    }
                    #endif

                    Text("Versão \(appVersion)")
                        .font(.captionMedium)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.large)
        #if canImport(UIKit)
        .toolbarBackground(Color.surfacePage, for: .navigationBar)
        #endif
        .onAppear {
            loadTestCount()
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet()
        }
    }
    
    private var subscriptionStatusText: String {
        switch entitlements.snapshot.plan {
        case .free:
            return "Conhecer"
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

struct SettingsSection<Content: View>: View {
    var header: String
    var headerColor: Color = .textSecondary
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header.uppercased())
                .font(.monoCaption)
                .foregroundColor(headerColor)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.surfaceCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
    }
}

struct SettingsRowContent: View {
    var title: String
    var subtitle: String?
    var showChevron: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.textPrimary)
            Spacer()
            if let subtitle = subtitle {
                Text(subtitle)
                    .foregroundColor(.textSecondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.bodySmallStrong)
                    .foregroundColor(.chevronAffordance)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
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
                        .font(.bodySmallStrong)
                }
                
                Text(title)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.bodySmallStrong)
                    .foregroundColor(.chevronAffordance)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
}

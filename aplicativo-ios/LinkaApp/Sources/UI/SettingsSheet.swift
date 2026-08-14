import SwiftUI
import MeasurementHistory

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var showPurchase = false
    @State private var testCount: Int = 0
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }
    
    var colorScheme: ColorScheme? {
        if appAppearance == "light" { return .light }
        if appAppearance == "dark" { return .dark }
        return nil
    }
    
    var body: some View {
        NavigationStack {
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
                            Text("R$ 6,90/ano")
                                .foregroundColor(.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
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
                                .foregroundColor(Color(UIColor.tertiaryLabel))
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
                
                if isPro {
                    Section(header: Text("DEBUG INTERNO").font(.monoCaption).foregroundColor(.brandAccentWarm)) {
                        Button(action: { isPro = false }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.brandAccentWarm)
                                Text("Resetar Compra Mockada")
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .listRowBackground(Color.surfaceCard)
                }
                
                Section {
                    EmptyView()
                } footer: {
                    Text("Linka Speedtest · Versão \(appVersion)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.surfacePage.ignoresSafeArea())
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.surfacePage, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.surfaceCard)
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                loadTestCount()
            }
            .sheet(isPresented: $showPurchase) {
                PurchaseSheet()
            }
        }
        .id(appAppearance)
        .preferredColorScheme(colorScheme)
    }
    
    private func loadTestCount() {
        Task { @MainActor in
            let repo = FileMeasurementHistoryRepository(
                fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json")
            )
            if let count = try? await repo.totalCount() {
                self.testCount = count
            }
        }
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
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
    }
}

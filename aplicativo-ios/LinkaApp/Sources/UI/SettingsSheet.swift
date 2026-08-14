import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @State private var showPurchase = false
    
    @State private var isCheckingUpdate = false
    @State private var showUpdateAlert = false
    @State private var updateAlertTitle = ""
    @State private var updateAlertMessage = ""
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Aparência").font(.monoCaption).foregroundColor(.textSecondary)) {
                    Picker("Aparência", selection: $appAppearance) {
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                        Text("Sistema").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.surfaceCard)
                }
                
                Section(header: Text("Assinatura").font(.monoCaption).foregroundColor(.textSecondary)) {
                    Button(action: {
                        showPurchase = true
                    }) {
                        HStack {
                            Image("wordmark")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 16)
                            Spacer()
                            Text("Em breve")
                                .font(.bodyRegular)
                                .foregroundColor(.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .listRowBackground(Color.surfaceCard)
                }
                
                Section(header: Text("Geral").font(.monoCaption).foregroundColor(.textSecondary)) {
                    Button(action: {
                        checkForUpdates()
                    }) {
                        HStack {
                            Text("Buscar atualização")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if isCheckingUpdate {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .listRowBackground(Color.surfaceCard)
                }
                
                Section(header: Text("Sobre o app").font(.monoCaption).foregroundColor(.textSecondary)) {
                    HStack {
                        Text("Versão")
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(appVersion)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                    }
                    .listRowBackground(Color.surfaceCard)
                }
                
                Section {
                    EmptyView()
                } footer: {
                    Text("Linka Speedtest · Versão \(appVersion)")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfacePage.ignoresSafeArea())
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surfacePage, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                    .font(.bodyRegular.weight(.bold))
                    .foregroundColor(.brandSurface)
                }
            }
            .sheet(isPresented: $showPurchase) {
                PurchaseSheet()
            }
            .alert(isPresented: $showUpdateAlert) {
                Alert(title: Text(updateAlertTitle), message: Text(updateAlertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func checkForUpdates() {
        isCheckingUpdate = true
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            self.updateAlertTitle = "Erro"
            self.updateAlertMessage = "Não foi possível verificar atualizações."
            self.showUpdateAlert = true
            self.isCheckingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isCheckingUpdate = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let appStoreVersion = firstResult["version"] as? String {
                    
                    let currentVersion = self.appVersion
                    if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        self.updateAlertTitle = "Atualização Disponível"
                        self.updateAlertMessage = "A versão \(appStoreVersion) está disponível na App Store."
                    } else {
                        self.updateAlertTitle = "App Atualizado"
                        self.updateAlertMessage = "Você já está usando a versão mais recente."
                    }
                } else {
                    self.updateAlertTitle = "Erro"
                    self.updateAlertMessage = "Não foi possível verificar atualizações."
                }
                self.showUpdateAlert = true
            }
        }.resume()
    }
}

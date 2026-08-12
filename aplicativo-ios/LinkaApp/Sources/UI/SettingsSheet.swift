import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @State private var showPurchase = false
    
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
                            Text("Linka")
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
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
        }
    }
}

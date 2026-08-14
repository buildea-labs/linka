import SwiftUI

struct PurchaseSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Close Button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.textSecondary.opacity(0.14))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Logo Box
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.textPrimary)
                                .frame(width: 72, height: 72)
                            
                            Image("wordmark")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                                .foregroundColor(Color.surfacePage)
                        }
                        .padding(.top, 40)
                        
                        // Titles
                        Text("Linka Pro")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .padding(.top, 24)
                        
                        Text("Uma medição limpa, sem interrupções, e tudo\no que vier depois.")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 32)
                            
                        // Features List
                        VStack(spacing: 0) {
                            PurchaseFeatureRow(text: "Nenhum anúncio, em nenhuma tela", showDivider: true)
                            PurchaseFeatureRow(text: "Acesso antecipado a novos recursos", showDivider: true)
                            PurchaseFeatureRow(text: "Widget de velocidade na tela de início", showDivider: false)
                        }
                        .padding(.vertical, 8)
                        .background(Color.surfaceCard)
                        .cornerRadius(16)
                        .padding(.top, 32)
                        .padding(.horizontal, 24)
                        
                        // Price Card
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("R$")
                                    .font(.system(size: 24, weight: .bold))
                                Text("6,90")
                                    .font(.system(size: 36, weight: .bold))
                                Text("/ ano")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                            .foregroundColor(.textPrimary)
                            
                            Text("Compra única · sem renovação automática")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textPrimary, lineWidth: 1.5)
                        )
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
                
                // Bottom CTA and Disclaimer
                VStack(spacing: 0) {
                    Button(action: {
                        isPro = true
                        dismiss()
                    }) {
                        Text("Comprar por R$ 6,90/ano")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.surfacePage)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.textPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: {
                        isPro = true
                        dismiss()
                    }) {
                        Text("Restaurar compra")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 16)
                    
                    Text("Compra única de R$ 6,90, válida por um ano, sem renovação automática. Gerencie sua compra nos Ajustes do Apple ID.")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                        
                    HStack(spacing: 4) {
                        Link("Termos de Uso", destination: URL(string: "https://linka-speedtest.web.app/termos")!)
                            .font(.system(size: 10))
                        
                        Text("e")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary.opacity(0.6))
                        
                        Link("Política de Privacidade", destination: URL(string: "https://linka-speedtest.web.app/privacidade")!)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.brandSurface)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
        }
    }
}

struct PurchaseFeatureRow: View {
    var text: String
    var showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            
            if showDivider {
                Divider()
                    .padding(.horizontal, 20)
            }
        }
    }
}

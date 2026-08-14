import SwiftUI

struct PurchaseSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                
                Spacer()
                
                Image("wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .padding(.bottom, 24)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(title: "Teste de velocidade completo", icon: "speedometer")
                    FeatureRow(title: "Histórico de medições", icon: "clock.arrow.circlepath")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
                
                Button(action: {
                    // Coming soon
                }) {
                    Text("Em breve")
                        .font(.bodyRegular.weight(.bold))
                        .foregroundColor(.brandOnSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.textSecondary)
                        .cornerRadius(100)
                }
                .disabled(true)
                .padding(.horizontal, 24)
                
                Button(action: {
                    // Restaurar compra
                }) {
                    Text("Restaurar compra")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary.opacity(0.5))
                }
                .disabled(true)
                .padding(.top, 24)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Assinatura renovada automaticamente. Cancele a qualquer momento nas configurações da App Store.")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Link("Termos de Uso", destination: URL(string: "https://linka.app/termos")!)
                            .font(.system(size: 10))
                        
                        Text("e")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary.opacity(0.6))
                        
                        Link("Política de Privacidade", destination: URL(string: "https://linka.app/privacidade")!)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.brandSurface)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

struct FeatureRow: View {
    var title: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.brandSurface)
                .frame(width: 24)
            
            Text(title)
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
        }
    }
}

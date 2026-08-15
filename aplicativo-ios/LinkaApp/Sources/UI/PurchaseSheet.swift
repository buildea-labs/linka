import SwiftUI
import LinkaEntitlements

struct PurchaseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

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
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.brandAccentWarm)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    }

                    Button(action: purchase) {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(Color.surfacePage)
                            } else {
                                Text("Comprar por R$ 6,90/ano")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(Color.surfacePage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.textPrimary)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing || isRestoring)
                    .padding(.horizontal, 24)

                    Button(action: restore) {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restaurar compra")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .disabled(isPurchasing || isRestoring)
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

    private func purchase() {
        guard !isPurchasing, !isRestoring else { return }
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let outcome = try await entitlements.purchase()
                await MainActor.run {
                    isPurchasing = false
                    switch outcome {
                    case .purchased:
                        dismiss()
                    case .userCancelled:
                        // Cancelamento silencioso: o usuário desistiu do
                        // fluxo nativo da App Store, sem estado de erro.
                        break
                    case .pending:
                        errorMessage = "Sua compra está pendente de aprovação (ex.: Compras Familiares). Você será avisado quando ela for concluída."
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "Não foi possível concluir a compra agora. Tente novamente em instantes."
                }
            }
        }
    }

    private func restore() {
        guard !isPurchasing, !isRestoring else { return }
        isRestoring = true
        errorMessage = nil

        Task {
            do {
                let restored = try await entitlements.restore()
                await MainActor.run {
                    isRestoring = false
                    if restored {
                        dismiss()
                    } else {
                        errorMessage = "Nenhuma compra ativa foi encontrada para restaurar."
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = "Não foi possível restaurar sua compra agora. Tente novamente em instantes."
                }
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

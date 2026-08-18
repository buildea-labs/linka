import SwiftUI
import StoreKit
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
                            .font(.bodySmallStrong)
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.textSecondary.opacity(0.14))
                            .clipShape(Circle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Fechar")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Hero
                        Image("Logo")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(height: 32)
                            .foregroundColor(.textPrimary)
                            .padding(.top, 48)
                        
                        // Titles
                        Text("Linka Plus")
                            .font(.displayTitle)
                            .foregroundColor(.textPrimary)
                            .padding(.top, 24)
                        
                        Text("Uma medição limpa, sem interrupções, e tudo\no que vier depois.")
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 32)
                            
                        // Grátis: o que já funciona sem Plus
                        PurchaseSectionHeader(text: "LINKA GRÁTIS")
                            .padding(.top, 32)

                        VStack(spacing: 0) {
                            PurchaseFeatureRow(
                                text: "Medição de velocidade",
                                showDivider: true
                            )
                            PurchaseFeatureRow(
                                text: "Histórico de resultados",
                                showDivider: false
                            )
                        }
                        .padding(.vertical, 8)
                        .background(Color.surfaceCard)
                        .cornerRadius(16)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)

                        // Plus: capacidades hoje gateadas por LinkaCapability
                        PurchaseSectionHeader(text: "LINKA PLUS")
                            .padding(.top, 24)

                        VStack(spacing: 0) {
                            PurchaseFeatureRow(
                                text: "Assist: intérprete IA",
                                showDivider: true
                            )
                            PurchaseFeatureRow(
                                text: "Insights e tendências",
                                showDivider: false
                            )
                        }
                        .padding(.vertical, 8)
                        .background(Color.surfaceCard)
                        .cornerRadius(16)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)

                        // Price Card
                        VStack(spacing: 8) {
                            if let product = entitlements.product {
                                Text(product.displayPrice)
                                    .font(.displayLarge)
                                    .foregroundColor(.textPrimary)

                                Text("Assinatura anual · renovação automática")
                                    .font(.captionMedium)
                                    .foregroundColor(.textSecondary)
                            } else if entitlements.isLoadingProduct {
                                ProgressView()
                                    .padding(.vertical, 6)
                            } else {
                                Text("Não foi possível carregar o preço agora")
                                    .font(.bodySmallMedium)
                                    .foregroundColor(.textSecondary)

                                Button(action: {
                                    Task { await entitlements.loadProduct() }
                                }) {
                                    Text("Tentar novamente")
                                        .font(.bodySmallStrong)
                                        .foregroundColor(.textPrimary)
                                }
                                .padding(.top, 4)
                            }
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
                            .font(.captionMedium)
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
                            } else if let product = entitlements.product {
                                Text("Comprar por \(product.displayPrice)/ano")
                                    .font(.buttonLabel)
                            } else {
                                Text("Carregando preço…")
                                    .font(.buttonLabel)
                            }
                        }
                        .foregroundColor(Color.surfacePage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.textPrimary)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing || isRestoring || entitlements.product == nil)
                    .padding(.horizontal, 24)

                    Button(action: restore) {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restaurar compra")
                                .font(.bodySmallMedium)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .disabled(isPurchasing || isRestoring)
                    .padding(.top, 16)

                    Text(disclaimerText)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                        
                    HStack(spacing: 4) {
                        Link("Termos de Uso", destination: URL(string: "https://linka-speedtest.web.app/termos")!)
                            .font(.captionSmall)
                        
                        Text("e")
                            .font(.captionSmall)
                            .foregroundColor(.textSecondary.opacity(0.6))
                        
                        Link("Política de Privacidade", destination: URL(string: "https://linka-speedtest.web.app/privacidade")!)
                            .font(.captionSmall)
                    }
                    .foregroundColor(.brandSurface)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
        }
    }

    /// Descreve a assinatura auto-renovável.
    private var disclaimerText: String {
        if let product = entitlements.product {
            return "Valor de \(product.displayPrice) cobrado anualmente, com renovação automática. Você pode cancelar ou gerenciar sua assinatura nos Ajustes do Apple ID a qualquer momento."
        }
        return "Valor anual cobrado com renovação automática. Você pode cancelar ou gerenciar sua assinatura nos Ajustes do Apple ID a qualquer momento."
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

/// Cabeçalho que separa visualmente o que é grátis do que é Plus — os dois
/// nunca aparecem misturados numa lista única.
struct PurchaseSectionHeader: View {
    var text: String

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.captionSmallStrong)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

struct PurchaseFeatureRow: View {
    var text: String
    var showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.bodySmallStrong)
                    .foregroundColor(.textPrimary)
                
                Text(text)
                    .font(.bodySmallMedium)
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

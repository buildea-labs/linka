import SwiftUI
import StoreKit
import LinkaEntitlements

struct PurchaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    let entryPoint: PurchaseEntryPoint
    let onPurchaseCompleted: (() -> Void)?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    init(entryPoint: PurchaseEntryPoint = .settings, onPurchaseCompleted: (() -> Void)? = nil) {
        self.entryPoint = entryPoint
        self.onPurchaseCompleted = onPurchaseCompleted
    }

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Fechar", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .foregroundColor(.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Fechar")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Image("Logo")
                            .resizable().renderingMode(.template).scaledToFit()
                            .frame(height: 30).foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity).padding(.top, 22)
                        Text(entryPoint.title)
                            .font(.displayTitle).foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity).padding(.top, 20)
                        Text(entryPoint.subtitle)
                            .font(.bodyRegular).foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                            .padding(.top, 8).padding(.horizontal, 28)

                        PurchaseSectionHeader(text: "LINKA GRÁTIS").padding(.top, 32)
                        featureList([
                            "Medição de velocidade", "Histórico de resultados",
                            "Detalhes básicos da conexão", "Identificação da rede Wi-Fi quando disponível"
                        ])
                        PurchaseSectionHeader(text: "LINKA PLUS").padding(.top, 24)
                        featureList([
                            "Entenda o seu resultado", "Descubra problemas que se repetem",
                            "Acompanhe cada rede no histórico", "Detalhes avançados do Wi-Fi"
                        ])
                        Text("O diagnóstico Wi-Fi avançado requer configuração opcional no app Atalhos.")
                            .font(.captionMedium).foregroundColor(.textSecondary)
                            .padding(.top, 12).padding(.horizontal, 28)
                        priceState.padding(.top, 24).padding(.horizontal, 24)
                    }
                    .padding(.bottom, 28)
                }

                VStack(spacing: 0) {
                    if let errorMessage {
                        Text(errorMessage).font(.captionMedium).foregroundColor(.brandAccentWarm)
                            .multilineTextAlignment(.center).padding(.horizontal, 28).padding(.bottom, 10)
                    }
                    Button(action: purchase) {
                        if isPurchasing { ProgressView().tint(Color.surfacePage) }
                        else if let product = entitlements.product { Text("Assinar por \(product.displayPrice)/ano").font(.buttonLabel) }
                        else { Text("Carregando preço…").font(.buttonLabel) }
                    }
                    .foregroundColor(Color.surfacePage).frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Color.textPrimary).clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isPurchasing || isRestoring || entitlements.product == nil).padding(.horizontal, 24)
                    Button(action: restore) {
                        if isRestoring { ProgressView() } else { Text("Restaurar compra") }
                    }
                    .font(.bodySmallMedium).foregroundColor(.textSecondary)
                    .disabled(isPurchasing || isRestoring).padding(.top, 14)
                    Text(disclaimerText).font(.captionSmall).foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center).padding(.top, 14).padding(.horizontal, 28)
                    HStack(spacing: 4) {
                        Link("Termos de Uso", destination: LinkaExternalLinks.terms)
                        Text("e").foregroundColor(.textSecondary)
                        Link("Política de Privacidade", destination: LinkaExternalLinks.privacy)
                    }
                    .font(.captionSmall).foregroundColor(.brandSurface).padding(.top, 8).padding(.bottom, 20)
                }
            }
        }
    }

    // Issue UI Polish v2 (2026-08-29): sem card por seção — "hero +
    // benefícios + preço + CTA", não "card, card, card". O conteúdo
    // (o que é grátis, o que é Plus, preço) continua o mesmo; só a moldura
    // visual em volta de cada bloco foi removida.
    private func featureList(_ features: [String]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                PurchaseFeatureRow(text: feature, showDivider: index < features.count - 1)
            }
        }
        .padding(.top, 8).padding(.horizontal, 24)
    }

    @ViewBuilder private var priceState: some View {
        VStack(spacing: 8) {
            if let product = entitlements.product {
                Text(product.displayPrice).font(.displayLarge).foregroundColor(.textPrimary)
                Text("Assinatura anual com renovação automática").font(.captionMedium).foregroundColor(.textSecondary)
            } else if entitlements.isLoadingProduct {
                ProgressView().padding(.vertical, 6)
            } else {
                Text("Não foi possível carregar o preço agora").font(.bodySmallMedium).foregroundColor(.textSecondary)
                Button("Tentar novamente") { Task { await entitlements.loadProduct() } }
                    .font(.bodySmallStrong).foregroundColor(.textPrimary)
            }
        }
        .padding(.vertical, 22).frame(maxWidth: .infinity)
    }

    private var disclaimerText: String {
        if let product = entitlements.product {
            return "Valor de \(product.displayPrice) cobrado anualmente, com renovação automática. Gerencie a assinatura pela Apple."
        }
        return "Assinatura anual com renovação automática. Gerencie a assinatura pela Apple."
    }

    private func purchase() {
        guard !isPurchasing, !isRestoring else { return }
        isPurchasing = true; errorMessage = nil
        Task {
            do {
                let outcome = try await entitlements.purchase()
                isPurchasing = false
                switch outcome {
                case .purchased: dismiss(); onPurchaseCompleted?()
                case .userCancelled: break
                case .pending: errorMessage = "A compra está pendente de aprovação."
                }
            } catch {
                isPurchasing = false; errorMessage = "Não foi possível concluir a compra agora. Tente novamente."
            }
        }
    }

    private func restore() {
        guard !isPurchasing, !isRestoring else { return }
        isRestoring = true; errorMessage = nil
        Task {
            do {
                let restored = try await entitlements.restore()
                isRestoring = false
                if restored { dismiss(); onPurchaseCompleted?() }
                else { errorMessage = "Nenhuma compra ativa foi encontrada." }
            } catch {
                isRestoring = false; errorMessage = "Não foi possível restaurar a compra agora. Tente novamente."
            }
        }
    }
}

struct PurchaseSectionHeader: View {
    var text: String
    var body: some View {
        Text(text).font(.captionSmallStrong).foregroundColor(.textSecondary).tracking(0.5).padding(.horizontal, 28)
    }
}

struct PurchaseFeatureRow: View {
    var text: String
    var showDivider: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark").font(.bodySmallStrong).foregroundColor(.textPrimary)
                Text(text).font(.bodySmallMedium).foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.vertical, 14).padding(.horizontal, 20)
            if showDivider { Divider().padding(.horizontal, 20) }
        }
        .accessibilityElement(children: .combine)
    }
}

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

    private var plusBenefits: [String] {
        var benefits = [
            "Assist explica o resultado",
            "Identifica problemas recorrentes",
            "Compara seu histórico",
            "Diagnóstico avançado de Wi-Fi"
        ]

        switch entryPoint {
        case .assist:
            benefits.removeAll { $0 == "Assist explica o resultado" }
            benefits.insert("Assist explica o resultado", at: 0)
        case .historyInsights:
            benefits.removeAll { $0 == "Compara seu histórico" || $0 == "Identifica problemas recorrentes" }
            benefits.insert("Identifica problemas recorrentes", at: 0)
            benefits.insert("Compara seu histórico", at: 1)
        case .advancedWiFi:
            benefits.removeAll { $0 == "Diagnóstico avançado de Wi-Fi" }
            benefits.insert("Diagnóstico avançado de Wi-Fi", at: 0)
        case .settings:
            break
        }
        
        return benefits
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
                    VStack(alignment: .center, spacing: 0) {
                        LinkaPlusWordmarkView(height: 28)
                            .padding(.top, 16)

                        if entryPoint != .settings {
                            Text(entryPoint.title)
                                .font(.displayTitle)
                                .foregroundColor(.textPrimary)
                                .padding(.top, 16)
                        }

                        Text(entryPoint.subtitle)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 6)
                            .padding(.horizontal, 28)

                        // Lista de Benefícios Plus
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(plusBenefits, id: \.self) { benefit in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.bodyRegularStrong)
                                        .foregroundColor(.brandAccentWarm)
                                    Text(benefit)
                                        .font(.bodyRegular)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 28)

                        priceState
                            .padding(.top, 28)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }

                VStack(spacing: 0) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.captionMedium)
                            .foregroundColor(.statusAttention)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 10)
                    }

                    Button(action: purchase) {
                        if isPurchasing {
                            ProgressView().tint(Color.brandOnSurface)
                        } else {
                            switch entitlements.productState {
                            case .loaded(let product):
                                Text("Assinar por \(product.displayPrice)/ano")
                            case .loading:
                                Text("Carregando preço…")
                            case .unavailable, .error:
                                Text("Assinar")
                            }
                        }
                    }
                    .buttonStyle(.linkaPrimary)
                    .disabled(isPurchasing || isRestoring || !isProductLoaded)
                    .padding(.horizontal, 24)

                    Button(action: restore) {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restaurar compra")
                        }
                    }
                    .buttonStyle(.linkaSecondary)
                    .disabled(isPurchasing || isRestoring)
                    .padding(.top, 14)

                    Text(disclaimerText)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 28)

                    HStack(spacing: 4) {
                        Link("Termos de Uso", destination: LinkaExternalLinks.terms)
                        Text("·").foregroundColor(.textSecondary)
                        Link("Privacidade", destination: LinkaExternalLinks.privacy)
                    }
                    .font(.captionSmall)
                    .foregroundColor(.brandSurface)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder private var priceState: some View {
        VStack(spacing: 4) {
            switch entitlements.productState {
            case .loaded(let product):
                Text(product.displayPrice)
                    .font(.displayLarge)
                    .foregroundColor(.textPrimary)
                Text("Cobrado anualmente · Cancele quando quiser")
                    .font(.captionMedium)
                    .foregroundColor(.textSecondary)
            case .loading:
                ProgressView().padding(.vertical, 6)
            case .unavailable:
                Text("Plano não disponível no momento")
                    .font(.bodySmallMedium)
                    .foregroundColor(.textSecondary)
                Button("Tentar novamente") {
                    Task { await entitlements.loadProduct() }
                }
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
            case .error(let message):
                Text("Não foi possível carregar o preço agora")
                    .font(.bodySmallMedium)
                    .foregroundColor(.textSecondary)
                #if DEBUG
                Text(message)
                    .font(.captionSmall)
                    .foregroundColor(.statusAttention)
                #endif
                Button("Tentar novamente") {
                    Task { await entitlements.loadProduct() }
                }
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var isProductLoaded: Bool {
        if case .loaded = entitlements.productState { return true }
        return false
    }

    private var disclaimerText: String {
        if case .loaded(let product) = entitlements.productState {
            return "Valor de \(product.displayPrice)/ano com renovação automática pela Apple."
        }
        return "Assinatura anual com renovação automática pela Apple."
    }

    private func purchase() {
        guard !isPurchasing, !isRestoring else { return }
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                let outcome = try await entitlements.purchase()
                isPurchasing = false
                switch outcome {
                case .purchased:
                    dismiss()
                    onPurchaseCompleted?()
                case .userCancelled:
                    break
                case .pending:
                    errorMessage = "A compra está pendente de aprovação."
                }
            } catch {
                isPurchasing = false
                errorMessage = "Não foi possível concluir a compra agora. Tente novamente."
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
                isRestoring = false
                if restored {
                    dismiss()
                    onPurchaseCompleted?()
                } else {
                    errorMessage = "Nenhuma compra ativa foi encontrada."
                }
            } catch {
                isRestoring = false
                errorMessage = "Não foi possível restaurar a compra agora. Tente novamente."
            }
        }
    }
}

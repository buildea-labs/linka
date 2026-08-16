import SwiftUI

#if canImport(UIKit)
import UIKit
import GoogleMobileAds

// MARK: - Public entry point

/// Native ad card. Substitui o `GADBannerView` cru pra parecer parte do app:
/// mesma paleta, tipografia semelhante, cantos arredondados. Só carrega
/// quando aparece na tela e cai silenciosamente se o AdMob não devolver ad —
/// não reserva slot vazio permanente.
struct BannerView: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let ad = loader.ad {
                NativeAdCard(nativeAd: ad)
                    .frame(maxWidth: 360, minHeight: 72, maxHeight: 84)
                    .padding(.horizontal, 16)
            } else {
                // Placeholder invisível — mantém a .task rodando enquanto
                // isLoading; some quando o load falha.
                Color.clear.frame(height: loader.isLoading ? 72 : 0)
            }
        }
        .task { loader.loadIfNeeded() }
    }
}

// MARK: - Loader

/// Ad Unit ID de teste do Google pra native ads. Substituir por ID real do
/// AdMob antes do release em loja.
private let nativeAdTestUnitID = "ca-app-pub-3940256099942544/3986624511"

@MainActor
final class NativeAdLoader: NSObject, ObservableObject {
    @Published var ad: GADNativeAd?
    @Published var isLoading: Bool = false

    private var loader: GADAdLoader?
    private var didStart = false

    func loadIfNeeded() {
        guard !didStart else { return }
        didStart = true
        isLoading = true

        // Sem aspectRatio explícito: aceitamos qualquer formato e não
        // precisamos exibir mediaView, o que mantém o card compacto.
        let viewOptions = GADNativeAdViewAdOptions()
        viewOptions.preferredAdChoicesPosition = .topRightCorner

        loader = GADAdLoader(
            adUnitID: nativeAdTestUnitID,
            rootViewController: Self.topViewController(),
            adTypes: [.native],
            options: [viewOptions]
        )
        loader?.delegate = self
        loader?.load(GADRequest())
    }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

extension NativeAdLoader: GADNativeAdLoaderDelegate {
    nonisolated func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        Task { @MainActor in
            self.ad = nativeAd
            self.isLoading = false
        }
    }

    nonisolated func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            self.ad = nil
            self.isLoading = false
        }
    }
}

// MARK: - Template

/// Card visual do ad. `GADNativeAdView` como container UIKit; as subviews
/// (label/imageview/button) são registradas nas outlets requeridas pelo SDK
/// para atribuição e click-through funcionarem por padrão. Layout compacto,
/// horizontal, sem mediaView.
struct NativeAdCard: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let container = GADNativeAdView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 16
        container.clipsToBounds = true

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail

        let advertiserLabel = UILabel()
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        advertiserLabel.font = .systemFont(ofSize: 10, weight: .regular)
        advertiserLabel.textColor = .tertiaryLabel

        var ctaConfig = UIButton.Configuration.filled()
        ctaConfig.baseBackgroundColor = .label
        ctaConfig.baseForegroundColor = .systemBackground
        ctaConfig.cornerStyle = .capsule
        ctaConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        ctaConfig.attributedTitle = AttributedString("CTA", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]))
        let ctaButton = UIButton(configuration: ctaConfig)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.isUserInteractionEnabled = false // clicks handled by GADNativeAdView
        ctaButton.setContentHuggingPriority(.required, for: .horizontal)

        let adBadge = UILabel()
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.text = "Anúncio"
        adBadge.font = .systemFont(ofSize: 9, weight: .semibold)
        adBadge.textColor = .tertiaryLabel
        adBadge.backgroundColor = .tertiarySystemFill
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true

        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel, advertiserLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [iconImageView, textStack, ctaButton])
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12

        container.addSubview(rowStack)
        container.addSubview(adBadge)

        container.iconView = iconImageView
        container.headlineView = headlineLabel
        container.bodyView = bodyLabel
        container.advertiserView = advertiserLabel
        container.callToActionView = ctaButton

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            adBadge.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            adBadge.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            adBadge.heightAnchor.constraint(equalToConstant: 14),

            container.heightAnchor.constraint(lessThanOrEqualToConstant: 92),
        ])

        return container
    }

    func updateUIView(_ container: GADNativeAdView, context: Context) {
        (container.headlineView as? UILabel)?.text = nativeAd.headline
        (container.bodyView as? UILabel)?.text = nativeAd.body
        (container.advertiserView as? UILabel)?.text = nativeAd.advertiser

        if let icon = nativeAd.icon?.image {
            (container.iconView as? UIImageView)?.image = icon
            container.iconView?.isHidden = false
        } else {
            container.iconView?.isHidden = true
        }

        if let cta = nativeAd.callToAction, !cta.isEmpty, let button = container.callToActionView as? UIButton {
            var config = button.configuration
            config?.attributedTitle = AttributedString(cta, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ]))
            button.configuration = config
            button.isHidden = false
        } else {
            container.callToActionView?.isHidden = true
        }

        // Assign nativeAd LAST — SDK wires interactions com as outlets acima.
        container.nativeAd = nativeAd
    }
}

#else

// MARK: - macOS stub

/// Ads são iOS-only por decisão de produto (issue #75) — `GoogleMobileAds`
/// só tem slice iOS. No macOS nativo (não Mac Catalyst) o espaço do banner
/// simplesmente não existe: sem placeholder decorativo, `BannerView()`
/// continua type-checking nos call sites (ex.: `MainView`) como uma view
/// vazia, sem reservar altura nem competir com o resultado.
struct BannerView: View {
    var body: some View {
        EmptyView()
    }
}

#endif

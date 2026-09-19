import SwiftUI

/// Ponto de inserção exclusivo do Histórico. Não há placeholder: se o
/// consentimento ou o carregamento falhar, a lista mantém apenas conteúdo do
/// usuário.
struct BannerView: View {
    @EnvironmentObject private var ads: LinkaAdsCoordinator

    var body: some View {
        #if os(iOS)
        if let nativeAd = ads.nativeAd {
            NativeAdCard(nativeAd: nativeAd)
                .accessibilityElement(children: .contain)
        }
        #else
        EmptyView()
        #endif
    }
}

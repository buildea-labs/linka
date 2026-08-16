import SwiftUI

/// Duração da animação de entrada da marca. `onComplete` é amarrado a este
/// mesmo valor — não existe espera fixa adicional além da própria transição
/// visual (issue #48).
private let splashFadeInDuration: Double = 0.8

struct SplashView: View {
    var onComplete: () -> Void
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()

            Image("wordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .opacity(opacity)
        }
        .onAppear {
            // `#available(iOS 17.0, *)` sozinho não protege o macOS: o `*`
            // cai no deployment target mínimo do target (macOS 13.0), e
            // `withAnimation(_:completion:)` só existe a partir do macOS
            // 14.0 — sem o `macOS 14.0` explícito aqui, o build macOS falha
            // (issue #108).
            if #available(iOS 17.0, macOS 14.0, *) {
                withAnimation(.easeIn(duration: splashFadeInDuration)) {
                    opacity = 1.0
                } completion: {
                    onComplete()
                }
            } else {
                withAnimation(.easeIn(duration: splashFadeInDuration)) {
                    opacity = 1.0
                }
                // iOS 16 / macOS < 14 não expõem completion handler para
                // withAnimation; aguarda exatamente a duração da própria
                // animação, sem acrescentar espera decorativa além dela.
                DispatchQueue.main.asyncAfter(deadline: .now() + splashFadeInDuration) {
                    onComplete()
                }
            }
        }
    }
}

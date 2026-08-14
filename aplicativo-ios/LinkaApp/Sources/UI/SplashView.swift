import SwiftUI

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
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onComplete()
            }
        }
    }
}

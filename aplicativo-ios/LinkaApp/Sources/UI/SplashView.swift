import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            
            HStack(alignment: .bottom, spacing: 3) {
                Text("l")
                    .font(Font.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.brandAccentWarm)
                        .frame(width: 18, height: 18)
                        .offset(y: bounce ? -24 : 0)
                        .padding(.bottom, 6)
                    
                    Rectangle()
                        .fill(Color.textPrimary)
                        .frame(width: 18, height: 32)
                        .cornerRadius(4)
                }
                .padding(.bottom, 4)
                
                Text("nka")
                    .font(Font.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .tracking(-1)
        }
        .onAppear {
            withAnimation(
                Animation.interpolatingSpring(stiffness: 170, damping: 8)
                    .repeatForever(autoreverses: true)
            ) {
                bounce = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onComplete()
            }
        }
    }
}

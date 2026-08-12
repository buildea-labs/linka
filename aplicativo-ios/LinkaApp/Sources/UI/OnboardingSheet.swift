import SwiftUI

struct OnboardingSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.linkaBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "network")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.linkaPrimary)
                
                Text("Welcome to Linka")
                    .font(.linkaLargeTitle)
                    .foregroundColor(.linkaText)
                    .multilineTextAlignment(.center)
                
                Text("Fast, accurate, and Apple-first speed testing for your network.")
                    .font(.linkaBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.linkaTextSecondary)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Get Started")
                        .font(.linkaHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.linkaPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

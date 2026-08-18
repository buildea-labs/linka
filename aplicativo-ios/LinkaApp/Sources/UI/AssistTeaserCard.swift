import SwiftUI

struct AssistTeaserCard: View {
    let downloadSpeed: Double
    let onFreeTap: () -> Void
    let onPlusTap: () -> Void
    let isPlusActive: Bool
    
    private var dynamicQuestion: String {
        if downloadSpeed > 100 {
            return "Posso jogar online sem lag com essa conexão?"
        } else if downloadSpeed > 30 {
            return "Essa velocidade aguenta streaming em 4K?"
        } else if downloadSpeed > 10 {
            return "Essa velocidade é boa para uma chamada de vídeo?"
        } else {
            return "Por que minha conexão está lenta?"
        }
    }
    
    var body: some View {
        Button(action: {
            if isPlusActive {
                onPlusTap()
            } else {
                onFreeTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ASSIST ✦")
                        .font(.monoCaption)
                        .foregroundColor(.brandAccentWarm)
                    Spacer()
                    if !isPlusActive {
                        Image(systemName: "lock.fill")
                            .font(.captionStrong)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Text(dynamicQuestion)
                    .font(.bodyRegularStrong)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !isPlusActive {
                    // Blurred lines to simulate hidden content
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.textSecondary.opacity(0.2))
                            .frame(height: 8)
                            .frame(maxWidth: .infinity)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.textSecondary.opacity(0.2))
                            .frame(height: 8)
                            .frame(maxWidth: 200)
                    }
                    .padding(.top, 4)
                } else {
                    Text("Toque para ver a resposta →")
                        .font(.captionStrong)
                        .foregroundColor(.brandAccentWarm)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.surfaceCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import NetworkCore
import NetworkAssist

struct AssistSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var answer: String = ""
    @State private var isAnalyzing: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.surfacePage.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(.brandAccentWarm)
                        
                        Text("Linka Assist")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.top, 24)
                    
                    if isAnalyzing {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Analisando sua conexão...")
                                .font(.bodyRegular)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                TypewriterText(text: answer)
                                    .font(.bodyRegular)
                                    .foregroundColor(.textPrimary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .onAppear {
                performAnalysis()
            }
        }
    }
    
    private func performAnalysis() {
        Task {
            // Simulate network request/analysis delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                self.isAnalyzing = false
                self.answer = "Analisando seu histórico recente, notei que a sua conexão Wi-Fi melhorou cerca de 15% nos últimos dias. Isso pode ser resultado de uma menor interferência no canal da sua rede ou devido a um reinício recente do seu roteador. Continuaremos monitorando para garantir a melhor experiência."
            }
        }
    }
}

struct TypewriterText: View {
    let text: String
    @State private var displayedText: String = ""
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onChange(of: text) { _ in
                displayedText = ""
                startTyping()
            }
    }
    
    private func startTyping() {
        // Simple word by word or char by char animation using Task
        Task {
            for char in text {
                try? await Task.sleep(nanoseconds: 15_000_000) // 15ms per character
                await MainActor.run {
                    displayedText.append(char)
                }
            }
        }
    }
}

struct AssistSheet_Previews: PreviewProvider {
    static var previews: some View {
        AssistSheet()
    }
}

import SwiftUI
import MeasurementHistory
import NetworkCore

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct AssistSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var isTyping: Bool = false
    
    @State private var availableQuestions: [String] = [
        "Serve para uma chamada de vídeo?",
        "Como está comparado aos meus últimos testes?",
        "Minha conexão variou muito esta semana?",
        "Esse resultado está melhor ou pior que o anterior?"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Assist")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                Text("Pergunte sobre este resultado.")
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser {
                                    Spacer(minLength: 40)
                                    Text(msg.text)
                                        .font(.bodyRegular)
                                        .padding()
                                        .background(Color.textPrimary.opacity(0.04))
                                        .cornerRadius(16)
                                        .foregroundColor(.textPrimary)
                                } else {
                                    Text(msg.text)
                                        .font(.bodyRegular)
                                        .padding()
                                        .background(Color.brandAccentWarm.opacity(0.1))
                                        .cornerRadius(16)
                                        .foregroundColor(.textPrimary)
                                    Spacer(minLength: 40)
                                }
                            }
                            .id(msg.id)
                        }
                        
                        if isTyping {
                            HStack {
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .id("typing")
                        } else {
                            if !availableQuestions.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(availableQuestions, id: \.self) { q in
                                        Button(action: {
                                            submitQuestion(q)
                                        }) {
                                            HStack {
                                                Text(q)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .background(Color.textPrimary.opacity(0.04))
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, messages.isEmpty ? 0 : 16)
                                .id("suggestions")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo("suggestions", anchor: .bottom) }
                }
                .onChange(of: isTyping) { typing in
                    if typing {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    } else {
                        withAnimation { proxy.scrollTo("suggestions", anchor: .bottom) }
                    }
                }
            }
        }
        .background(Color.surfacePage)
    }
    
    private func submitQuestion(_ q: String) {
        if let index = availableQuestions.firstIndex(of: q) {
            availableQuestions.remove(at: index)
        }
        messages.append(ChatMessage(text: q, isUser: true))
        isTyping = true
        
        Task {
            // Fake network processing time to feel natural
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json")
            let repository = FileMeasurementHistoryRepository(fileURL: fileURL)
            let query = MeasurementQuery(limit: 50, sortOrder: .newestFirst)
            let results = (try? await repository.measurements(matching: query)) ?? []
            
            let responseText = generateAlgorithmicResponse(for: q, history: results)
            
            await MainActor.run {
                self.isTyping = false
                self.messages.append(ChatMessage(text: responseText, isUser: false))
            }
        }
    }
    
    private func generateAlgorithmicResponse(for q: String, history: [NetworkMeasurement]) -> String {
        let qLower = q.lowercased()
        
        guard let current = history.first else {
            return "Ainda não há testes suficientes para responder. Faça seu primeiro teste!"
        }
        let dl = current.downloadMbps ?? 0
        let ul = current.uploadMbps ?? 0
        let ping = current.latencyMs ?? 0
        
        if qLower.contains("vídeo") || qLower.contains("video") || qLower.contains("chamada") {
            if dl >= 5 && ul >= 2 && ping <= 150 {
                return "Sim. Seu download de \(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps e upload de \(String(format: "%.1f", ul).replacingOccurrences(of: ".", with: ",")) Mbps são suficientes para chamadas de vídeo em HD."
            } else {
                return "Pode haver instabilidade. Para chamadas de vídeo em HD, recomenda-se ao menos 5 Mbps de download e 2 Mbps de upload."
            }
        } else if qLower.contains("variou") || qLower.contains("semana") {
            let thisWeek = history.filter { $0.measuredAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
            if thisWeek.count < 2 {
                return "Não há testes suficientes nesta semana para avaliar a variação."
            }
            let dls = thisWeek.compactMap(\.downloadMbps)
            let minDl = dls.min() ?? 0
            let maxDl = dls.max() ?? 0
            return "Nesta semana, registramos \(thisWeek.count) testes. O download variou entre \(String(format: "%.1f", minDl).replacingOccurrences(of: ".", with: ",")) Mbps e \(String(format: "%.1f", maxDl).replacingOccurrences(of: ".", with: ",")) Mbps."
        } else if qLower.contains("pior") || qLower.contains("melhor") || qLower.contains("anterior") {
            if history.count < 2 {
                return "Este é o seu primeiro teste, não há um resultado anterior para comparar."
            }
            let prev = history[1]
            let prevDl = prev.downloadMbps ?? 0
            if dl > prevDl * 1.05 {
                return "O teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está melhor que o anterior (\(String(format: "%.1f", prevDl).replacingOccurrences(of: ".", with: ",")) Mbps)."
            } else if dl < prevDl * 0.95 {
                return "O teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está pior que o anterior (\(String(format: "%.1f", prevDl).replacingOccurrences(of: ".", with: ",")) Mbps)."
            } else {
                return "O teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está praticamente igual ao anterior (\(String(format: "%.1f", prevDl).replacingOccurrences(of: ".", with: ",")) Mbps)."
            }
        } else if qLower.contains("últimos") || qLower.contains("ultimos") || qLower.contains("comparado") {
            if history.count < 2 {
                return "Faça mais testes para podermos comparar a estabilidade."
            }
            let previous = Array(history.dropFirst().prefix(4))
            let avgDownload = previous.compactMap(\.downloadMbps).reduce(0, +) / Double(previous.count)
            if dl >= avgDownload * 1.1 {
                return "Seu teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está acima da sua média recente de \(String(format: "%.1f", avgDownload).replacingOccurrences(of: ".", with: ",")) Mbps."
            } else if dl <= avgDownload * 0.8 {
                return "Seu teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está abaixo da sua média recente de \(String(format: "%.1f", avgDownload).replacingOccurrences(of: ".", with: ",")) Mbps."
            } else {
                return "Seu teste atual (\(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps) está estável, dentro da sua média recente de \(String(format: "%.1f", avgDownload).replacingOccurrences(of: ".", with: ",")) Mbps."
            }
        } else if qLower.contains("ping") || qLower.contains("latência") || qLower.contains("latencia") {
            return "No seu último teste, o ping (latência) foi de \(ping) ms."
        } else if qLower.contains("download") {
            return "No seu último teste, o download foi de \(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps."
        } else if qLower.contains("upload") {
            return "No seu último teste, o upload foi de \(String(format: "%.1f", ul).replacingOccurrences(of: ".", with: ",")) Mbps."
        } else if qLower.contains("jogos") || qLower.contains("jogar") {
            if ping <= 50 {
                return "Com um ping de \(ping) ms, sua conexão está ótima para jogos online sem atrasos significativos."
            } else {
                return "Com um ping de \(ping) ms, você pode sentir um pouco de atraso (lag) em jogos competitivos. O ideal é abaixo de 50 ms."
            }
        } else {
            return "No seu último teste, registramos \(String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")) Mbps de download, \(String(format: "%.1f", ul).replacingOccurrences(of: ".", with: ",")) Mbps de upload e ping de \(ping) ms. Sua rede está medindo resultados consistentes com esses valores."
        }
    }
}

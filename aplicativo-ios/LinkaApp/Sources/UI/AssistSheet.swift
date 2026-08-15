import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkAssist

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

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]

    private let assistProvider: any NetworkAssistProviding
    private let assistIsRemote: Bool

    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        assistProvider: (any NetworkAssistProviding)? = nil,
        assistIsRemote: Bool = AssistContainer.isRemoteAssistEnabled()
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.assistProvider = assistProvider ?? AssistContainer.makeAssistProvider()
        self.assistIsRemote = assistIsRemote
    }

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
                        } else if !availableQuestions.isEmpty {
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
            let responseText = await answer(for: q)
            await MainActor.run {
                self.isTyping = false
                self.messages.append(ChatMessage(text: responseText, isUser: false))
            }
        }
    }

    private func answer(for question: String) async -> String {
        guard let currentMeasurement else {
            return "Ainda não há medições suficientes para responder. Faça seu primeiro teste."
        }
        guard assistIsRemote else {
            return "O Assist ainda não está configurado neste build."
        }

        let context = NetworkAssistContext(
            question: question,
            currentMeasurement: currentMeasurement,
            recentMeasurements: recentMeasurements,
            evidence: [],
            locale: "pt-BR"
        )

        do {
            let response = try await assistProvider.answer(context)
            switch response.disposition {
            case .answered:
                return response.text
            case .insufficientEvidence:
                return response.text.isEmpty
                    ? "Não tenho dados suficientes para responder isso agora."
                    : response.text
            case .requiresDiagnosis:
                return response.text.isEmpty
                    ? "Esse caso precisa de um diagnóstico mais completo."
                    : response.text
            case .unsupported:
                return "Ainda não sei responder esse tipo de pergunta."
            }
        } catch NetworkAssistError.notConfigured {
            return "O Assist ainda não está configurado neste build."
        } catch NetworkAssistError.emptyQuestion {
            return "Por favor, escreva uma pergunta."
        } catch {
            return "Não foi possível consultar o Assist agora. Tente novamente em instantes."
        }
    }
}

import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkAssist
import LinkaEntitlements

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let longText: String?
    let isUser: Bool

    init(text: String, longText: String? = nil, isUser: Bool) {
        self.text = text
        self.longText = longText
        self.isUser = isUser
    }
}

struct AssistSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var isTyping: Bool = false
    @State private var expandedMessages: Set<UUID> = []
    @State private var investigationExpanded: Bool = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var availableQuestions: [String] = [
        "Serve para uma chamada de vídeo?",
        "Como está comparado aos meus últimos testes?",
        "Minha conexão variou muito esta semana?",
        "Esse resultado está melhor ou pior que o anterior?"
    ]

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]
    /// Sinal de falha local (issue #56) que motivou a abertura do Assist —
    /// `nil` quando o Assist foi aberto a partir de um resultado bom.
    /// Chamadores atuais (`MainView`, `HistoryView`) não passam esse
    /// parâmetro ainda; o valor default preserva o comportamento existente.
    let failureSignal: NetworkAssistFailureSignal?

    private let assistProvider: any NetworkAssistProviding
    private let assistIsRemote: Bool

    /// `entitlements` é obrigatório para montar o provider padrão porque o
    /// Assist agora consulta a mesma fonte de entitlement do app
    /// (`AssistContainer.makeAssistProvider(entitlements:)`) — não pode
    /// mais ser construído sem saber o plano do usuário. Testes/previews
    /// que já injetam `assistProvider` explicitamente não precisam de
    /// `entitlements`.
    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        failureSignal: NetworkAssistFailureSignal? = nil,
        entitlements: StoreKitEntitlementProvider? = nil,
        assistProvider: (any NetworkAssistProviding)? = nil,
        assistIsRemote: Bool = AssistContainer.isRemoteAssistEnabled()
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.failureSignal = failureSignal
        if let assistProvider {
            self.assistProvider = assistProvider
        } else if let entitlements {
            self.assistProvider = AssistContainer.makeAssistProvider(entitlements: entitlements)
        } else {
            self.assistProvider = NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }
        self.assistIsRemote = assistIsRemote
    }

    /// Investigação local determinística (issue #56) — calculada só quando
    /// há `failureSignal`, direto pelo motor puro do `NetworkAssist`, sem
    /// nenhuma chamada de rede. Continua funcionando mesmo se o transport
    /// remoto do Assist estiver indisponível/não configurado, porque nunca
    /// depende dele.
    private var investigation: NetworkAssistInvestigationResult? {
        guard let failureSignal else { return nil }
        return NetworkAssistInvestigationEngine.investigate(
            NetworkAssistInvestigationInput(
                failureSignal: failureSignal,
                recentMeasurements: recentMeasurements
            )
        )
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
                        // Seção de investigação (issue #56) — só existe
                        // quando o Assist foi aberto após uma falha
                        // (`failureSignal` não-nil). Aparece assim que o
                        // usuário abre o Assist (ação sob demanda), nunca no
                        // primeiro frame da medição/erro/resultado em si.
                        // Texto curto primeiro, detalhe sob "Ver mais" —
                        // mesmo padrão de divulgação progressiva das bolhas
                        // de resposta abaixo (`bubble(for:)`, desde `534c121`).
                        if let investigation {
                            investigationSection(investigation)
                                .id("investigation")
                        }

                        ForEach(messages) { msg in
                            bubble(for: msg)
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
                                    Button(action: { submitQuestion(q) }) {
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
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func bubble(for msg: ChatMessage) -> some View {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(msg.text)
                        .font(.bodyRegular)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let long = msg.longText, expandedMessages.contains(msg.id) {
                        Text(long)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if msg.longText != nil {
                        Button(action: { toggleExpansion(for: msg) }) {
                            Text(expandedMessages.contains(msg.id) ? "Ver menos" : "Ver mais")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.brandAccentWarm)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color.brandAccentWarm.opacity(0.1))
                .cornerRadius(16)
                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private func investigationSection(_ result: NetworkAssistInvestigationResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(investigationShortText(for: result))
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if investigationExpanded {
                    Text(investigationLongText(for: result))
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button(action: { toggleInvestigationExpansion() }) {
                    Text(investigationExpanded ? "Ver menos" : "Ver mais")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.brandAccentWarm)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.brandAccentWarm.opacity(0.1))
            .cornerRadius(16)
            Spacer(minLength: 40)
        }
    }

    private func toggleInvestigationExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            investigationExpanded.toggle()
            if investigationExpanded {
                selectedDetent = .large
            }
        }
    }

    /// Copy da investigação local (issue #56) vive na UI, não no motor de
    /// regras do `NetworkAssist` — o engine devolve só dado tipado
    /// (disposição, evidência, sinais ausentes), nunca texto. Mesmo padrão
    /// de `MainView.errorTitle`/`errorMessage` mapeando `EngineFailureReason`
    /// (AGENTS.md §8): motor expõe fato, apresentação expõe linguagem.
    /// Vocabulário estritamente observacional — nunca "provedor com
    /// problema", nunca causa fora do que os sinais realmente sustentam.
    private func investigationShortText(for result: NetworkAssistInvestigationResult) -> String {
        switch result.disposition {
        case .localSignalLikely:
            return "Os sinais disponíveis apontam mais para o aparelho ou a rede local do que para algo além do seu acesso."
        case .externalSignalLikely:
            return "Os sinais disponíveis apontam mais para algo além do seu acesso do que para o aparelho ou a rede local."
        case .inconclusive:
            return "Não há sinais suficientes para dizer se o problema é do aparelho/rede local ou de algo além do seu acesso."
        }
    }

    /// Detalhe sob "Ver mais": cita exatamente a evidência usada
    /// (`result.evidenceIDs`/`result.evidence`) e declara o que falta
    /// (`result.missingSignals`) — a lista de sinais ausentes limita
    /// literalmente o que este texto tem base para afirmar.
    private func investigationLongText(for result: NetworkAssistInvestigationResult) -> String {
        var parts: [String] = [investigationEvidenceSummary(for: result)]
        if !result.missingSignals.isEmpty {
            let missing = result.missingSignals
                .map(investigationMissingSignalLabel)
                .joined(separator: ", ")
            parts.append("Não temos: \(missing).")
        }
        return parts.joined(separator: " ")
    }

    private func investigationEvidenceSummary(for result: NetworkAssistInvestigationResult) -> String {
        guard !result.evidence.isEmpty else {
            return "Baseado apenas no que sabemos até agora."
        }
        let descriptions = result.evidence.map(investigationEvidenceLabel)
        return "Baseado em: " + descriptions.joined(separator: "; ") + "."
    }

    private func investigationEvidenceLabel(_ evidence: NetworkAssistEvidence) -> String {
        switch evidence.metricKey {
        case "failureSignal":
            return evidence.direction == "offline"
                ? "nenhuma rede foi detectada antes de iniciar o teste"
                : "a conexão foi perdida durante a medição"
        case "recentOutcomeStability":
            return evidence.direction == "stable"
                ? "seus testes recentes completaram normalmente"
                : "seus testes recentes também ficaram incompletos"
        case "connectionKind":
            return "seus testes recentes usaram principalmente \(evidence.direction ?? "conexão desconhecida")"
        case "wifiBandGHz":
            return "a banda de Wi-Fi recente observada"
        case "loadedLatencyMs":
            return "a latência sob carga recente"
        default:
            return "dado medido recente"
        }
    }

    private func investigationMissingSignalLabel(_ signal: NetworkAssistInvestigationMissingSignal) -> String {
        switch signal {
        case .failureContext:
            return "detalhe da falha"
        case .recentMeasurementHistory:
            return "histórico recente de testes"
        case .alternateNetworkSample:
            return "um teste em outra rede"
        case .connectionKind:
            return "o tipo de conexão"
        case .wifiBandGHz:
            return "a banda do Wi-Fi"
        case .loadedLatencyBaseline:
            return "a latência sob carga recente"
        }
    }

    private func toggleExpansion(for msg: ChatMessage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedMessages.contains(msg.id) {
                expandedMessages.remove(msg.id)
            } else {
                expandedMessages.insert(msg.id)
                selectedDetent = .large
            }
        }
    }

    private func submitQuestion(_ q: String) {
        if let index = availableQuestions.firstIndex(of: q) {
            availableQuestions.remove(at: index)
        }
        messages.append(ChatMessage(text: q, isUser: true))
        isTyping = true

        Task {
            let (short, long) = await answer(for: q)
            await MainActor.run {
                self.isTyping = false
                self.messages.append(ChatMessage(text: short, longText: long, isUser: false))
            }
        }
    }

    private func answer(for question: String) async -> (String, String?) {
        guard let currentMeasurement else {
            return ("Ainda não há medições suficientes para responder. Faça seu primeiro teste.", nil)
        }
        guard assistIsRemote else {
            return ("O Assist ainda não está configurado neste build.", nil)
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
                return (response.text, response.longText)
            case .insufficientEvidence:
                let text = response.text.isEmpty
                    ? "Não tenho dados suficientes para responder isso agora."
                    : response.text
                return (text, response.longText)
            case .requiresDiagnosis:
                let text = response.text.isEmpty
                    ? "Esse caso precisa de um diagnóstico mais completo."
                    : response.text
                return (text, response.longText)
            case .unsupported:
                return ("Ainda não sei responder esse tipo de pergunta.", nil)
            }
        } catch NetworkAssistError.notConfigured {
            return ("O Assist ainda não está configurado neste build.", nil)
        } catch NetworkAssistError.emptyQuestion {
            return ("Por favor, escreva uma pergunta.", nil)
        } catch {
            return ("Não foi possível consultar o Assist agora. Tente novamente em instantes.", nil)
        }
    }
}

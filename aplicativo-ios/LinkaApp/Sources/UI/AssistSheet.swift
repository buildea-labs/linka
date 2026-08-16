import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkAssist
import LinkaEntitlements

struct ChatMessage: Identifiable {
    let id = UUID()
    /// `var` (não `let`): a bolha do assistente é atualizada in-place
    /// conforme `.textDelta` chega e finalizada por `.completed` (issue
    /// #69) — sem isso, cada chunk precisaria remover/reinserir a mensagem
    /// no array só para mudar o texto.
    var text: String
    var longText: String?
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
    /// `Task` do stream de resposta em andamento (issue #69) — guardada
    /// para poder cancelar de verdade quando uma nova pergunta é enviada
    /// ou o sheet é fechado, em vez de só parar de atualizar a UI.
    @State private var streamTask: Task<Void, Never>?
    /// `id` da `ChatMessage` sendo construída via `.textDelta` — `nil`
    /// quando nenhuma resposta está em streaming no momento (inclusive
    /// durante todo o bridge não-streaming, já que ele nunca emite
    /// `.textDelta`). Também usado para esconder a bolha parcial da
    /// acessibilidade enquanto ela ainda está sendo montada.
    @State private var streamingMessageID: UUID?
    /// Etapa sinalizada pelo transporte via `.progress` — só existe quando
    /// o transporte real emite o evento; nunca inferida client-side.
    @State private var progressStep: NetworkAssistProgressStep?
    /// Alterna a opacidade do indicador discreto pré-primeiro-trecho.
    @State private var progressPulse: Bool = false
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
    /// Dispara uma nova medição pelo caminho de início de teste já
    /// existente do chamador — `nil` quando o chamador não tem esse
    /// caminho disponível no contexto atual (ex.: `HistoryView`, que só
    /// olha medições passadas). A sugestão `.retryMeasurement` (issue #58)
    /// só é calculada/exibida quando este closure existe (ver `body`);
    /// sem ele, o botão nunca aparece, em vez de aparecer e falhar
    /// silenciosamente.
    let onRetry: (() -> Void)?

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
        onRetry: (() -> Void)? = nil,
        entitlements: StoreKitEntitlementProvider? = nil,
        assistProvider: (any NetworkAssistProviding)? = nil,
        assistIsRemote: Bool = AssistContainer.isRemoteAssistEnabled()
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.failureSignal = failureSignal
        self.onRetry = onRetry
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

    /// Próxima ação sugerida (issue #58), calculada a partir da mesma
    /// `investigation` acima — nunca aparece sem gatilho objetivo vindo
    /// dela (`AssistContainer.suggestedAction` devolve `nil` quando não há
    /// evidência suficiente). `.retryMeasurement` é descartado quando
    /// `onRetry` não foi injetado: sem caminho de reteste disponível no
    /// contexto atual, a UI não calcula nem mostra o botão, em vez de
    /// mostrar algo que não pode executar (ver nota do init/`onRetry`).
    private var suggestedAction: NetworkAssistActionSuggestion? {
        let suggestion = AssistContainer.suggestedAction(for: investigation)
        if case .retryMeasurement = suggestion, onRetry == nil {
            return nil
        }
        return suggestion
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

                            // Botão secundário de próxima ação (issue #58) —
                            // sempre abaixo da seção de investigação, nunca
                            // a substitui nem compete com ela. Só existe
                            // quando `suggestedAction` tem gatilho objetivo;
                            // sem sugestão, esta view nem aparece.
                            if let suggestedAction {
                                actionSuggestionSection(suggestedAction)
                                    .id("suggestedAction")
                            }
                        }

                        ForEach(messages) { msg in
                            bubble(for: msg)
                                .id(msg.id)
                        }

                        if isTyping {
                            assistProgressIndicator
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
                // Acompanha a bolha crescendo chunk a chunk (issue #69):
                // `.textDelta` muda o texto da última mensagem sem mudar
                // `messages.count`, então o `onChange` acima não dispara.
                .onChange(of: messages.last?.text) { _ in
                    guard let streamingMessageID else { return }
                    withAnimation { proxy.scrollTo(streamingMessageID, anchor: .bottom) }
                }
            }
        }
        .background(Color.surfacePage)
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        // Cancela de verdade o stream em andamento (não só para de
        // consumir client-side) quando o sheet é fechado — issue #69,
        // requisito de aceite de cancelamento.
        .onDisappear {
            streamTask?.cancel()
        }
    }

    /// Indicador antes do primeiro trecho da resposta (issue #69):
    /// deliberadamente mínimo e neutro — um único ponto respirando
    /// devagar, sem rótulo "Pensando…" e sem a bolinha tripla saltitante
    /// de chat genérico (não-objetivo explícito da issue). Uma mensagem de
    /// etapa (`.progress`) só substitui/acompanha o ponto quando o
    /// transporte de fato sinaliza aquela etapa — nunca por adivinhação
    /// client-side.
    private var assistProgressIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.textSecondary)
                .frame(width: 6, height: 6)
                .opacity(progressPulse ? 0.65 : 0.25)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        progressPulse.toggle()
                    }
                }
            if let progressStep {
                Text(progressStepLabel(for: progressStep))
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(progressStep.map { progressStepLabel(for: $0) } ?? "Preparando resposta")
    }

    /// Copy da etapa vive na UI, não no motor (`NetworkAssist` só expõe o
    /// enum tipado) — mesmo padrão de `investigationShortText` abaixo.
    private func progressStepLabel(for step: NetworkAssistProgressStep) -> String {
        switch step {
        case .readingMeasurement:
            return "Lendo seu teste…"
        case .comparingHistory:
            return "Comparando com o histórico…"
        case .composingAnswer:
            return "Preparando a resposta…"
        }
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
                // VoiceOver não deve anunciar cada `.textDelta` isolado
                // (issue #69): enquanto esta é a bolha sendo streamada,
                // ela fica fora da árvore de acessibilidade; assim que
                // `.completed` chega (`streamingMessageID` volta a `nil`),
                // volta a ser lida normalmente — leitura coerente com o
                // texto final, nunca fragmento a fragmento.
                .accessibilityHidden(msg.id == streamingMessageID)
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

    /// Botão secundário de próxima ação (issue #58) — sempre abaixo de
    /// `investigationSection`, nunca no lugar dela. `.retryMeasurement` e
    /// `.openAppSettings` viram botão (com a confirmação do próprio
    /// sistema no caso de Ajustes, via `.open`); `.manualGuidance` vira
    /// só uma lista curta de passos em texto — sem botão que prometa
    /// automação que não existe (AGENTS.md §9, requisito de aceite #58).
    @ViewBuilder
    private func actionSuggestionSection(_ suggestion: NetworkAssistActionSuggestion) -> some View {
        switch suggestion {
        case .retryMeasurement, .openAppSettings:
            HStack {
                Button(action: { performActionSuggestion(suggestion) }) {
                    HStack(spacing: 6) {
                        Text(actionSuggestionLabel(for: suggestion))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Image(systemName: actionSuggestionSymbol(for: suggestion))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.textPrimary.opacity(0.04))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        case .manualGuidance(let topic):
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(actionSuggestionManualGuidanceTitle(for: topic))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    ForEach(Array(actionSuggestionManualGuidanceSteps(for: topic).enumerated()), id: \.offset) { _, step in
                        Text("• \(step)")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 4)
                Spacer(minLength: 40)
            }
        }
    }

    /// Executa a sugestão. `.openAppSettings` delega a
    /// `AssistContainer.openAppSettings()` (a única API pública que existe
    /// para isso — AGENTS.md §9); `.retryMeasurement` delega ao closure do
    /// chamador, nunca dispara uma medição diretamente (AssistSheet não
    /// duplica o caminho de início de teste). `.manualGuidance` nunca
    /// chega aqui — não tem botão associado.
    private func performActionSuggestion(_ suggestion: NetworkAssistActionSuggestion) {
        switch suggestion {
        case .retryMeasurement:
            onRetry?()
            dismiss()
        case .openAppSettings:
            AssistContainer.openAppSettings()
        case .manualGuidance:
            break
        }
    }

    /// Copy do botão de ação vive na UI, mesmo padrão de
    /// `investigationShortText`/`investigationLongText`: o motor
    /// (`NetworkAssistActionEngine`) só expõe o tipo de sugestão, nunca
    /// texto (AGENTS.md §8).
    private func actionSuggestionLabel(for suggestion: NetworkAssistActionSuggestion) -> String {
        switch suggestion {
        case .retryMeasurement:
            return "Testar novamente"
        case .openAppSettings:
            return "Abrir Ajustes do app"
        case .manualGuidance:
            return ""
        }
    }

    private func actionSuggestionSymbol(for suggestion: NetworkAssistActionSuggestion) -> String {
        switch suggestion {
        case .retryMeasurement:
            return "arrow.clockwise"
        case .openAppSettings:
            return "gear"
        case .manualGuidance:
            return ""
        }
    }

    /// Título curto do guia manual. Deixa explícito que é orientação em
    /// texto, sem prometer um botão que abra a tela diretamente — não
    /// existe API pública da Apple para isso (requisito de aceite #58).
    private func actionSuggestionManualGuidanceTitle(for topic: NetworkAssistManualGuidanceTopic) -> String {
        switch topic {
        case .wifiConnectivity:
            return "Passos para verificar manualmente:"
        case .dnsConnectivity:
            return "Passos para verificar o DNS manualmente:"
        }
    }

    /// Passos considerando diferença de plataforma (iPhone/iPad vs. Mac,
    /// requisito de aceite #58) — Ajustes Rápidos existe só no
    /// iPhone/iPad; no Mac a Central de Controle/menu de Wi-Fi na barra de
    /// menus é o caminho equivalente.
    private func actionSuggestionManualGuidanceSteps(for topic: NetworkAssistManualGuidanceTopic) -> [String] {
        switch topic {
        case .wifiConnectivity:
            #if os(macOS)
            return [
                "Verifique o ícone de Wi-Fi na barra de menus e confirme que está conectado à rede certa.",
                "Confirme se os dados móveis (quando aplicável) estão ativos.",
                "Depois de checar, teste novamente."
            ]
            #else
            return [
                "Abra a Central de Controle e confirme que o Wi-Fi está ativado e conectado à rede certa.",
                "Confirme se os Dados Móveis estão ativados e o Modo Avião está desligado.",
                "Depois de checar, teste novamente."
            ]
            #endif
        case .dnsConnectivity:
            return [
                "Em Ajustes > Wi-Fi, toque na rede conectada e confira a configuração de DNS.",
                "Se o DNS foi configurado manualmente, tente voltar para \"Automático\".",
                "Depois de checar, teste novamente."
            ]
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

    /// Envia a pergunta. Os dois casos sem `currentMeasurement`/com Assist
    /// desligado são caminhos locais/instantâneos (guard clauses, issue
    /// #69): a resposta já existe por completo antes de qualquer
    /// round-trip, então revela de uma vez e nunca passa pela máquina de
    /// streaming — não fingir "pensamento" sobre algo que já está pronto.
    /// Só quando há de fato uma pergunta a consultar é que
    /// `consumeAssistStream` (via `streamAnswer`) entra em cena.
    private func submitQuestion(_ q: String) {
        streamTask?.cancel()
        streamTask = nil
        streamingMessageID = nil
        progressStep = nil

        if let index = availableQuestions.firstIndex(of: q) {
            availableQuestions.remove(at: index)
        }
        messages.append(ChatMessage(text: q, isUser: true))

        guard let currentMeasurement else {
            isTyping = false
            messages.append(ChatMessage(
                text: "Ainda não há medições suficientes para responder. Faça seu primeiro teste.",
                isUser: false
            ))
            return
        }
        guard assistIsRemote else {
            isTyping = false
            messages.append(ChatMessage(
                text: "O Assist ainda não está configurado neste build.",
                isUser: false
            ))
            return
        }

        isTyping = true

        let context = NetworkAssistContext(
            question: q,
            currentMeasurement: currentMeasurement,
            recentMeasurements: recentMeasurements,
            evidence: [],
            locale: "pt-BR"
        )

        streamTask = Task { @MainActor in
            await consumeAssistStream(for: context)
        }
    }

    /// Consome `assistProvider.streamAnswer(_:)` (issue #69) — único
    /// call-site independente de o provider por baixo saber streamar de
    /// verdade ou não: `.textDelta` acumula na bolha em construção,
    /// `.progress` atualiza o indicador só quando o transporte de fato
    /// sinaliza aquela etapa, e `.completed` finaliza. Contra o bridge
    /// não-streaming de hoje (`SignallqAiDiagnosticTransport`), isto se
    /// reduz a um único `.completed` — a resposta aparece de uma vez,
    /// porque já chegou inteira.
    @MainActor
    private func consumeAssistStream(for context: NetworkAssistContext) async {
        do {
            for try await event in assistProvider.streamAnswer(context) {
                switch event {
                case .progress(let step):
                    withAnimation(.easeInOut(duration: 0.2)) {
                        progressStep = step
                    }
                case .textDelta(let delta):
                    appendStreamedDelta(delta)
                case .completed(let response):
                    finishStream(with: response)
                }
            }
        } catch {
            handleStreamFailure(error)
        }
        isTyping = false
        progressStep = nil
        streamingMessageID = nil
    }

    /// O primeiro `.textDelta` cria a bolha do assistente (e esconde o
    /// indicador pré-primeiro-trecho, já que agora há conteúdo real para
    /// mostrar); deltas seguintes só se acumulam nela, sem nenhum delay
    /// artificial entre chunks — coalescing/throttle de chunks reais que
    /// chegam granulares demais é legítimo, atraso decorativo sobre texto
    /// já recebido não é (não-objetivo explícito da issue #69).
    @MainActor
    private func appendStreamedDelta(_ delta: String) {
        guard !delta.isEmpty else { return }
        if let id = streamingMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text += delta
        } else {
            let message = ChatMessage(text: delta, isUser: false)
            streamingMessageID = message.id
            messages.append(message)
            isTyping = false
            progressStep = nil
        }
    }

    /// `.completed` carrega o texto final já validado/normalizado por
    /// `NetworkAssistService` — é a fonte da verdade, então sobrescreve
    /// (não concatena sobre) qualquer acúmulo de `.textDelta` anterior.
    /// Quando não houve nenhum `.textDelta` antes (bridge não-streaming,
    /// 100% do tráfego real hoje), esta é a primeira e única vez que o
    /// texto aparece — de uma vez.
    @MainActor
    private func finishStream(with response: NetworkAssistResponse) {
        let (short, long) = presentableText(for: response)
        if let id = streamingMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text = short
            messages[index].longText = long
        } else {
            messages.append(ChatMessage(text: short, longText: long, isUser: false))
        }
    }

    /// Mesmo mapeamento de disposição→texto de antes de #69 (issue #53).
    private func presentableText(for response: NetworkAssistResponse) -> (String, String?) {
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
    }

    /// Erro no meio do stream recebe o mesmo mapeamento humano/PT-BR de
    /// antes de #69. Cancelamento deliberado (nova pergunta enviada,
    /// dismiss do sheet) não é um erro para o usuário: some
    /// silenciosamente, removendo a bolha parcial em vez de deixá-la
    /// quebrada pela metade.
    @MainActor
    private func handleStreamFailure(_ error: Error) {
        if error is CancellationError {
            removeStreamingMessageIfPartial()
            return
        }

        let text: String
        switch error {
        case NetworkAssistError.notConfigured:
            text = "O Assist ainda não está configurado neste build."
        case NetworkAssistError.emptyQuestion:
            text = "Por favor, escreva uma pergunta."
        default:
            text = "Não foi possível consultar o Assist agora. Tente novamente em instantes."
        }

        if let id = streamingMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text = text
            messages[index].longText = nil
        } else {
            messages.append(ChatMessage(text: text, isUser: false))
        }
    }

    private func removeStreamingMessageIfPartial() {
        guard let id = streamingMessageID,
              let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages.remove(at: index)
    }
}

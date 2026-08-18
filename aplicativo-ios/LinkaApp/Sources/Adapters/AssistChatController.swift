import Foundation
import NetworkCore
import NetworkAssist

/// Estado e máquina de streaming da conversa do Assist (issue #69,
/// extraído de `AssistSheet` no PR #101 R2). `ObservableObject` — não
/// `View`/`@State` — de propósito: `@State` só é garantido de persistir
/// mutações quando a `View` dona está instalada na hierarquia real do
/// SwiftUI (renderizada de verdade); um `AssistSheet` construído
/// diretamente num teste unitário, sem simulador/host de UI, NUNCA
/// instala esse grafo, e mutações em `@State` silenciosamente não
/// persistem nesse cenário (confirmado empiricamente durante a R2 do PR
/// #101 — um `@State var counter` incrementado num teste desse tipo lia
/// de volta o valor inicial pra sempre). `AssistChatController`, sendo
/// uma classe comum com `@Published`, não tem essa exigência — é
/// testável do mesmo jeito que `SpeedTestViewModel` (issue #65): construa
/// diretamente e chame os métodos, sem UI real nem simulador.
///
/// `AssistSheet` mantém tudo que NÃO é streaming/mensagem (investigação,
/// sugestão de ação, expansão de "Ver mais", `PresentationDetent`) —
/// esta classe é só o pedaço que a R2 precisa cobrir com teste
/// automatizado: enfileiramento de pergunta, consumo do stream,
/// cancelamento e a guarda por geração.
@MainActor
final class AssistChatController: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    /// `id` da `ChatMessage` sendo construída via `.textDelta` — `nil`
    /// quando nenhuma resposta está em streaming no momento (inclusive
    /// durante todo o bridge não-streaming, já que ele nunca emite
    /// `.textDelta`). Também usado por `AssistSheet` para esconder a
    /// bolha parcial da acessibilidade enquanto ela ainda está sendo
    /// montada.
    @Published var streamingMessageID: UUID?
    /// Etapa sinalizada pelo transporte via `.progress` — só existe
    /// quando o transporte real emite o evento; nunca inferida
    /// client-side.
    @Published var progressStep: NetworkAssistProgressStep?
    @Published var availableQuestions: [String] = [
        "Serve para uma chamada de vídeo?",
        "Como está comparado aos meus últimos testes?",
        "Minha conexão variou muito esta semana?",
        "Esse resultado está melhor ou pior que o anterior?"
    ]

    private let currentMeasurement: NetworkMeasurement?
    private let recentMeasurements: [NetworkMeasurement]
    private let assistProvider: any NetworkAssistProviding
    private let assistIsRemote: Bool

    /// `Task` do stream de resposta em andamento (issue #69) — guardada
    /// para poder cancelar de verdade quando uma nova pergunta é enviada
    /// ou o sheet é fechado, em vez de só parar de atualizar a UI.
    private var streamTask: Task<Void, Never>?
    /// Geração do stream em andamento (PR #101, R2 — achado de Marcelo).
    /// Incrementada sincronamente em `submitQuestion`, antes de qualquer
    /// `await`, mesmo padrão de `SpeedTestViewModel.testGeneration`
    /// (issue #47). Cada `consumeAssistStream` captura sua própria
    /// geração e só aplica o cleanup compartilhado (`isTyping`/
    /// `progressStep`/`streamingMessageID` = nil) se ainda for a geração
    /// corrente quando termina — sem isto, uma Task antiga cancelada que
    /// só percebe isso depois que a pergunta nova já está em andamento
    /// sobrescreveria o estado que a pergunta nova acabou de montar.
    private var streamGeneration: Int = 0


    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement],
        assistProvider: any NetworkAssistProviding,
        assistIsRemote: Bool
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.assistProvider = assistProvider
        self.assistIsRemote = assistIsRemote
    }

    func cancelStream() {
        streamTask?.cancel()
    }

    func submitQuestion(_ q: String) {
        streamTask?.cancel()
        streamTask = nil
        streamGeneration += 1
        let myGeneration = streamGeneration
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
            diagnosticPayload: nil,
            locale: "pt-BR"
        )

        streamTask = Task { @MainActor in
            await consumeAssistStream(for: context, generation: myGeneration)
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
    ///
    /// `generation` (PR #101, R2 — dois achados de Marcelo) é a geração
    /// que `submitQuestion` capturou no instante em que esta Task foi
    /// criada. Resolve dois problemas distintos de cancelamento:
    ///
    /// 1. **Cancelamento silencioso (BLOQUEANTE).** Quando esta Task é
    ///    cancelada (nova pergunta ou dismiss do sheet), o
    ///    `AsyncThrowingStream` por trás de `streamAnswer` checa
    ///    `Task.isCancelled` internamente e simplesmente encerra a
    ///    iteração devolvendo `nil` — o `for try await` abaixo termina
    ///    sem lançar `CancellationError`, então o `catch` nunca roda.
    ///    Por isso a checagem explícita de `Task.isCancelled` depois do
    ///    loop: sem ela, a bolha parcial desta pergunta ficava presa em
    ///    `messages` para sempre — `handleStreamFailure`/
    ///    `removePartialMessage` nunca eram chamados.
    /// 2. **Corrida por geração (ALTA, mesmo padrão do #47 no
    ///    `SpeedTestViewModel`).** Esta Task pode só perceber o próprio
    ///    cancelamento (silencioso ou via `CancellationError` lançado)
    ///    depois que `submitQuestion` já iniciou a pergunta seguinte.
    ///    Sem guarda, o cleanup incondicional de
    ///    `isTyping`/`progressStep`/`streamingMessageID` desta Task
    ///    antiga sobrescreveria o estado que a Task nova já está
    ///    construindo — por isso `finishConsuming` só mexe em estado
    ///    compartilhado quando `streamGeneration == generation` ainda é
    ///    verdade. `myMessageID` é local (não o `streamingMessageID`
    ///    compartilhado) justamente para que a bolha certa seja removida
    ///    mesmo quando o compartilhado já pertence à pergunta nova.
    private func consumeAssistStream(for context: NetworkAssistContext, generation: Int) async {
        var myMessageID: UUID?

        do {
            for try await event in assistProvider.streamAnswer(context) {
                // Uma Task antiga que só nota o próprio cancelamento no
                // próximo `await` do stream não deve mais tocar em
                // nenhum estado compartilhado — ele já pode pertencer à
                // pergunta seguinte. `continue` (não `return`): o loop
                // precisa terminar naturalmente pra sempre alcançar a
                // checagem de `Task.isCancelled`/`removePartialMessage`
                // depois dele — um `return` aqui puxaria a função pra
                // fora antes disso, deixando a bolha parcial presa se um
                // evento já bufferizado for entregue depois que a
                // geração mudou mas antes do stream notar o
                // cancelamento.
                guard streamGeneration == generation else { continue }
                switch event {
                case .progress(let step):
                    progressStep = step
                case .textDelta(let delta):
                    myMessageID = appendStreamedDelta(delta)
                case .completed(let response):
                    finishStream(with: response)
                }
            }
        } catch {
            guard streamGeneration == generation else {
                // Task antiga, já superada por uma pergunta nova: mesmo
                // não sendo cancelamento, não mostra erro nem mexe em
                // estado compartilhado — só garante que a bolha parcial
                // dela (se houver) não fique presa em `messages`.
                removePartialMessage(withID: myMessageID)
                return
            }
            if error is CancellationError {
                removePartialMessage(withID: myMessageID)
            } else {
                handleStreamFailure(error)
            }
            finishConsuming(generation: generation)
            return
        }

        // Loop terminou sem lançar: sucesso real (stream completou por
        // conta própria) OU cancelamento silencioso (caso 1 do
        // comentário acima) — só `Task.isCancelled` distingue os dois,
        // porque não há exceção pra inspecionar em nenhum dos dois casos.
        if Task.isCancelled {
            removePartialMessage(withID: myMessageID)
        }
        finishConsuming(generation: generation)
    }

    /// Cleanup compartilhado de final de stream, guardado por geração
    /// (caso 2 do comentário de `consumeAssistStream` acima). Chamado
    /// nos caminhos de sucesso, erro e cancelamento — sempre a última
    /// coisa que `consumeAssistStream` faz antes de retornar.
    private func finishConsuming(generation: Int) {
        guard streamGeneration == generation else { return }
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
    ///
    /// Devolve o `id` da bolha usada (nova ou existente) para que
    /// `consumeAssistStream` guarde sua própria referência local (PR
    /// #101, R2) — necessária para remover a bolha certa numa Task
    /// cancelada mesmo depois que `streamingMessageID` compartilhado já
    /// foi reatribuído pela pergunta seguinte.
    @discardableResult
    private func appendStreamedDelta(_ delta: String) -> UUID? {
        guard !delta.isEmpty else { return streamingMessageID }
        if let id = streamingMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text += delta
            return id
        } else {
            let message = ChatMessage(text: delta, isUser: false)
            streamingMessageID = message.id
            messages.append(message)
            isTyping = false
            progressStep = nil
            return message.id
        }
    }

    /// `.completed` carrega o texto final já validado/normalizado por
    /// `NetworkAssistService` — é a fonte da verdade, então sobrescreve
    /// (não concatena sobre) qualquer acúmulo de `.textDelta` anterior.
    /// Quando não houve nenhum `.textDelta` antes (bridge não-streaming,
    /// 100% do tráfego real hoje), esta é a primeira e única vez que o
    /// texto aparece — de uma vez.
    private func finishStream(with response: NetworkAssistResponse) {
        let (short, long) = presentableText(for: response)
        if let id = streamingMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text = short
            messages[index].longText = long
        } else {
            messages.append(ChatMessage(text: short, longText: long, isUser: false))
        }
        
        if let suggestions = response.suggestions, !suggestions.isEmpty {
            self.availableQuestions = suggestions
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
    /// dismiss do sheet) não chega mais aqui — `consumeAssistStream`
    /// intercepta `CancellationError` (e o cancelamento silencioso, via
    /// `Task.isCancelled`) antes de chamar este método (PR #101, R2);
    /// este continua sendo só o caminho de erro real pro usuário.
    private func handleStreamFailure(_ error: Error) {
        let text: String
        switch error {
        case NetworkAssistError.notConfigured:
            text = "O Assist ainda não está configurado neste build."
        case NetworkAssistError.emptyQuestion:
            text = "Por favor, escreva uma pergunta."
        case NetworkAssistError.notEntitled:
            text = "O Assist faz parte do Linka Plus. Assine para conversar sobre seus testes."
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

    /// Remove a bolha parcial de uma pergunta cancelada, dado o `id` que
    /// `consumeAssistStream` capturou localmente para ELA (PR #101, R2)
    /// — nunca o `streamingMessageID` compartilhado, que numa Task
    /// antiga já pode pertencer à pergunta seguinte (ver comentário de
    /// `consumeAssistStream`).
    private func removePartialMessage(withID id: UUID?) {
        guard let id, let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages.remove(at: index)
    }
}

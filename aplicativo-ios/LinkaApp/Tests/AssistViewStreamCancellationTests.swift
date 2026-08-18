import XCTest
import NetworkCore
import NetworkAssist
@testable import LinkaApp

/// Cobertura dos dois achados de Marcelo na R2 do PR #101 (issue #69):
///
/// 1. **BLOQUEANTE — cancelamento silencioso.** Quando `submitQuestion`
///    cancela o stream em andamento (nova pergunta ou dismiss),
///    `AsyncThrowingStream` encerra o `for try await` sem lançar
///    `CancellationError` (ver `AssistChatController.consumeAssistStream`).
///    Sem a checagem explícita de `Task.isCancelled` depois do loop, a
///    bolha parcial da pergunta cancelada ficava presa em `messages`
///    para sempre.
/// 2. **ALTA — corrida por geração.** A Task antiga só percebe o próprio
///    cancelamento depois que a pergunta nova já está em andamento; sem
///    guarda por `streamGeneration`, o cleanup dela sobrescrevia
///    `isTyping`/`streamingMessageID` da pergunta nova.
///
/// Estes testes constroem `AssistChatController` diretamente (mesma
/// abordagem de `SpeedTestViewModelScenePhaseTests`, issue #65) — é um
/// `ObservableObject` comum, não uma `View`/`@State`. Isso importa aqui
/// especificamente: `@State` só é garantido de persistir mutações quando
/// a `View` dona está instalada na hierarquia real do SwiftUI; testar a `AssistView` (a `View`) construindo-a diretamente foi tentado
/// primeiro nesta R2 e falhou de um jeito revelador — mutações em
/// `@State` (inclusive um `streamGeneration += 1` simples) não
/// persistiam entre chamadas nesse cenário, confirmado por um teste de
/// diagnóstico isolado. Por isso a máquina de streaming foi extraída
/// para `AssistChatController` nesta R2: sem isso, não havia como cobrir
/// os dois achados de Marcelo com um teste automatizado confiável.
@MainActor
final class AssistViewStreamCancellationTests: XCTestCase {

    private struct WaitTimeoutError: Error, CustomStringConvertible {
        let description: String
    }

    /// Provider de teste que expõe streaming real (não o bridge default
    /// de `NetworkAssistProviding`) — cada chamada a `streamAnswer(_:)`
    /// registra sua `continuation` por texto de pergunta, para que o
    /// teste consiga pilotar os eventos de CADA pergunta
    /// independentemente (issue #69 exige streaming de verdade, então o
    /// teste precisa simular isso, não só o bridge de round-trip único).
    private actor ScriptedStreamingAssistProvider: NetworkAssistProviding {
        typealias Continuation = AsyncThrowingStream<NetworkAssistStreamEvent, Error>.Continuation

        private var continuations: [String: Continuation] = [:]

        nonisolated func answer(_ context: NetworkAssistContext) async throws -> NetworkAssistResponse {
            NetworkAssistResponse(text: "não usado neste teste — só streamAnswer é exercitado")
        }

        nonisolated func streamAnswer(_ context: NetworkAssistContext) -> AsyncThrowingStream<NetworkAssistStreamEvent, Error> {
            AsyncThrowingStream { continuation in
                Task { await self.register(question: context.question, continuation: continuation) }
            }
        }

        private func register(question: String, continuation: Continuation) {
            continuations[question] = continuation
        }

        /// Espera até que `streamAnswer(_:)` tenha sido chamado para
        /// `question` e devolve a `continuation` correspondente, pra o
        /// teste poder emitir `.textDelta`/`.progress`/`.completed` na
        /// hora que quiser. Lança em vez de crashar se o orçamento de
        /// iterações esgotar, pra um bug real virar falha de teste
        /// normal, não queda do processo.
        func continuation(for question: String, maxYields: Int = 20_000) async throws -> Continuation {
            for _ in 0..<maxYields {
                if let c = continuations[question] { return c }
                await Task.yield()
            }
            throw WaitTimeoutError(description: "streamAnswer(_:) nunca foi chamado para a pergunta '\(question)'")
        }
    }

    private func makeMeasurement() -> NetworkMeasurement {
        NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 87.3,
            uploadMbps: 21.4,
            latencyMs: 14,
            jitterMs: 1.2,
            packetLossPercent: 0.0,
            connectionKind: .wifi,
            networkIdentifier: "Provedor Teste"
        )
    }

    /// Espera até que `condition()` seja verdadeira — necessário porque
    /// `submitQuestion`/`consumeAssistStream` fazem trabalho assíncrono
    /// real (o `Task` do stream); sem isto o teste checaria o estado
    /// antes dele convergir. Lança em vez de deixar o teste seguir com
    /// uma condição não satisfeita silenciosamente.
    private func waitUntil(
        maxYields: Int = 20_000,
        description: String,
        _ condition: () -> Bool
    ) async throws {
        for _ in 0..<maxYields {
            if condition() { return }
            await Task.yield()
        }
        throw WaitTimeoutError(description: description)
    }

    func test_cancelStream_removesPartialBubble() async throws {
        let provider = ScriptedStreamingAssistProvider()
        let chat = AssistChatController(
            currentMeasurement: makeMeasurement(),
            recentMeasurements: [],
            assistProvider: provider,
            assistIsRemote: true
        )

        chat.explain()
        let continuation = try await provider.continuation(for: "Esse resultado está bom para o que você faz?")
        continuation.yield(.textDelta("Com base no seu teste mais recente"))

        try await waitUntil(description: "bolha parcial nunca apareceu em `messages`") {
            chat.messages.contains { !$0.isUser && $0.text == "Com base no seu teste mais recente" }
        }
        guard let partialBubble = chat.messages.first(where: { !$0.isUser }) else {
            XCTFail("Bolha parcial nunca apareceu em `messages`")
            return
        }
        XCTAssertEqual(chat.streamingMessageID, partialBubble.id)

        // Cancela de verdade, fechando a view
        chat.cancelStream()

        try await waitUntil(description: "bolha parcial nunca foi removida após o cancelamento") {
            !chat.messages.contains { $0.id == partialBubble.id }
        }
        XCTAssertFalse(
            chat.messages.contains { $0.id == partialBubble.id },
            "Bolha parcial deveria ter sido removida após o cancelamento silencioso"
        )
    }
}

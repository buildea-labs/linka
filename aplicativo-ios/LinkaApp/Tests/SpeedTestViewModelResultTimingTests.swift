import XCTest
import Combine
import NetworkCore
import LinkaEngine
@testable import LinkaApp

/// Cobertura do requisito de aceite da issue #88: no instante síncrono em
/// que `uiPhase` publica `.done`, `connectionKind`/`wifiBandGHz` já
/// refletem o valor final resolvido — nenhum observador consegue capturar
/// `uiPhase == .done` com esses campos ainda `nil` por causa do teste em si.
///
/// `engine` (`SpeedTestCore`) não é injetável em `SpeedTestViewModel`, então
/// não dá pra exercitar `startTest()` fim-a-fim aqui sem rede real. Em vez
/// disso, este arquivo cobre `processResultState(_:startingKind:endingKind:
/// generation:)` — o método `internal` que `startTest()` chama, dentro do
/// loop de consumo do stream, exatamente na ordem de produção: resolve
/// connectionKind/wifiBandGHz primeiro, só depois publica o state via
/// `update(with:)` (que marca `uiPhase = .done`). Ver nota de Guinho no
/// `plano.md` da issue #88 — mesma extração mínima usada em #65 para
/// `handleScenePhaseChange`.
@MainActor
final class SpeedTestViewModelResultTimingTests: XCTestCase {

    private func resultState() -> MeasurementState {
        MeasurementState(
            ping: 14,
            jitter: 1.2,
            packetLossPercent: 0.0,
            downloadSpeed: 87.3,
            uploadSpeed: 21.4,
            progress: 1.0,
            phase: .result,
            provider: "Provedor Teste",
            networkType: "Wi-Fi",
            duration: 9.8
        )
    }

    /// Aceite #1 e #5: no exato instante em que o subscriber de `$uiPhase`
    /// observa `.done`, `connectionKind` já não é `nil` — não é uma leitura
    /// assíncrona subsequente que só por acaso encontra o valor certo
    /// depois.
    ///
    /// Não afirma `wifiBandGHz` não-nulo aqui de propósito: no iPhone (sem
    /// `CoreWLAN`) `nil` é o estado normal mesmo em Wi-Fi — ver
    /// `ApplePlatformSignalProvider.currentWifiBandGHz()`. O teste de
    /// ordenação para `wifiBandGHz` (que ele foi *reatribuído*, não deixado
    /// com um valor obsoleto) vive no teste seguinte, com um sentinela.
    func test_finalConnectionKind_resolvedBeforeUiPhasePublishesDone() {
        let viewModel = SpeedTestViewModel()
        var sawDone = false
        var connectionKindWhenDone: NetworkConnectionKind?

        let cancellable = viewModel.$uiPhase.sink { phase in
            if phase == .done {
                sawDone = true
                connectionKindWhenDone = viewModel.connectionKind
            }
        }
        defer { cancellable.cancel() }

        viewModel.processResultState(
            resultState(),
            startingKind: .wifi,
            endingKind: .wifi,
            generation: 0 // testGeneration nunca foi incrementado (init padrão)
        )

        XCTAssertTrue(sawDone, "o subscriber precisa ter observado uiPhase == .done")
        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertNotNil(connectionKindWhenDone, "connectionKind não pode estar nil no instante em que uiPhase == .done")
        XCTAssertEqual(connectionKindWhenDone, .wifi)
    }

    /// Aceite #1 e #5, complemento pra `wifiBandGHz`: mesmo quando a
    /// plataforma não confirma banda (iPhone, sem `CoreWLAN` — `nil` é
    /// estado normal), o campo precisa ter sido *reatribuído* (resolvido)
    /// antes de `uiPhase` publicar `.done`, nunca deixado com um valor
    /// obsoleto de um teste anterior. Um sentinela antes da chamada prova
    /// isso independente do valor real que a plataforma devolve.
    func test_wifiBandGHz_reassignedBeforeUiPhasePublishesDone_neverStale() {
        let viewModel = SpeedTestViewModel()
        let staleSentinel = 999.9
        viewModel.wifiBandGHz = staleSentinel
        var sawDone = false
        var wifiBandGHzWhenDone: Double?

        let cancellable = viewModel.$uiPhase.sink { phase in
            if phase == .done {
                sawDone = true
                wifiBandGHzWhenDone = viewModel.wifiBandGHz
            }
        }
        defer { cancellable.cancel() }

        viewModel.processResultState(
            resultState(),
            startingKind: .wifi,
            endingKind: .wifi,
            generation: 0
        )

        XCTAssertTrue(sawDone, "o subscriber precisa ter observado uiPhase == .done")
        XCTAssertNotEqual(
            wifiBandGHzWhenDone,
            staleSentinel,
            "wifiBandGHz precisa ter sido reatribuído (a valor real ou nil) antes de uiPhase == .done, nunca deixado com o valor obsoleto do teste anterior"
        )
    }

    /// Troca de rede no meio do teste continua produzindo `nil` (aceite #1
    /// e #2) — `NetworkConnectionKind.resolve(start:end:)` continua a única
    /// fonte que decide isso, sem lógica duplicada aqui.
    func test_networkChangedDuringTest_connectionKindStaysNil() {
        let viewModel = SpeedTestViewModel()

        viewModel.processResultState(
            resultState(),
            startingKind: .wifi,
            endingKind: .cellular,
            generation: 0
        )

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertNil(viewModel.connectionKind)
        XCTAssertNil(viewModel.wifiBandGHz)
    }

    /// Rede não-Wi-Fi nunca carrega banda (aceite #1: `nil` é resultado
    /// legítimo quando não é Wi-Fi).
    func test_cellularConnection_wifiBandGHzStaysNil() {
        let viewModel = SpeedTestViewModel()

        viewModel.processResultState(
            resultState(),
            startingKind: .cellular,
            endingKind: .cellular,
            generation: 0
        )

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertEqual(viewModel.connectionKind, .cellular)
        XCTAssertNil(viewModel.wifiBandGHz)
    }

    /// Aceite #3: a guarda por geração continua protegendo o ponto de
    /// assignment — se a geração passada não bate mais com a corrente
    /// (equivalente a um `skipOrCancel()`/novo `startTest()` que avançou
    /// `testGeneration` durante os ~100ms de amostragem final), esta
    /// execução não deve escrever `connectionKind`/`wifiBandGHz` por baixo
    /// de quem é dono deles agora — mas o state ainda é publicado via
    /// `update(with:)` (mesmo comportamento de antes desta issue).
    func test_staleGeneration_doesNotOverwriteConnectionKind() {
        let viewModel = SpeedTestViewModel()
        // Simula uma T2 já em andamento, dona de connectionKind == nil por
        // ter acabado de reiniciar o teste.
        viewModel.connectionKind = nil
        viewModel.wifiBandGHz = nil

        viewModel.processResultState(
            resultState(),
            startingKind: .wifi,
            endingKind: .wifi,
            generation: -1 // geração que nunca vai bater com testGeneration (0 por padrão)
        )

        XCTAssertNil(viewModel.connectionKind)
        XCTAssertNil(viewModel.wifiBandGHz)
    }
}

import XCTest
import SwiftUI
import NetworkCore
@testable import LinkaApp

/// Cobertura do contrato de ciclo de vida da issue #65: backgrounding
/// durante uma medição em andamento nunca deixa o motor em estado
/// indefinido, nunca mostra um resultado completo que não foi medido por
/// completo, e sempre preserva o último resultado válido da sessão.
///
/// Estes testes chamam `handleScenePhaseChange(_:)` diretamente no
/// `SpeedTestViewModel` — ele é um `ObservableObject` comum, não precisa de
/// UI real nem de simulador rodando pra exercitar a lógica de decisão
/// (ver nota de Guinho no `plano.md` da issue #65). O que eles NÃO cobrem:
/// a interação real com `SpeedTestCore` (rede real) e com o
/// `FileMeasurementHistoryRepository` (disco real) durante um cancelamento
/// em andamento — isso segue como verificação manual (ver PR desta issue),
/// não automatizada, para não depender de rede/IO real em teste unitário.
@MainActor
final class SpeedTestViewModelScenePhaseTests: XCTestCase {

    private func makeSnapshot(
        downloadSpeed: Double = 87.3
    ) -> SpeedTestViewModel.ResultSnapshot {
        SpeedTestViewModel.ResultSnapshot(
            downloadSpeed: downloadSpeed,
            uploadSpeed: 21.4,
            ping: 14,
            jitter: 1.2,
            provider: "Provedor Teste",
            networkType: "Wi-Fi",
            testDuration: "9,8s",
            packetLossPercent: 0.0,
            connectionKind: .wifi,
            wifiBandGHz: 5.0
        )
    }

    // MARK: - .background durante medição em andamento, SEM snapshot válido

    func test_background_duringDownload_withoutSnapshot_goesIdle() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true
        XCTAssertNil(viewModel.lastValidResultSnapshot)

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .idle)
        XCTAssertFalse(viewModel.isTesting)
        XCTAssertNil(viewModel.failureReason)
    }

    func test_background_duringUpload_withoutSnapshot_goesIdle() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .uploading
        viewModel.isTesting = true
        XCTAssertNil(viewModel.lastValidResultSnapshot)

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .idle)
        XCTAssertFalse(viewModel.isTesting)
    }

    func test_background_duringConnecting_withoutSnapshot_goesIdle() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .connecting
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .idle)
        XCTAssertFalse(viewModel.isTesting)
    }

    // MARK: - .background durante medição em andamento, COM snapshot válido

    func test_background_duringDownload_withSnapshot_restoresDone() {
        let viewModel = SpeedTestViewModel()
        let snapshot = makeSnapshot(downloadSpeed: 87.3)
        viewModel.lastValidResultSnapshot = snapshot
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true
        // Campos "sujos" do reteste em andamento — devem ser sobrescritos
        // pelo snapshot, nunca deixados como estavam (aceite #2: nunca um
        // `uiPhase` que sugira teste completo sem valores consistentes).
        viewModel.downloadSpeed = 3.1

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertFalse(viewModel.isTesting)
        XCTAssertEqual(viewModel.downloadSpeed, snapshot.downloadSpeed)
        XCTAssertEqual(viewModel.uploadSpeed, snapshot.uploadSpeed)
        XCTAssertEqual(viewModel.ping, snapshot.ping)
        XCTAssertEqual(viewModel.progress, 1.0)
    }

    func test_background_duringUpload_withSnapshot_restoresDone() {
        let viewModel = SpeedTestViewModel()
        let snapshot = makeSnapshot(downloadSpeed: 55.0)
        viewModel.lastValidResultSnapshot = snapshot
        viewModel.uiPhase = .uploading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertFalse(viewModel.isTesting)
        XCTAssertEqual(viewModel.downloadSpeed, snapshot.downloadSpeed)
    }

    // MARK: - .background em estado terminal (.done/.error) não mexe em nada

    func test_background_whileDone_doesNothing() {
        let viewModel = SpeedTestViewModel()
        let snapshot = makeSnapshot()
        viewModel.lastValidResultSnapshot = snapshot
        viewModel.uiPhase = .done
        viewModel.isTesting = false
        viewModel.downloadSpeed = snapshot.downloadSpeed

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertEqual(viewModel.downloadSpeed, snapshot.downloadSpeed)
    }

    func test_background_whileError_doesNothing() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .error
        viewModel.isTesting = false

        viewModel.handleScenePhaseChange(.background)

        XCTAssertEqual(viewModel.uiPhase, .error)
    }

    // MARK: - .inactive isolado (blip transitório) nunca cancela nada

    func test_inactive_duringDownload_doesNotCancel() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.inactive)

        XCTAssertEqual(viewModel.uiPhase, .downloading)
        XCTAssertTrue(viewModel.isTesting)
    }

    func test_inactive_duringUpload_doesNotCancel() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .uploading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.inactive)

        XCTAssertEqual(viewModel.uiPhase, .uploading)
        XCTAssertTrue(viewModel.isTesting)
    }

    /// Sequência realista de um blip transitório (permission prompt, ad
    /// interstitial, share sheet): `.active` → `.inactive` → `.active`,
    /// sem nunca passar por `.background`. Nada deve mudar.
    func test_inactiveThenActive_withoutBackground_isNoOp() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.inactive)
        viewModel.handleScenePhaseChange(.active)

        XCTAssertEqual(viewModel.uiPhase, .downloading)
        XCTAssertTrue(viewModel.isTesting)
    }

    // MARK: - Retorno a .active nunca inicia uma medição sozinho

    func test_active_afterIdleFromBackground_staysReadyForExplicitTest() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.background)
        XCTAssertEqual(viewModel.uiPhase, .idle)

        viewModel.handleScenePhaseChange(.active)

        XCTAssertEqual(viewModel.uiPhase, .idle)
        XCTAssertFalse(viewModel.isTesting)
    }

    /// Retorno a `.active` quando o resultado já foi restaurado (`.done`)
    /// NÃO deve reiniciar sozinho — só o branch "sem snapshot" (`.idle`)
    /// reinicia automaticamente.
    func test_active_afterDoneFromBackground_doesNotRestart() {
        let viewModel = SpeedTestViewModel()
        let snapshot = makeSnapshot()
        viewModel.lastValidResultSnapshot = snapshot
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true

        viewModel.handleScenePhaseChange(.background)
        XCTAssertEqual(viewModel.uiPhase, .done)

        viewModel.handleScenePhaseChange(.active)

        XCTAssertEqual(viewModel.uiPhase, .done)
        XCTAssertFalse(viewModel.isTesting)
    }

    func test_connectionChange_discardsPartialMeasurementAndRequiresExplicitNewTest() {
        let viewModel = SpeedTestViewModel()
        viewModel.uiPhase = .downloading
        viewModel.isTesting = true
        viewModel.downloadSpeed = 87.3
        viewModel.uploadSpeed = 21.4
        viewModel.progress = 0.6

        viewModel.cancelForConnectionChange()

        XCTAssertEqual(viewModel.uiPhase, .connectionChanged)
        XCTAssertFalse(viewModel.isTesting)
        XCTAssertEqual(viewModel.progress, 0)
        XCTAssertEqual(viewModel.downloadSpeed, 0)
        XCTAssertEqual(viewModel.uploadSpeed, 0)
        XCTAssertNil(viewModel.latestFinishedMeasurement)
    }
}

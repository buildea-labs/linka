import XCTest
@testable import LinkaEngine

/// Cobre o enriquecimento de provedor desacoplado (issue #64):
/// - sucesso normaliza e retorna o nome comercial;
/// - falha do lookup nunca produz "Desconhecido", só `nil`;
/// - timeout dedicado vence uma consulta lenta sem esperar por ela.
///
/// As fases de ping/download/upload de `SpeedTestCore.runTest()` batem em
/// endpoints reais (Cloudflare) por 18s+18s e não têm ponto de injeção hoje
/// (fora de escopo desta issue — ver AGENTS.md §8 e não-objetivo do plano).
/// Por isso os testes exercitam diretamente `resolveProviderName(lookup:timeout:)`,
/// que é a peça introduzida/alterada por esta issue e concentra toda a lógica
/// de corrida entre consulta e timeout.
final class SpeedTestCoreTests: XCTestCase {

    private struct StubLookupError: Error {}

    private struct StubOrgLookup: ProviderOrgLookup {
        enum Behavior {
            /// Responde imediatamente com o `org` bruto (ou nil, simulando resposta sem o campo).
            case success(String?)
            /// Lança um erro imediatamente.
            case failure(Error)
            /// Demora `delay` segundos antes de responder — usado para testar timeout.
            case hang(delay: TimeInterval, thenReturns: String?)
        }

        let behavior: Behavior

        func fetchOrg() async throws -> String? {
            switch behavior {
            case .success(let org):
                return org
            case .failure(let error):
                throw error
            case .hang(let delay, let org):
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return org
            }
        }
    }

    // MARK: - Sucesso

    func test_resolveProviderName_success_returnsNormalizedCommercialName() async {
        let lookup = StubOrgLookup(behavior: .success("AS27699 TELEFÔNICA BRASIL S.A"))

        let result = await SpeedTestCore.resolveProviderName(lookup: lookup, timeout: 2.0)

        XCTAssertEqual(result, "Vivo")
    }

    func test_resolveProviderName_success_doesNotWaitForTimeoutWindow() async {
        let lookup = StubOrgLookup(behavior: .success("AS7922 COMCAST-7922"))
        let start = Date()

        let result = await SpeedTestCore.resolveProviderName(lookup: lookup, timeout: 2.0)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(result, "Xfinity")
        // Resposta rápida não deve ficar presa esperando o timeout de 2s inteiro.
        XCTAssertLessThan(elapsed, 1.0)
    }

    func test_resolveProviderName_missingOrgField_returnsNil() async {
        let lookup = StubOrgLookup(behavior: .success(nil))

        let result = await SpeedTestCore.resolveProviderName(lookup: lookup, timeout: 2.0)

        XCTAssertNil(result)
    }

    // MARK: - Falha

    func test_resolveProviderName_lookupThrows_returnsNilNeverDesconhecido() async {
        let lookup = StubOrgLookup(behavior: .failure(StubLookupError()))

        let result = await SpeedTestCore.resolveProviderName(lookup: lookup, timeout: 2.0)

        XCTAssertNil(result)
        XCTAssertNotEqual(result, "Desconhecido")
    }

    // MARK: - Timeout

    func test_resolveProviderName_timeout_winsOverSlowLookupAndReturnsNil() async {
        // Lookup deliberadamente mais lento que o timeout dedicado.
        let lookup = StubOrgLookup(behavior: .hang(delay: 5.0, thenReturns: "AS27699 TELEFÔNICA BRASIL S.A"))
        let start = Date()

        let result = await SpeedTestCore.resolveProviderName(lookup: lookup, timeout: 0.2)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertNil(result)
        // Deve retornar próximo do timeout dedicado (0.2s), não esperar o hang de 5s.
        XCTAssertLessThan(elapsed, 2.0)
    }

}

/// Cobre o critério de convergência de vazão adaptativa por fase (issue #62):
/// `hasConverged` e `shouldStopPhase` são `nonisolated static` — puras, sem
/// `Date()` ao vivo nem `URLSession` — então exercitáveis com arrays
/// sintéticos de amostras mbps, sem bater em rede real.
final class SpeedTestCorePhaseStabilityTests: XCTestCase {

    // MARK: - hasConverged

    func test_hasConverged_stableSamples_returnsTrue() {
        // Últimas 5 amostras bem próximas (variação < 8%) — vazão estabilizou.
        let samples: [Double] = [40.0, 95.0, 98.0, 100.0, 99.0, 101.0, 100.0]

        XCTAssertTrue(SpeedTestCore.hasConverged(samples: samples))
    }

    func test_hasConverged_stillRamping_returnsFalse() {
        // Vazão claramente ainda subindo — sem plateau nas últimas amostras.
        let samples: [Double] = [10.0, 20.0, 35.0, 50.0, 70.0, 90.0, 110.0]

        XCTAssertFalse(SpeedTestCore.hasConverged(samples: samples))
    }

    func test_hasConverged_noisyUnstableSamples_returnsFalse() {
        // Conexão instável — grandes variações entre amostras consecutivas,
        // nunca assenta num plateau.
        let samples: [Double] = [50.0, 120.0, 30.0, 140.0, 20.0, 150.0, 25.0]

        XCTAssertFalse(SpeedTestCore.hasConverged(samples: samples))
    }

    func test_hasConverged_notEnoughSamplesYet_returnsFalse() {
        // Menos amostras do que a janela padrão (5) — não há dado suficiente
        // ainda para decidir estabilidade, mesmo que os valores sejam iguais.
        let samples: [Double] = [100.0, 100.0, 100.0]

        XCTAssertFalse(SpeedTestCore.hasConverged(samples: samples))
    }

    func test_hasConverged_ignoresLeadingZeroSamples() {
        // Zeros no início representam ausência de dado na janela (não vazão
        // real, ver `runPhaseTimeBased`) e não devem contar para o tamanho
        // da janela nem distorcer a média.
        let samples: [Double] = [0.0, 0.0, 100.0, 99.0, 101.0, 100.0, 100.0]

        XCTAssertTrue(SpeedTestCore.hasConverged(samples: samples))
    }

    // MARK: - shouldStopPhase

    func test_shouldStopPhase_convergesEarly_stopsAfterMinDuration() {
        let stableSamples: [Double] = [40.0, 95.0, 98.0, 100.0, 99.0, 101.0, 100.0]

        let result = SpeedTestCore.shouldStopPhase(
            samples: stableSamples,
            elapsed: 7.0,
            minDuration: 6.0,
            maxDuration: 18.0
        )

        XCTAssertTrue(result)
    }

    func test_shouldStopPhase_staysUnstable_doesNotStopBeforeMaxDuration() {
        let noisySamples: [Double] = [50.0, 120.0, 30.0, 140.0, 20.0, 150.0, 25.0]

        let result = SpeedTestCore.shouldStopPhase(
            samples: noisySamples,
            elapsed: 12.0,
            minDuration: 6.0,
            maxDuration: 18.0
        )

        XCTAssertFalse(result)
    }

    func test_shouldStopPhase_respectsMinDuration_evenWithApparentConvergence() {
        // Amostras perfeitamente estáveis, mas `elapsed` ainda não alcançou
        // `minDuration` — não deve encerrar cedo demais (evita convergência
        // espúria por poucas amostras durante o warmup TCP/TLS).
        let stableSamples: [Double] = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0]

        let result = SpeedTestCore.shouldStopPhase(
            samples: stableSamples,
            elapsed: 3.0,
            minDuration: 6.0,
            maxDuration: 18.0
        )

        XCTAssertFalse(result)
    }

    func test_shouldStopPhase_respectsMaxDuration_evenWithoutConvergence() {
        // Amostras nunca convergem, mas `elapsed` já alcançou `maxDuration`
        // — o teto sempre vence, preservando o pior caso de tempo/consumo de
        // dados do comportamento anterior (18s fixos).
        let noisySamples: [Double] = [50.0, 120.0, 30.0, 140.0, 20.0, 150.0, 25.0]

        let result = SpeedTestCore.shouldStopPhase(
            samples: noisySamples,
            elapsed: 18.0,
            minDuration: 6.0,
            maxDuration: 18.0
        )

        XCTAssertTrue(result)
    }

    func test_shouldStopPhase_beforeMinAndMax_neverStopsRegardlessOfSamples() {
        let anySamples: [Double] = [10.0, 200.0, 5.0]

        let result = SpeedTestCore.shouldStopPhase(
            samples: anySamples,
            elapsed: 1.0,
            minDuration: 6.0,
            maxDuration: 18.0
        )

        XCTAssertFalse(result)
    }

}

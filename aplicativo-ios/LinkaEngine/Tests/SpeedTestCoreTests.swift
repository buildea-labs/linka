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

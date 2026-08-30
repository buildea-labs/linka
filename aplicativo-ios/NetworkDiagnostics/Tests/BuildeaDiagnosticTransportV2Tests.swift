import XCTest
@testable import NetworkDiagnostics
import NetworkAssist
import NetworkCore

/// Cobertura do parsing do contrato v2 (`raw`+`explanation`) dentro de
/// `BuildeaDiagnosticTransport.answer(_:)` — mapeamento
/// titulo/descricao/dados/acao_usuario → title/summary/recommendation, o
/// caminho `sem_causa_identificada`, e regressão do formato v1 puro.
final class BuildeaDiagnosticTransportV2Tests: XCTestCase {
    /// `NetworkAssistRequest.init(validated:)` é `internal` ao pacote
    /// `NetworkAssist` — este teste vive em `NetworkDiagnostics`, então
    /// monta o mesmo valor via `Codable` (todos os campos são públicos e
    /// `Codable`), sem depender de um initializer não exposto.
    private func makeRequest(objective: String? = nil, subcategory: String? = nil) throws -> NetworkAssistRequest {
        let measurement = NetworkMeasurement(
            id: UUID(), outcome: .complete, downloadMbps: 100, uploadMbps: 50,
            latencyMs: 20, connectionKind: .wifi
        )
        let evidence = NetworkAssistEvidence(
            id: NetworkAssistRequest.currentMeasurementEvidenceID(measurement.id),
            kind: .metric,
            sourceMeasurementIDs: [measurement.id]
        )
        let requestLike = RequestLike(
            question: "Interprete esta medição com os dados disponíveis.",
            currentMeasurement: measurement,
            recentMeasurements: [],
            evidence: [evidence],
            usageContext: nil,
            locale: nil,
            policy: .measurementUnderstanding,
            objective: objective,
            subcategory: subcategory
        )
        let data = try JSONEncoder().encode(requestLike)
        return try JSONDecoder().decode(NetworkAssistRequest.self, from: data)
    }

    /// Mesmo shape/`CodingKeys` de `NetworkAssistRequest` (Codable
    /// sintetizado), usado só para produzir o JSON que o decoder real de
    /// `NetworkAssistRequest` sabe ler.
    private struct RequestLike: Codable {
        let question: String
        let currentMeasurement: NetworkMeasurement
        let recentMeasurements: [NetworkMeasurement]
        let evidence: [NetworkAssistEvidence]
        let usageContext: String?
        let locale: String?
        let policy: NetworkAssistPolicy
        let objective: String?
        let subcategory: String?
    }

    func testAnswerMapsV2ExplanationToTitleSummaryAndRecommendation() async throws {
        let json = """
        {
          "raw": { "results": [], "recommendation": null },
          "explanation": {
            "titulo": "Ping alto identificado",
            "descricao": "Seu ping está bem acima do esperado para jogos.",
            "dados": "Ping médio de 180ms nos últimos testes.",
            "acao_usuario": "Conecte o console por cabo em vez de Wi-Fi."
          }
        }
        """.data(using: .utf8)!
        let client = StubHTTPClient(data: json, status: 200)
        let configuration = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://example.com/v1/diagnostics/evaluate")!,
            transportAuth: .relay,
            platformIdentifier: "ios"
        )
        let api = BuildeaDiagnosticAPI(configuration: configuration, httpClient: client)
        let transport = BuildeaDiagnosticTransport(api: api)

        let request = try makeRequest(objective: "JOGOS_COM_LAG", subcategory: "PING_ALTO")
        let response = try await transport.answer(request)

        XCTAssertEqual(response.title, "Ping alto identificado")
        XCTAssertEqual(response.summary, "Seu ping está bem acima do esperado para jogos.")
        XCTAssertEqual(response.recommendation?.title, "Conecte o console por cabo em vez de Wi-Fi.")
        XCTAssertEqual(response.recommendation?.description, "Ping médio de 180ms nos últimos testes.")
    }

    func testAnswerShowsTransparentMessageWhenSemCausaIdentificada() async throws {
        let json = """
        {
          "raw": { "results": [], "recommendation": null },
          "explanation": { "sem_causa_identificada": true }
        }
        """.data(using: .utf8)!
        let client = StubHTTPClient(data: json, status: 200)
        let configuration = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://example.com/v1/diagnostics/evaluate")!,
            transportAuth: .relay,
            platformIdentifier: "ios"
        )
        let api = BuildeaDiagnosticAPI(configuration: configuration, httpClient: client)
        let transport = BuildeaDiagnosticTransport(api: api)

        let request = try makeRequest(objective: "JOGOS_COM_LAG", subcategory: "PING_ALTO")
        let response = try await transport.answer(request)

        XCTAssertEqual(
            response.summary,
            "Não encontramos uma causa específica — os dados da sua conexão parecem normais."
        )
        XCTAssertNil(response.recommendation)
    }

    /// Regressão: resposta v1 pura (sem `raw`/`explanation`) continua
    /// passando pelo caminho de copy existente (IA do módulo `ai` ou
    /// fallback determinístico), sem quebrar.
    func testAnswerStillHandlesV1ResponseFormat() async throws {
        let json = """
        {
          "recommendation": {
            "id": "REC_WIFI_FAR",
            "type": "wifi_issue",
            "title": "Sinal Wi-Fi fraco",
            "description": "Aproxime-se do roteador.",
            "steps": []
          },
          "results": [
            { "module": "scoring", "result": { "score": 60, "veredicto": "regular" } }
          ]
        }
        """.data(using: .utf8)!
        let client = StubHTTPClient(data: json, status: 200)
        let configuration = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://example.com/v1/diagnostics/evaluate")!,
            transportAuth: .relay,
            platformIdentifier: "ios"
        )
        let api = BuildeaDiagnosticAPI(configuration: configuration, httpClient: client)
        let transport = BuildeaDiagnosticTransport(api: api)

        // Fluxo observacional puro: sem objective/subcategory guiados.
        let request = try makeRequest()
        let response = try await transport.answer(request)

        XCTAssertEqual(response.title, "Sinal Wi-Fi fraco")
        XCTAssertEqual(response.summary, "Aproxime-se do roteador.")
        XCTAssertEqual(response.recommendation?.title, "Sinal Wi-Fi fraco")
    }
}

private struct StubHTTPClient: DiagnosticHTTPClient {
    let data: Data
    let status: Int

    func postJSON(url: URL, body: Data, timeout: TimeInterval, bearerToken: String?) async throws -> (Data, Int) {
        (data, status)
    }
}

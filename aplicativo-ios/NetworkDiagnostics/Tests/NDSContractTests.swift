import XCTest
@testable import NetworkDiagnostics
import NetworkCore
import NetworkAssist

final class NDSContractTests: XCTestCase {
    func testDecodeNDSResponse() throws {
        let json = """
        {
          "recommendation": {
            "id": "REC_WIFI_FAR",
            "type": "wifi_issue",
            "title": "Sinal Wi-Fi fraco",
            "description": "Aproxime-se do roteador...",
            "steps": ["Aproxime-se do roteador.", "Repita a medição."],
            "source_finding_ids": ["wifi_signal_critical"]
          },
          "traces": [
            { "module": "scoring", "duration_ms": 3, "status": "ok" }
          ],
          "results": [
            {
              "module": "diagnostics.wifi",
              "result": {},
              "cards": [
                {
                  "id": "wifi_far",
                  "titulo": "Sinal Fraco",
                  "status": "attention",
                  "evidencia": null,
                  "mensagemUsuario": "Latência elevada",
                  "recomendacao": null,
                  "categoria": "wifi",
                  "podeConcluir": false,
                  "categoriaOrigem": null
                }
              ]
            },
            {
              "module": "scoring",
              "result": {
                "score": 85,
                "veredicto": "bom",
                "observed_dimensions": 2
              }
            },
            {
              "module": "ai",
              "result": {
                "explanation": {
                  "titulo_amigavel": "Tudo certo",
                  "resumo_tecnico_traduzido": "Sua conexão está boa."
                }
              }
            }
          ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(NDSResponse.self, from: json)
        
        XCTAssertEqual(response.recommendation?.id, "REC_WIFI_FAR")
        XCTAssertEqual(response.recommendation?.steps, ["Aproxime-se do roteador.", "Repita a medição."])
        XCTAssertEqual(response.traces?.first?.durationMs, 3)
        XCTAssertEqual(response.results?.first(where: { $0.module == "scoring" })?.result?.score, 85)
        XCTAssertEqual(response.results?.first(where: { $0.module == "scoring" })?.result?.veredicto, "bom")
        XCTAssertEqual(response.results?.first(where: { $0.module == "diagnostics.wifi" })?.cards?.first?.mensagemUsuario, "Latência elevada")
    }

    func testDecodeCanonicalErrorEnvelope() throws {
        let json = """
        {
          "error": {
            "code": "NDS_TIMEOUT",
            "message": "A análise demorou mais que o limite do serviço. Tente novamente.",
            "retryable": true
          },
          "request_id": "req-123"
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(NDSErrorEnvelope.self, from: json)

        XCTAssertEqual(envelope.error.code, "NDS_TIMEOUT")
        XCTAssertTrue(envelope.error.retryable)
        XCTAssertEqual(envelope.requestID, "req-123")
    }

    func testDecodeResponseWithoutRecommendation() throws {
        let response = try JSONDecoder().decode(
            NDSResponse.self,
            from: Data("{\"results\":[],\"traces\":[],\"recommendation\":null}".utf8)
        )

        XCTAssertNil(response.recommendation)
        XCTAssertEqual(response.results, [])
    }

    func testAPIPropagatesCanonicalNDSFailure() async throws {
        let client = StubDiagnosticHTTPClient(
            data: Data("""
            {
              "error": {
                "code": "NDS_TIMEOUT",
                "message": "Tente novamente.",
                "retryable": true
              },
              "request_id": "req-456"
            }
            """.utf8),
            status: 504
        )
        let configuration = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://example.com/v1/diagnostics/evaluate")!,
            bearerToken: "test-token",
            platformIdentifier: "ios"
        )
        let api = BuildeaDiagnosticAPI(configuration: configuration, httpClient: client)
        let measurement = NetworkMeasurement(
            id: UUID(),
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20,
            connectionKind: .wifi
        )

        do {
            _ = try await api.evaluate(measurement, requestAI: true)
            XCTFail("A falha canônica do NDS deveria ser propagada")
        } catch let error as NetworkDiagnosticsError {
            XCTAssertEqual(
                error,
                .nds(code: "NDS_TIMEOUT", message: "Tente novamente.", retryable: true, requestID: "req-456")
            )
        }
    }

    func testAPIFailsClosedWithoutCredential() async throws {
        let configuration = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://example.com/v1/diagnostics/evaluate")!,
            platformIdentifier: "ios"
        )
        let api = BuildeaDiagnosticAPI(
            configuration: configuration,
            httpClient: StubDiagnosticHTTPClient(data: Data(), status: 200)
        )
        let measurement = NetworkMeasurement(
            id: UUID(),
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20,
            connectionKind: .wifi
        )

        do {
            _ = try await api.evaluate(measurement, requestAI: false)
            XCTFail("A API deveria falhar fechada sem credencial")
        } catch let error as NetworkDiagnosticsError {
            XCTAssertEqual(error, .notConfigured)
        }
    }

    func testConfiguredRelayDoesNotSendBearerCredential() async throws {
        let client = RecordingDiagnosticHTTPClient(
            data: try JSONEncoder().encode(NDSResponse(results: [], traces: [], recommendation: nil)),
            status: 200
        )
        let api = BuildeaDiagnosticAPI(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: URL(string: "https://relay.example/v1/assist")!,
                transportAuth: .relay,
                platformIdentifier: "ios"
            ),
            httpClient: client
        )

        let measurement = NetworkMeasurement(
            id: UUID(), outcome: .complete, downloadMbps: 100, uploadMbps: 50,
            latencyMs: 20, connectionKind: .wifi
        )
        _ = try await api.evaluate(measurement, requestAI: true)

        let bearerToken = await client.bearerToken
        XCTAssertNil(bearerToken)
    }

    func testTransportSummarizesRecentMeasurementsForNDS() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let current = NetworkMeasurement(
            measuredAt: reference,
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 40,
            latencyMs: 20
        )
        let recent = [
            NetworkMeasurement(
                measuredAt: reference.addingTimeInterval(-86_400),
                outcome: .complete,
                downloadMbps: 200,
                uploadMbps: 60,
                latencyMs: 30
            ),
            NetworkMeasurement(
                measuredAt: reference.addingTimeInterval(-40 * 86_400),
                outcome: .complete,
                downloadMbps: 999,
                uploadMbps: 999,
                latencyMs: 999
            )
        ]

        let historical = BuildeaDiagnosticTransport.historicalSnapshot(
            current: current,
            recent: recent,
            referenceDate: reference,
            lookbackDays: 30
        )

        XCTAssertEqual(historical?.tests30d, 2)
        XCTAssertEqual(historical?.tests7d, 2)
        XCTAssertEqual(historical?.avgDownload30d, 150)
        XCTAssertEqual(historical?.avgDownload7d, 150)
        XCTAssertEqual(historical?.avgPing30d, 25)
    }
}

private struct StubDiagnosticHTTPClient: DiagnosticHTTPClient {
    let data: Data
    let status: Int

    func postJSON(url: URL, body: Data, timeout: TimeInterval, bearerToken: String?) async throws -> (Data, Int) {
        (data, status)
    }
}

private actor RecordingDiagnosticHTTPClient: DiagnosticHTTPClient {
    let data: Data
    let status: Int
    private(set) var bearerToken: String?

    init(data: Data, status: Int) {
        self.data = data
        self.status = status
    }

    func postJSON(url: URL, body: Data, timeout: TimeInterval, bearerToken: String?) async throws -> (Data, Int) {
        self.bearerToken = bearerToken
        return (data, status)
    }
}

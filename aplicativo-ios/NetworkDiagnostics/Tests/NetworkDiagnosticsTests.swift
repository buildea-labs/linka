import XCTest
import NetworkCore
import NetworkAssist
@testable import NetworkDiagnostics

final class DiagnosticSnapshotBuilderTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testSnapshotMapsCompleteWifiMeasurement() {
        let current = makeMeasurement(
            connection: .wifi,
            download: 250,
            upload: 40,
            latency: 12,
            jitter: 3
        )
        let builder = DiagnosticSnapshotBuilder()
        let snapshot = builder.snapshot(
            current: current,
            history: [],
            platform: PlatformHints(wifi: .init(ssid: nil, bssid: nil, rssiDbm: -55, band: "5GHz", linkSpeedMbps: 866)),
            appVersion: "1.0.0",
            platformIdentifier: "ios",
            now: now
        )

        XCTAssertEqual(snapshot.schemaVersion, 6)
        XCTAssertEqual(snapshot.platform, "ios")
        XCTAssertEqual(snapshot.appVersion, "1.0.0")
        XCTAssertEqual(snapshot.connection?.type, "wifi")
        XCTAssertEqual(snapshot.speed?.downloadMbps, 250)
        XCTAssertEqual(snapshot.speed?.uploadMbps, 40)
        XCTAssertEqual(snapshot.quality?.latencyMs, 12)
        XCTAssertEqual(snapshot.wifi?.rssiDbm, -55)
        XCTAssertEqual(snapshot.wifi?.band, "5GHz")
        XCTAssertEqual(snapshot.wifi?.linkSpeedMbps, 866)
        XCTAssertNil(snapshot.mobile)
    }

    func testCellularMeasurementFillsMobileBlockNotWifi() {
        let current = makeMeasurement(connection: .cellular, download: 30, upload: 10, latency: 45)
        let builder = DiagnosticSnapshotBuilder()
        let snapshot = builder.snapshot(
            current: current,
            history: [],
            platform: PlatformHints(
                wifi: .init(ssid: "não-deve-vazar", rssiDbm: -60),
                mobile: .init(technology: "5G", operatorName: "Vivo")
            ),
            appVersion: nil,
            platformIdentifier: "ios",
            now: now
        )
        XCTAssertNil(snapshot.wifi, "Wi-Fi só entra em conexão wifi")
        XCTAssertEqual(snapshot.mobile?.technology, "5G")
        XCTAssertEqual(snapshot.mobile?.operatorName, "Vivo")
        XCTAssertEqual(snapshot.connection?.type, "mobile")
    }

    func testHistoricalAggregatesOnlyMeasurementsInsideWindows() {
        let current = makeMeasurement(connection: .wifi, download: 100, upload: 20, latency: 20)
        let m1 = makeMeasurement(
            connection: .wifi, download: 200, upload: 40, latency: 10,
            measuredAt: now.addingTimeInterval(-1 * 86_400)
        )
        let m2 = makeMeasurement(
            connection: .wifi, download: 100, upload: 20, latency: 30,
            measuredAt: now.addingTimeInterval(-6 * 86_400)
        )
        let mOld = makeMeasurement(
            connection: .wifi, download: 900, upload: 900, latency: 900,
            measuredAt: now.addingTimeInterval(-31 * 86_400)
        )
        let builder = DiagnosticSnapshotBuilder()
        let snapshot = builder.snapshot(
            current: current,
            history: [m1, m2, mOld],
            platform: .empty,
            appVersion: nil,
            platformIdentifier: "ios",
            now: now
        )
        XCTAssertEqual(snapshot.historical?.testsCount7d, 2, "só m1 e m2 caem em 7d")
        XCTAssertEqual(snapshot.historical?.testsCount30d, 2, "mOld está fora de 30d")
        XCTAssertEqual(snapshot.historical?.avgDownload7d, 150)
    }

    func testSnapshotIsPureJSONSerializable() throws {
        let current = makeMeasurement(connection: .wifi, download: 100, upload: 20, latency: 20)
        let snapshot = DiagnosticSnapshotBuilder().snapshot(
            current: current,
            history: [],
            platform: .empty,
            appVersion: nil,
            platformIdentifier: "ios",
            now: now
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["schemaVersion"] as? Int, 6)
        XCTAssertEqual(obj?["platform"] as? String, "ios")
    }

    private func makeMeasurement(
        connection: NetworkConnectionKind,
        download: Double? = nil,
        upload: Double? = nil,
        latency: Double? = nil,
        jitter: Double? = nil,
        measuredAt: Date? = nil
    ) -> NetworkMeasurement {
        NetworkMeasurement(
            id: UUID(),
            measuredAt: measuredAt ?? now,
            outcome: .complete,
            downloadMbps: download,
            uploadMbps: upload,
            latencyMs: latency,
            jitterMs: jitter,
            connectionKind: connection
        )
    }
}

final class AiDiagnosisPayloadBuilderTests: XCTestCase {
    func testPayloadContainsQuestionAndMetricsInPortuguese() throws {
        let current = NetworkMeasurement(
            id: UUID(),
            outcome: .complete,
            downloadMbps: 300,
            uploadMbps: 50,
            latencyMs: 20,
            jitterMs: 2,
            connectionKind: .wifi
        )
        let payload = AiDiagnosisPayloadBuilder().payload(
            question: "  Serve para vídeo?  ",
            current: current,
            history: [],
            platform: PlatformHints(wifi: .init(rssiDbm: -60, band: "5GHz")),
            appVersion: "1.0",
            platformIdentifier: "ios"
        )
        XCTAssertEqual(payload.feedbackUsuario, "Serve para vídeo?")
        XCTAssertEqual(payload.connectionType, "wifi")
        XCTAssertEqual(payload.metricasAtuais?.downloadMbps, 300)
        XCTAssertEqual(payload.metricasAtuais?.latenciaMs, 20)
        XCTAssertEqual(payload.wifi?.banda, "5GHz")

        let data = try JSONEncoder().encode(payload)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(obj?["metricasAtuais"])
    }
}

// MARK: - Transports

final class MockHTTPClient: DiagnosticHTTPClient, @unchecked Sendable {
    var responseData: Data
    var responseStatus: Int
    var lastURL: URL?
    var lastBody: Data?

    init(responseData: Data, responseStatus: Int = 200) {
        self.responseData = responseData
        self.responseStatus = responseStatus
    }

    func postJSON(url: URL, body: Data, timeout: TimeInterval) async throws -> (Data, Int) {
        lastURL = url
        lastBody = body
        return (responseData, responseStatus)
    }
}

final class SignallqDiagnosticTransportTests: XCTestCase {
    func testAnsweredMapsDecisaoAndRecomendacoes() async throws {
        let json = """
        {
          "evaluationSource": "REMOTE",
          "decisao": {
            "id": "internet_instavel",
            "titulo": "Conexão instável",
            "status": "attention",
            "mensagemUsuario": "Sua velocidade está boa, mas a latência oscila.",
            "recomendacao": "Aproxime-se do roteador e refaça o teste.",
            "categoria": "internet",
            "podeConcluir": true
          },
          "recomendacoes": [
            {
              "id": "trocar-banda",
              "titulo": "Troque para 5 GHz",
              "status": "info",
              "mensagemUsuario": "Se possível, use a rede de 5 GHz."
            }
          ]
        }
        """.data(using: .utf8)!
        let client = MockHTTPClient(responseData: json)
        let config = NetworkDiagnosticsConfiguration(
            rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
            aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
            platformIdentifier: "ios"
        )
        let transport = SignallqDiagnosticTransport(configuration: config, httpClient: client)
        let service = NetworkAssistService(transport: transport)

        let response = try await service.answer(NetworkAssistContext(
            question: "Como está minha rede?",
            currentMeasurement: makeValidMeasurement()
        ))

        XCTAssertEqual(response.disposition, .answered)
        XCTAssertEqual(response.text, "Sua velocidade está boa, mas a latência oscila.")
        XCTAssertNotNil(response.longText)
        XCTAssertTrue(response.longText?.contains("Aproxime-se do roteador") ?? false)
        XCTAssertTrue(response.longText?.contains("Se possível, use a rede de 5 GHz") ?? false)
        XCTAssertFalse(response.evidenceIDs.isEmpty)
        XCTAssertEqual(client.lastURL, config.rulesEndpoint)
    }

    func testMissingDecisaoBecomesInsufficientEvidence() async throws {
        let json = "{\"evaluationSource\":\"REMOTE\"}".data(using: .utf8)!
        let transport = SignallqDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: json)
        )
        let service = NetworkAssistService(transport: transport)
        let response = try await service.answer(NetworkAssistContext(
            question: "Como está minha rede?",
            currentMeasurement: makeValidMeasurement()
        ))
        XCTAssertEqual(response.disposition, .insufficientEvidence)
        XCTAssertTrue(response.evidenceIDs.isEmpty)
    }

    func testHttpErrorSurfacesAsError() async {
        let transport = SignallqDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: Data("erro".utf8), responseStatus: 503)
        )
        let service = NetworkAssistService(transport: transport)
        do {
            _ = try await service.answer(NetworkAssistContext(
                question: "Como está minha rede?",
                currentMeasurement: makeValidMeasurement()
            ))
            XCTFail("esperava erro")
        } catch let error as NetworkDiagnosticsError {
            XCTAssertEqual(error, .httpStatus(503))
        } catch {
            XCTFail("erro inesperado: \(error)")
        }
    }
}

final class SignallqAiDiagnosticTransportTests: XCTestCase {
    func testAiResponseSplitsResumoAsShortAndTextoLaudoAsLong() async throws {
        let json = """
        {
          "schemaVersion": "2",
          "status": "regular",
          "titulo": "Conexão instável",
          "resumo": "A velocidade está boa, mas a conexão oscila.",
          "textoLaudo": "Sua conexão está oscilando e isso pode causar travamentos em chamadas."
        }
        """.data(using: .utf8)!
        let transport = SignallqAiDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: json)
        )
        let service = NetworkAssistService(transport: transport)
        let response = try await service.answer(NetworkAssistContext(
            question: "Serve para vídeo?",
            currentMeasurement: makeValidMeasurement()
        ))
        XCTAssertEqual(response.disposition, .answered)
        XCTAssertEqual(response.text, "A velocidade está boa, mas a conexão oscila.")
        XCTAssertEqual(response.longText, "Sua conexão está oscilando e isso pode causar travamentos em chamadas.")
    }

    func testAiResponseFallsBackToResumoWhenTextoLaudoMissing() async throws {
        let json = """
        {"schemaVersion":"2","status":"bom","titulo":"Resposta","resumo":"Conexão ok pra vídeo."}
        """.data(using: .utf8)!
        let transport = SignallqAiDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: json)
        )
        let service = NetworkAssistService(transport: transport)
        let response = try await service.answer(NetworkAssistContext(
            question: "Serve para vídeo?",
            currentMeasurement: makeValidMeasurement()
        ))
        XCTAssertEqual(response.text, "Conexão ok pra vídeo.")
        XCTAssertNil(response.longText)
        XCTAssertFalse(response.text.contains("Resposta"), "título genérico do modo chat não deve aparecer")
    }

    func testAiResponseUsesTextoLaudoAsShortWhenResumoMissing() async throws {
        let json = """
        {"schemaVersion":"2","status":"bom","textoLaudo":"Sua conexão está saudável."}
        """.data(using: .utf8)!
        let transport = SignallqAiDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: json)
        )
        let service = NetworkAssistService(transport: transport)
        let response = try await service.answer(NetworkAssistContext(
            question: "Como está?",
            currentMeasurement: makeValidMeasurement()
        ))
        XCTAssertEqual(response.text, "Sua conexão está saudável.")
        XCTAssertNil(response.longText)
    }

    func testInconclusiveStatusBecomesInsufficientEvidence() async throws {
        let json = """
        {"schemaVersion":"2","status":"inconclusivo","resumo":"Sem dados suficientes."}
        """.data(using: .utf8)!
        let transport = SignallqAiDiagnosticTransport(
            configuration: NetworkDiagnosticsConfiguration(
                rulesEndpoint: NetworkDiagnosticsConfiguration.defaultRulesEndpoint,
                aiEndpoint: NetworkDiagnosticsConfiguration.defaultAiEndpoint,
                platformIdentifier: "ios"
            ),
            httpClient: MockHTTPClient(responseData: json)
        )
        let service = NetworkAssistService(transport: transport)
        let response = try await service.answer(NetworkAssistContext(
            question: "Como está minha rede?",
            currentMeasurement: makeValidMeasurement()
        ))
        XCTAssertEqual(response.disposition, .insufficientEvidence)
        XCTAssertTrue(response.evidenceIDs.isEmpty)
    }
}

private func makeValidMeasurement() -> NetworkMeasurement {
    NetworkMeasurement(
        id: UUID(),
        outcome: .complete,
        downloadMbps: 100,
        uploadMbps: 20,
        latencyMs: 15,
        connectionKind: .wifi
    )
}

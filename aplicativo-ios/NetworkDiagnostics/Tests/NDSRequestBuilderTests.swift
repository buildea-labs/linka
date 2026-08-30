import XCTest
@testable import NetworkDiagnostics
import NetworkCore

final class NDSRequestBuilderTests: XCTestCase {
    func testBuildRequest() throws {
        let builder = NDSRequestBuilder()
        let measurement = NetworkMeasurement(
            id: UUID(),
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20,
            connectionKind: .wifi
        )
        let hints = PlatformHints(wifi: PlatformHints.Wifi(rssiDbm: -50, linkSpeedMbps: 866))
        
        let request = builder.buildRequest(current: measurement, platformHints: hints, appVersion: "1.0.0", platformIdentifier: "ios", requestAI: true)
        
        XCTAssertEqual(request.sessionId, measurement.id.uuidString)
        XCTAssertEqual(request.platform, "ios")
        XCTAssertEqual(request.app?.version, "1.0.0")
        XCTAssertEqual(request.capabilities, ["wifi"])
        XCTAssertEqual(request.requestedOutputs, ["scoring", "ai"])
        XCTAssertEqual(request.connection?.type, "wifi")
        XCTAssertEqual(request.wifi?.rssiDbm, -50)
        XCTAssertEqual(request.speed?.downloadMbps, 100)

        let encoded = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(json["requested_outputs"] as? [String], ["scoring", "ai"])
        XCTAssertNil(json["context"])
    }

    func testBuildRequest_forwardsOnlyProvidedDiagnosticContext() throws {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let context = NDSRequest.DiagnosticContext(objective: "chamada de vídeo")

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: true,
            diagnosticContext: context
        )

        XCTAssertEqual(request.context, context)
    }

    /// `subcategory` (issue objective+subcategory guiado) só existe quando
    /// o app coletou a seleção guiada — precisa aparecer no JSON quando
    /// fornecido e ficar totalmente ausente (não `null`) quando não.
    func testBuildRequest_includesSubcategoryWhenProvided() throws {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let context = NDSRequest.DiagnosticContext(objective: "JOGOS_COM_LAG", subcategory: "PING_ALTO")

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: true,
            diagnosticContext: context
        )

        XCTAssertEqual(request.context?.subcategory, "PING_ALTO")

        let encoded = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let contextJSON = try XCTUnwrap(json["context"] as? [String: Any])
        XCTAssertEqual(contextJSON["subcategory"] as? String, "PING_ALTO")
    }

    func testBuildRequest_omitsSubcategoryWhenNil() throws {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let context = NDSRequest.DiagnosticContext(objective: "JOGOS_COM_LAG")

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: true,
            diagnosticContext: context
        )

        XCTAssertNil(request.context?.subcategory)

        let encoded = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let contextJSON = try XCTUnwrap(json["context"] as? [String: Any])
        XCTAssertNil(contextJSON["subcategory"])
    }

    func testBuildRequestNeverSendsSSIDOrBSSID() throws {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20,
            connectionKind: .wifi,
            wifiContext: WiFiNetworkContext(ssid: "Casa", accessPointIdentifier: "derived-ap"),
            advancedWiFiDiagnostics: AdvancedWiFiDiagnostics(
                capturedAt: Date(),
                ssid: "Casa",
                accessPointIdentifier: "advanced-derived-ap",
                rssiDbm: -51,
                noiseDbm: -92,
                snrDb: 41
            )
        )
        let hints = PlatformHints(wifi: .init(ssid: "Casa", bssid: "AA:BB:CC:DD:EE:FF", rssiDbm: -51))

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: hints,
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: false
        )
        let data = try JSONEncoder().encode(request)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertFalse(json.contains("Casa"))
        XCTAssertFalse(json.contains("AA:BB:CC:DD:EE:FF"))
        XCTAssertFalse(json.contains("derived-ap"))
        XCTAssertFalse(json.contains("advanced-derived-ap"))
    }

    func testBuildRequest_forwardsHistoricalEvidenceAsCapability() throws {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 100,
            uploadMbps: 50,
            latencyMs: 20
        )
        let historical = NDSRequest.Historical(
            avgDownload30d: 200,
            avgDownload7d: 150,
            tests30d: 8,
            tests7d: 3
        )

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: true,
            historical: historical
        )

        XCTAssertEqual(request.capabilities, ["historical"])
        XCTAssertEqual(request.historical, historical)
    }

    /// Issue #129: `speed: {}` (objeto presente, campos vazios) é rejeitado
    /// pelo relay do NDS com RELAY_INVALID_REQUEST — confirmado testando o
    /// payload real contra o serviço em produção. Um teste que aborta antes
    /// do download/upload (`outcome: .partial`) tem as duas velocidades
    /// nil; a chave `speed` precisa ficar ausente, não virar objeto vazio.
    func testBuildRequest_omitsSpeedWhenBothDownloadAndUploadAreNil() throws {
        let measurement = NetworkMeasurement(
            outcome: .partial,
            latencyMs: 22
        )

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: false
        )

        XCTAssertNil(request.speed)

        let encoded = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNil(json["speed"])
    }

    /// Basta uma das duas velocidades existir para o objeto `speed` ser
    /// enviado — só as duas ausentes ao mesmo tempo omitem a chave.
    func testBuildRequest_includesSpeedWhenOnlyDownloadIsKnown() throws {
        let measurement = NetworkMeasurement(
            outcome: .partial,
            downloadMbps: 50,
            latencyMs: 22
        )

        let request = NDSRequestBuilder().buildRequest(
            current: measurement,
            platformHints: PlatformHints(),
            appVersion: nil,
            platformIdentifier: "ios",
            requestAI: false
        )

        XCTAssertEqual(request.speed?.downloadMbps, 50)
        XCTAssertNil(request.speed?.uploadMbps)
    }
}

import XCTest
@testable import NetworkCore

final class NetworkCoreTests: XCTestCase {
    func testCompleteMeasurementRequiresCoreMetrics() {
        let measurement = NetworkMeasurement(
            outcome: .complete,
            downloadMbps: 500,
            uploadMbps: 100,
            latencyMs: 12
        )

        XCTAssertTrue(NetworkMeasurementContract.isValid(measurement))
    }

    func testPartialMeasurementRequiresAtLeastOneMetric() {
        XCTAssertFalse(NetworkMeasurementContract.isValid(NetworkMeasurement()))
        XCTAssertTrue(NetworkMeasurementContract.isValid(NetworkMeasurement(latencyMs: 15)))
    }

    func testInvalidRangesAreRejected() {
        let measurement = NetworkMeasurement(
            downloadMbps: -1,
            packetLossPercent: 101
        )

        let violations = NetworkMeasurementContract.violations(for: measurement)
        XCTAssertTrue(violations.contains("downloadMbps"))
        XCTAssertTrue(violations.contains("packetLossPercent"))
    }

    func testWifiBandRequiresWifiConnectionKind() {
        let bandWithoutWifi = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: .cellular,
            wifiBandGHz: 5.0
        )
        XCTAssertTrue(NetworkMeasurementContract.violations(for: bandWithoutWifi).contains("wifiBandGHz"))

        let bandWithNilKind = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: nil,
            wifiBandGHz: 5.0
        )
        XCTAssertTrue(NetworkMeasurementContract.violations(for: bandWithNilKind).contains("wifiBandGHz"))

        let validBand = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: .wifi,
            wifiBandGHz: 5.0
        )
        XCTAssertTrue(NetworkMeasurementContract.isValid(validBand))
    }

    func testWifiBandMustBePositiveAndFinite() {
        let negative = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: .wifi,
            wifiBandGHz: -1
        )
        XCTAssertTrue(NetworkMeasurementContract.violations(for: negative).contains("wifiBandGHz"))

        let nan = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: .wifi,
            wifiBandGHz: .nan
        )
        XCTAssertTrue(NetworkMeasurementContract.violations(for: nan).contains("wifiBandGHz"))
    }

    /// Ausência de banda é o estado normal (issue #51 — sempre o caso no
    /// iPhone, e no Mac quando `CoreWLAN` não confirma nada): não é
    /// violação de contrato.
    func testWifiConnectionWithoutBandIsValid() {
        let measurement = NetworkMeasurement(
            latencyMs: 15,
            connectionKind: .wifi,
            wifiBandGHz: nil
        )
        XCTAssertTrue(NetworkMeasurementContract.isValid(measurement))
    }

    /// Um registro antigo (schema v1, sem `wifiBandGHz` no JSON) precisa
    /// continuar decodificando sem quebrar — o campo novo é opcional com
    /// default `nil`, sem exigir bump de `schemaVersion` (nota do plano #51).
    func testDecodesLegacyJSONWithoutWifiBandField() throws {
        let legacyJSON = """
        {
            "schemaVersion": 1,
            "id": "4A5F9B63-E4F4-4D90-904F-3E618FC92C32",
            "measuredAt": "2026-08-01T12:00:00Z",
            "outcome": "complete",
            "downloadMbps": 512.4,
            "uploadMbps": 104.8,
            "latencyMs": 11.7,
            "connectionKind": "wifi",
            "serverIdentifier": "cloudflare"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NetworkMeasurement.self, from: Data(legacyJSON.utf8))

        XCTAssertNil(decoded.wifiBandGHz)
        XCTAssertEqual(decoded.connectionKind, .wifi)
        XCTAssertTrue(NetworkMeasurementContract.isValid(decoded))
    }

    func testMeasurementRoundTripsThroughJSON() throws {
        let original = NetworkMeasurement(
            id: UUID(uuidString: "4A5F9B63-E4F4-4D90-904F-3E618FC92C32")!,
            measuredAt: Date(timeIntervalSince1970: 1_786_428_000),
            outcome: .complete,
            downloadMbps: 512.4,
            uploadMbps: 104.8,
            latencyMs: 11.7,
            connectionKind: .wifi,
            serverIdentifier: "cloudflare"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NetworkMeasurement.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testWifiBandRoundTripsThroughJSON() throws {
        let original = NetworkMeasurement(
            id: UUID(uuidString: "4A5F9B63-E4F4-4D90-904F-3E618FC92C32")!,
            measuredAt: Date(timeIntervalSince1970: 1_786_428_000),
            outcome: .complete,
            downloadMbps: 512.4,
            uploadMbps: 104.8,
            latencyMs: 11.7,
            connectionKind: .wifi,
            wifiBandGHz: 5.0,
            serverIdentifier: "cloudflare"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NetworkMeasurement.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.wifiBandGHz, 5.0)
    }

    // MARK: - NetworkConnectionKind.resolve(start:end:) — issue #51

    /// Troca de rede durante o teste (início ≠ fim) deve persistir `nil`
    /// em vez de afirmar um tipo que não valeu para o teste inteiro.
    func testResolveReturnsNilWhenBothAreNil() {
        XCTAssertNil(NetworkConnectionKind.resolve(start: nil, end: nil))
    }

    func testResolveReturnsNilWhenStartIsNil() {
        XCTAssertNil(NetworkConnectionKind.resolve(start: nil, end: .wifi))
    }

    func testResolveReturnsNilWhenEndIsNil() {
        XCTAssertNil(NetworkConnectionKind.resolve(start: .wifi, end: nil))
    }

    func testResolveReturnsCommonKindWhenBothMatch() {
        XCTAssertEqual(NetworkConnectionKind.resolve(start: .wifi, end: .wifi), .wifi)
        XCTAssertEqual(NetworkConnectionKind.resolve(start: .cellular, end: .cellular), .cellular)
        XCTAssertEqual(NetworkConnectionKind.resolve(start: .ethernet, end: .ethernet), .ethernet)
        XCTAssertEqual(NetworkConnectionKind.resolve(start: .other, end: .other), .other)
    }

    func testResolveReturnsNilWhenKindsDiverge() {
        XCTAssertNil(NetworkConnectionKind.resolve(start: .wifi, end: .cellular))
        XCTAssertNil(NetworkConnectionKind.resolve(start: .cellular, end: .wifi))
        XCTAssertNil(NetworkConnectionKind.resolve(start: .ethernet, end: .other))
        XCTAssertNil(NetworkConnectionKind.resolve(start: .wifi, end: .ethernet))
    }
}

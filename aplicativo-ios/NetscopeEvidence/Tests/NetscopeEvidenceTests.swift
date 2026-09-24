import XCTest
@testable import NetscopeEvidence
import NetworkCore

final class NetscopeEvidenceTests: XCTestCase {
    func test_projectsOnlyValidAllowlistedMeasurementFacts() {
        let measurement = NetworkMeasurement(
            downloadMbps: 500.5,
            uploadMbps: 80.25,
            latencyMs: 12,
            jitterMs: 1.5,
            packetLossPercent: 0,
            connectionKind: .wifi,
            wifiBandGHz: 5,
            wifiContext: WiFiNetworkContext(
                ssid: "Casa privada",
                accessPointIdentifier: "identificador-local",
                rssiDbm: -58,
                linkSpeedMbps: 1200,
                gatewayIP: "192.168.0.1",
                gatewayVendor: "Fabricante"
            ),
            networkIdentifier: "provedor",
            serverIdentifier: "servidor",
            location: MeasurementLocation(latitude: -23.55, longitude: -46.63)
        )

        let evidence = NetscopeMeasurementEvidenceProjector.project(measurement)

        XCTAssertEqual(evidence.downloadMbps, 500.5)
        XCTAssertEqual(evidence.uploadMbps, 80.25)
        XCTAssertEqual(evidence.latencyMs, 12)
        XCTAssertEqual(evidence.jitterMs, 1.5)
        XCTAssertEqual(evidence.packetLossPercent, 0)
        XCTAssertEqual(evidence.connectionKind, .wifi)
        XCTAssertEqual(evidence.wifiDetails, .init(band: .fiveGHz, linkSpeedMbps: 1200))

        let encoded = try! JSONEncoder().encode(evidence)
        let payload = String(decoding: encoded, as: UTF8.self)
        XCTAssertTrue(payload.contains("\"band\":\"5ghz\""))
        XCTAssertTrue(payload.contains("\"link_speed_mbps\":1200"))
        XCTAssertFalse(payload.contains("rssi"))
        XCTAssertFalse(payload.contains("Casa privada"))
        XCTAssertFalse(payload.contains("identificador-local"))
        XCTAssertFalse(payload.contains("192.168.0.1"))
        XCTAssertFalse(payload.contains("provedor"))
        XCTAssertFalse(payload.contains("servidor"))
        XCTAssertFalse(payload.contains("latitude"))
    }

    func test_omitsAbsentMetricsAndWifiDetailsWithoutInventingZero() {
        let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(connectionKind: .wifi))

        XCTAssertNil(evidence.downloadMbps)
        XCTAssertNil(evidence.uploadMbps)
        XCTAssertNil(evidence.latencyMs)
        XCTAssertNil(evidence.jitterMs)
        XCTAssertNil(evidence.packetLossPercent)
        XCTAssertEqual(evidence.connectionKind, .wifi)
        XCTAssertNil(evidence.wifiDetails)
    }

    func test_omitsInvalidNumbersIndividually() {
        let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
            downloadMbps: -.infinity,
            uploadMbps: 42,
            latencyMs: .nan,
            jitterMs: -0.1,
            packetLossPercent: 100.1,
            connectionKind: .wifi,
            wifiBandGHz: -.infinity,
            wifiContext: WiFiNetworkContext(rssiDbm: .nan, linkSpeedMbps: 0)
        ))

        XCTAssertNil(evidence.downloadMbps)
        XCTAssertEqual(evidence.uploadMbps, 42)
        XCTAssertNil(evidence.latencyMs)
        XCTAssertNil(evidence.jitterMs)
        XCTAssertNil(evidence.packetLossPercent)
        XCTAssertNil(evidence.wifiDetails)
    }

    func test_projectsEveryObservedConnectionKindAndUnknownRoute() {
        XCTAssertEqual(projectedKind(.wifi), .wifi)
        XCTAssertEqual(projectedKind(.cellular), .cellular)
        XCTAssertEqual(projectedKind(.ethernet), .ethernet)
        XCTAssertEqual(projectedKind(.other), .other)
        XCTAssertEqual(projectedKind(nil), .unknown)
    }

    func test_unknownRouteOmitsWifiDetailsEvenWhenWifiFieldsExist() {
        let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
            connectionKind: nil,
            wifiBandGHz: 5,
            wifiContext: WiFiNetworkContext(rssiDbm: -58, linkSpeedMbps: 1200)
        ))

        XCTAssertEqual(evidence.connectionKind, .unknown)
        XCTAssertNil(evidence.wifiDetails)
    }

    func test_routeTransitionProjectsAsUnknownInsteadOfChoosingEitherInterface() {
        let resolvedKind = NetworkConnectionKind.resolve(start: .wifi, end: .cellular)
        let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
            connectionKind: resolvedKind,
            wifiBandGHz: 5,
            wifiContext: WiFiNetworkContext(rssiDbm: -58, linkSpeedMbps: 1200)
        ))

        XCTAssertNil(resolvedKind)
        XCTAssertEqual(evidence.connectionKind, .unknown)
        XCTAssertNil(evidence.wifiDetails)
    }

    func test_wifiDetailsAreOmittedForNonWifiRoutes() {
        for kind in [NetworkConnectionKind.cellular, .ethernet, .other] {
            let measurement = NetworkMeasurement(
                connectionKind: kind,
                wifiBandGHz: 5,
                wifiContext: WiFiNetworkContext(rssiDbm: -58, linkSpeedMbps: 1200)
            )

            XCTAssertNil(NetscopeMeasurementEvidenceProjector.project(measurement).wifiDetails)
        }
    }

    func test_declaredContextStaysSeparateFromObservedEvidence() {
        let input = NetscopeLocalAnalysisInput(
            observedEvidence: NetscopeMeasurementEvidenceProjector.project(
                NetworkMeasurement(connectionKind: .ethernet)
            ),
            declaredContext: NetscopeDeclaredContext(objective: .gaming)
        )

        XCTAssertEqual(input.observedEvidence.connectionKind, .ethernet)
        XCTAssertNil(input.observedEvidence.wifiDetails)
        XCTAssertEqual(input.declaredContext.objective, .gaming)
    }

    func test_onlyWirePermittedBandsAreProjectedAndUnprovenBandIsOmitted() {
        XCTAssertEqual(projectedBand(2.4), .twoPointFourGHz)
        XCTAssertEqual(projectedBand(5), .fiveGHz)
        XCTAssertEqual(projectedBand(6), .sixGHz)
        XCTAssertNil(projectedBand(5.8))
        XCTAssertNil(projectedBand(.nan))
    }

    func test_zeroOrNegativeLinkSpeedIsOmittedRatherThanSentAsObserved() {
        for linkSpeed: Double in [0, -1] {
            let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
                connectionKind: .wifi,
                wifiContext: WiFiNetworkContext(linkSpeedMbps: linkSpeed)
            ))

            XCTAssertNil(evidence.wifiDetails)
        }
    }

    func test_wifiJSONExcludesRssiIdentifiersGatewayAndAdvancedDiagnostics() throws {
        let evidence = NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
            connectionKind: .wifi,
            wifiBandGHz: 5,
            wifiContext: WiFiNetworkContext(
                ssid: "Casa privada",
                accessPointIdentifier: "local-ap-id",
                rssiDbm: -58,
                linkSpeedMbps: 1200,
                gatewayIP: "192.168.0.1",
                gatewayVendor: "Fabricante",
                gatewayAdminURL: "http://192.168.0.1"
            ),
            advancedWiFiDiagnostics: AdvancedWiFiDiagnostics(
                capturedAt: Date(timeIntervalSince1970: 1),
                wifiStandard: "802.11ax",
                rxRateMbps: 1300,
                txRateMbps: 900,
                noiseDbm: -95,
                channelNumber: 36,
                snrDb: 37
            )
        ))

        let payload = String(decoding: try JSONEncoder().encode(evidence), as: UTF8.self)
        XCTAssertEqual(evidence.wifiDetails, .init(band: .fiveGHz, linkSpeedMbps: 1200))
        XCTAssertFalse(payload.contains("rssi"))
        XCTAssertFalse(payload.contains("Casa privada"))
        XCTAssertFalse(payload.contains("local-ap-id"))
        XCTAssertFalse(payload.contains("192.168.0.1"))
        XCTAssertFalse(payload.contains("Fabricante"))
        XCTAssertFalse(payload.contains("802.11ax"))
        XCTAssertFalse(payload.contains("1300"))
        XCTAssertFalse(payload.contains("900"))
        XCTAssertFalse(payload.contains("channelNumber"))
        XCTAssertFalse(payload.contains("snrDb"))
    }

    private func projectedBand(_ gigahertz: Double?) -> NetscopeMeasurementEvidence.WiFiDetails.Band? {
        NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(
            connectionKind: .wifi,
            wifiBandGHz: gigahertz
        )).wifiDetails?.band
    }

    private func projectedKind(_ kind: NetworkConnectionKind?) -> NetscopeMeasurementEvidence.ConnectionKind {
        NetscopeMeasurementEvidenceProjector.project(NetworkMeasurement(connectionKind: kind)).connectionKind
    }
}

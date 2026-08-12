import XCTest
import NetworkCore
@testable import NetworkAssist

final class NetworkAssistTests: XCTestCase {
    private func completeMeasurement(
        id: UUID = UUID(),
        download: Double = 500,
        upload: Double = 100,
        latency: Double = 12
    ) -> NetworkMeasurement {
        NetworkMeasurement(
            id: id,
            outcome: .complete,
            downloadMbps: download,
            uploadMbps: upload,
            latencyMs: latency
        )
    }

    func testUnconfiguredTransportFailsClosed() async {
        let service = NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        let context = NetworkAssistContext(
            question: "Esse resultado está bom?",
            currentMeasurement: completeMeasurement()
        )

        do {
            _ = try await service.answer(context)
            XCTFail("Expected notConfigured")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServiceInjectsRestrictivePolicyAndAcceptsGroundedAnswer() async throws {
        let measurement = completeMeasurement()
        let transport = RecordingTransport { request in
            XCTAssertTrue(request.policy.observationalOnly)
            XCTAssertFalse(request.policy.mayInferRootCause)
            XCTAssertFalse(request.policy.mayRecommendRepair)
            XCTAssertTrue(request.policy.mustGroundInProvidedData)
            XCTAssertTrue(request.policy.handoffWhenDiagnosisIsRequired)

            return NetworkAssistResponse(
                text: "A medição mostra 500 Mbps de download e 12 ms de latência.",
                disposition: .answered,
                evidenceIDs: [NetworkAssistRequest.currentMeasurementEvidenceID(measurement.id)]
            )
        }
        let service = NetworkAssistService(transport: transport)

        let response = try await service.answer(
            NetworkAssistContext(
                question: "  Como foi esse teste?  ",
                currentMeasurement: measurement
            )
        )

        XCTAssertEqual(response.disposition, .answered)
        XCTAssertFalse(response.text.isEmpty)
    }

    func testInvalidMeasurementNeverReachesTransport() async {
        let invalid = NetworkMeasurement(outcome: .complete, downloadMbps: 100)
        let service = NetworkAssistService(transport: FailingIfCalledTransport())

        do {
            _ = try await service.answer(
                NetworkAssistContext(question: "Como foi?", currentMeasurement: invalid)
            )
            XCTFail("Expected invalidMeasurement")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .invalidMeasurement(invalid.id))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEmptyAndOversizedQuestionsAreRejected() async {
        let measurement = completeMeasurement()
        let service = NetworkAssistService(
            transport: FailingIfCalledTransport(),
            configuration: .init(maximumQuestionLength: 10)
        )

        do {
            _ = try await service.answer(
                NetworkAssistContext(question: "   ", currentMeasurement: measurement)
            )
            XCTFail("Expected emptyQuestion")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .emptyQuestion)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            _ = try await service.answer(
                NetworkAssistContext(question: "01234567890", currentMeasurement: measurement)
            )
            XCTFail("Expected questionTooLong")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .questionTooLong(maximum: 10))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEvidenceCannotReferenceUnknownMeasurement() async {
        let measurement = completeMeasurement()
        let evidence = NetworkAssistEvidence(
            id: "trend-download",
            kind: .trend,
            metricKey: "downloadMbps",
            direction: "falling",
            sourceMeasurementIDs: [UUID()]
        )
        let service = NetworkAssistService(transport: FailingIfCalledTransport())

        do {
            _ = try await service.answer(
                NetworkAssistContext(
                    question: "Meu download mudou?",
                    currentMeasurement: measurement,
                    evidence: [evidence]
                )
            )
            XCTFail("Expected unknownEvidenceSource")
        } catch let error as NetworkAssistError {
            guard case .unknownEvidenceSource = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProviderCannotInventEvidenceReference() async {
        let measurement = completeMeasurement()
        let transport = RecordingTransport { _ in
            NetworkAssistResponse(
                text: "Resposta",
                disposition: .answered,
                evidenceIDs: ["inventado"]
            )
        }
        let service = NetworkAssistService(transport: transport)

        do {
            _ = try await service.answer(
                NetworkAssistContext(question: "Como foi?", currentMeasurement: measurement)
            )
            XCTFail("Expected unknownResponseEvidenceID")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .unknownResponseEvidenceID("inventado"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAnsweredResponseMustCiteEvidence() async {
        let measurement = completeMeasurement()
        let transport = RecordingTransport { _ in
            NetworkAssistResponse(text: "Resposta", disposition: .answered)
        }
        let service = NetworkAssistService(transport: transport)

        do {
            _ = try await service.answer(
                NetworkAssistContext(question: "Como foi?", currentMeasurement: measurement)
            )
            XCTFail("Expected answeredWithoutEvidence")
        } catch let error as NetworkAssistError {
            XCTAssertEqual(error, .answeredWithoutEvidence)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequiresDiagnosisCanReturnWithoutEvidenceReference() async throws {
        let transport = RecordingTransport { _ in
            NetworkAssistResponse(
                text: "Essa pergunta exige investigação além das medições disponíveis.",
                disposition: .requiresDiagnosis
            )
        }
        let service = NetworkAssistService(transport: transport)

        let response = try await service.answer(
            NetworkAssistContext(
                question: "Por que meu Wi-Fi está caindo?",
                currentMeasurement: completeMeasurement()
            )
        )

        XCTAssertEqual(response.disposition, .requiresDiagnosis)
    }
}

private struct RecordingTransport: NetworkAssistTransport {
    let handler: @Sendable (NetworkAssistRequest) throws -> NetworkAssistResponse

    init(handler: @escaping @Sendable (NetworkAssistRequest) throws -> NetworkAssistResponse) {
        self.handler = handler
    }

    func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        try handler(request)
    }
}

private struct FailingIfCalledTransport: NetworkAssistTransport {
    func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        XCTFail("Transport should not have been called")
        throw NetworkAssistError.notConfigured
    }
}

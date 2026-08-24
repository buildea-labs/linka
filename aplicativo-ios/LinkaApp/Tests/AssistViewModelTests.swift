import XCTest
import NetworkAssist
import NetworkCore
@testable import LinkaApp

@MainActor
final class AssistViewModelTests: XCTestCase {
    func test_makeContext_usesCurrentAndRecentMeasurementsAsEvidence() {
        let current = measurement(id: UUID())
        let recent = [measurement(id: UUID()), measurement(id: UUID())]

        let context = AssistViewModel.makeContext(
            currentMeasurement: current,
            recentMeasurements: recent
        )

        XCTAssertEqual(context.question, "Interprete esta medição com os dados disponíveis.")
        XCTAssertEqual(context.currentMeasurement.id, current.id)
        XCTAssertEqual(context.recentMeasurements.map(\.id), recent.map(\.id))
        XCTAssertNil(context.usageContext)
        XCTAssertEqual(
            context.evidence.map(\.id),
            [
                NetworkAssistRequest.currentMeasurementEvidenceID(current.id),
                NetworkAssistRequest.recentMeasurementEvidenceID(recent[0].id),
                NetworkAssistRequest.recentMeasurementEvidenceID(recent[1].id)
            ]
        )
    }

    func test_makeContext_doesNotInferUsageContext_andLimitsHistory() {
        let current = measurement(id: UUID())
        let recent = (0..<25).map { _ in measurement(id: UUID()) }

        let context = AssistViewModel.makeContext(
            currentMeasurement: current,
            recentMeasurements: recent,
            usageContext: nil
        )

        XCTAssertEqual(context.recentMeasurements.count, 20)
        XCTAssertNil(context.usageContext)
    }

    func test_load_insufficientEvidence_becomesExplicitError() async {
        let provider = StubAssistProvider(
            response: NetworkAssistResponse(
                text: "Não há dados suficientes.",
                disposition: .insufficientEvidence
            )
        )
        let viewModel = AssistViewModel(assistProvider: provider)

        await viewModel.load(
            currentMeasurement: measurement(id: UUID()),
            failureSignal: nil
        )

        XCTAssertEqual(
            viewModel.state,
            .error("Ainda não há dados suficientes para uma interpretação confiável.")
        )
    }

    func test_load_fallback_keepsRecommendationAndSteps() async {
        let recommendation = NetworkAssistRecommendation(
            title: "Repita a medição",
            description: "Faça outro teste para confirmar o resultado.",
            steps: ["Aproxime-se do roteador.", "Repita a medição."]
        )
        let current = measurement(id: UUID())
        let provider = StubAssistProvider(
            response: NetworkAssistResponse(
                text: "A resposta chegou sem o bloco visual estruturado.",
                disposition: .answered,
                evidenceIDs: [NetworkAssistRequest.currentMeasurementEvidenceID(current.id)],
                recommendation: recommendation
            )
        )
        let viewModel = AssistViewModel(assistProvider: provider)

        await viewModel.load(currentMeasurement: current, failureSignal: nil)

        guard case .success(let data) = viewModel.state else {
            return XCTFail("A resposta respondida deveria produzir sucesso")
        }
        XCTAssertEqual(data.recommendation?.steps, recommendation.steps)
    }

    private func measurement(id: UUID) -> NetworkMeasurement {
        NetworkMeasurement(
            id: id,
            outcome: .complete,
            downloadMbps: 120,
            uploadMbps: 30,
            latencyMs: 18
        )
    }
}

private struct StubAssistProvider: NetworkAssistProviding {
    let response: NetworkAssistResponse

    func answer(_ context: NetworkAssistContext) async throws -> NetworkAssistResponse {
        response
    }

    func streamAnswer(_ context: NetworkAssistContext) -> AsyncThrowingStream<NetworkAssistStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.completed(response))
            continuation.finish()
        }
    }
}

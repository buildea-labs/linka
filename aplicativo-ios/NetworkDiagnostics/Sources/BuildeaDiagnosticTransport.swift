import Foundation
import NetworkAssist
import NetworkCore

public struct BuildeaDiagnosticTransport: NetworkAssistTransport {
    public let api: BuildeaDiagnosticAPI
    private let coordinator = DiagnosticCopyCoordinator()

    public init(api: BuildeaDiagnosticAPI) {
        self.api = api
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        let ndsResponse = try await api.evaluate(request.currentMeasurement, requestAI: false)
        
        guard let recommendation = ndsResponse.recommendation else {
            return NetworkAssistResponse(
                text: "Não consegui gerar um diagnóstico definitivo no momento.",
                disposition: .insufficientEvidence,
                evidenceIDs: []
            )
        }
        
        // Extract score and findings properly depending on where they are in NDSResponse
        // Let's assume they are top level, or from the first result
        let score = ndsResponse.results?.first?.result?.score
        let findings = ndsResponse.results?.compactMap { $0.result?.findings }.flatMap { $0 } ?? []

        let input = DiagnosticCopyInput(
            recommendationTitle: recommendation.title,
            recommendationDescription: recommendation.description,
            score: score,
            findings: findings
        )
        
        let copy = await coordinator.resolveCopy(for: input)
        
        let evidenceIDs = [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
        
        return NetworkAssistResponse(
            text: copy.title,
            longText: copy.summary,
            disposition: .answered,
            evidenceIDs: evidenceIDs
        )
    }
}

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
        let ndsResponse = try await api.evaluate(request.currentMeasurement, requestAI: true)
        
        // Extract score and veredicto properly from the scoring module
        let scoringModule = ndsResponse.results?.first(where: { $0.module == "scoring" })?.result
        let score = scoringModule?.score
        let veredicto = scoringModule?.veredicto
        let findings = ndsResponse.results?.compactMap { $0.cards }.flatMap { $0 } ?? []

        guard let recommendation = ndsResponse.recommendation else {
            // Trata cenários onde recommendation == null
            let isHealthyScore = veredicto == "bom" || veredicto == "excelente"
            let hasProblemCards = findings.contains { $0.status == "attention" || $0.status == "critical" }
            
            if isHealthyScore && !hasProblemCards {
                return NetworkAssistResponse(
                    text: "Seu resultado está bom. Não encontrei nada que exija atenção agora.",
                    disposition: .answered,
                    evidenceIDs: [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
                )
            } else {
                return NetworkAssistResponse(
                    text: "Não há dados suficientes para concluir.",
                    disposition: .insufficientEvidence,
                    evidenceIDs: []
                )
            }
        }

        let aiExplanation = ndsResponse.results?.first(where: { $0.module == "ai" })?.result?.explanation

        let input = DiagnosticCopyInput(
            recommendationTitle: recommendation.title,
            recommendationDescription: recommendation.description,
            score: score,
            findings: findings,
            aiTitle: aiExplanation?.tituloAmigavel,
            aiSummary: aiExplanation?.resumoTecnicoTraduzido
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

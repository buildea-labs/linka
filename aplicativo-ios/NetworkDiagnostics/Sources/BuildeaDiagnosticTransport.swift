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

        let aiExplanation = ndsResponse.results?.first(where: { $0.module == "ai" })?.result?.explanation

        let input = DiagnosticCopyInput(
            recommendationTitle: ndsResponse.recommendation?.title,
            recommendationDescription: ndsResponse.recommendation?.description,
            score: score,
            findings: findings,
            aiTitle: aiExplanation?.tituloAmigavel,
            aiSummary: aiExplanation?.resumoTecnicoTraduzido,
            veredicto: veredicto
        )
        
        let copy = await coordinator.resolveCopy(for: input)
        
        let evidenceIDs = [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
        
        let headerStatus = (veredicto == "bom" || veredicto == "excelente") ? "✓ TUDO CERTO" : "⚠ PRECISA DE ATENÇÃO"
        
        var parsedRecommendation: NetworkAssistRecommendation? = nil
        if let rec = ndsResponse.recommendation {
            parsedRecommendation = NetworkAssistRecommendation(title: rec.title, description: rec.description)
        }
        
        var mappedDimensions: [NetworkAssistDimension]? = nil
        if let dimensoes = scoringModule?.dimensoes, !dimensoes.isEmpty {
            mappedDimensions = dimensoes.map { NetworkAssistDimension(name: $0.nome, status: $0.status) }
        }
        
        return NetworkAssistResponse(
            text: copy.title,
            longText: copy.summary,
            disposition: .answered,
            evidenceIDs: evidenceIDs,
            suggestions: nil,
            headerStatus: headerStatus,
            title: copy.title,
            summary: copy.summary,
            recommendation: parsedRecommendation,
            dimensions: mappedDimensions
        )
    }
}

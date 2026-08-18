import Foundation
import NetworkAssist
import NetworkCore

/// Transport de fallback que delega 100% da avaliação e geração de texto ao
/// Network Diagnostics Service remoto.
public struct BuildeaDiagnosticTransport: NetworkAssistTransport {
    public let api: BuildeaDiagnosticAPI

    public init(api: BuildeaDiagnosticAPI) {
        self.api = api
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        let ndsResponse = try await api.evaluate(request.currentMeasurement, requestAI: true)
        
        guard let explanation = ndsResponse.explanation, let primary = explanation.titulo_amigavel else {
            return NetworkAssistResponse(
                text: "Não consegui gerar uma resposta com a IA no momento.",
                disposition: .insufficientEvidence,
                evidenceIDs: []
            )
        }
        
        let evidenceIDs = [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
        
        return NetworkAssistResponse(
            text: primary,
            longText: explanation.resumo_tecnico_traduzido,
            disposition: .answered,
            evidenceIDs: evidenceIDs
        )
    }
}

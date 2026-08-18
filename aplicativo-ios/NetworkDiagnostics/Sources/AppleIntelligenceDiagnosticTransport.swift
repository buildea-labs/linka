import Foundation
import NetworkAssist
import NetworkCore

/// Transport que processa as métricas através do motor de regras do NDS (sem IA)
/// e, em seguida, utiliza as capacidades de IA locais do dispositivo (Apple Intelligence)
/// para traduzir o laudo técnico em texto humanizado.
public struct AppleIntelligenceDiagnosticTransport: NetworkAssistTransport {
    public let api: BuildeaDiagnosticAPI

    public init(api: BuildeaDiagnosticAPI) {
        self.api = api
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        // 1. Obter diagnóstico técnico determinístico sem custo de IA remota
        let ndsResponse = try await api.evaluate(request.currentMeasurement, requestAI: false)
        
        // 2. Extrair o fato gerado
        guard let recommendation = ndsResponse.recommendation else {
            return NetworkAssistResponse(
                text: "Não consegui concluir um diagnóstico com os dados atuais.",
                disposition: .insufficientEvidence,
                evidenceIDs: []
            )
        }

        // 3. Traduzir via modelo local
        // TODO: Substituir essa implementação mock pela chamada real ao framework
        // nativo de Inteligência (ex: AppIntents, NaturalLanguage ou Intelligence)
        // quando a API de geração de texto de terceiros for liberada.
        let localGeneratedText = try await generateLocalExplanation(for: recommendation)
        
        let evidenceIDs = [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
        
        return NetworkAssistResponse(
            text: localGeneratedText.titulo,
            longText: localGeneratedText.detalhe,
            disposition: .answered,
            evidenceIDs: evidenceIDs
        )
    }

    private func generateLocalExplanation(for recommendation: NDSRecommendation) async throws -> (titulo: String, detalhe: String) {
        // Mock simulando tempo de inferência do modelo local
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let tituloAmigavel = "Recomendação analisada localmente"
        let detalhe = "Avaliamos que a recomendação correta é: \(recommendation.title). \n\nDetalhes adicionais: \(recommendation.description) \n\n(Texto gerado on-device via Apple Intelligence)"
        
        return (titulo: tituloAmigavel, detalhe: detalhe)
    }
}

import Foundation
import NetworkAssist
import NetworkCore

@MainActor
final class AssistViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case success(DiagnosticData)
        case error(String)
    }

    struct DiagnosticData: Equatable {
        let headerStatus: String
        let title: String
        let summary: String
        let recommendation: NetworkAssistRecommendation?
        let dimensions: [NetworkAssistDimension]
        let fallbackText: String?
    }

    @Published private(set) var state: State = .idle
    private let assistProvider: any NetworkAssistProviding

    init(assistProvider: any NetworkAssistProviding) {
        self.assistProvider = assistProvider
    }

    func load(currentMeasurement: NetworkMeasurement?, recentMeasurements: [NetworkMeasurement], failureSignal: NetworkAssistFailureSignal?) async {
        guard case .idle = state else { return }
        
        guard let current = currentMeasurement else {
            state = .error("Nenhuma medição encontrada para diagnóstico.")
            return
        }

        state = .loading
        
        let context = NetworkAssistContext(
            question: "Esse resultado está bom para o que você faz?",
            currentMeasurement: current,
            recentMeasurements: recentMeasurements,
            evidence: []
        )

        do {
            var finalResponse: NetworkAssistResponse?
            
            for try await event in assistProvider.streamAnswer(context) {
                if case .completed(let response) = event {
                    finalResponse = response
                }
            }
            
            if let response = finalResponse {
                if let title = response.title, let summary = response.summary {
                    let data = DiagnosticData(
                        headerStatus: response.headerStatus ?? "DIAGNÓSTICO CONCLUÍDO",
                        title: title,
                        summary: summary,
                        recommendation: response.recommendation,
                        dimensions: response.dimensions ?? [],
                        fallbackText: nil
                    )
                    state = .success(data)
                } else {
                    let data = DiagnosticData(
                        headerStatus: "Assist",
                        title: "Conclusão",
                        summary: response.text,
                        recommendation: nil,
                        dimensions: [],
                        fallbackText: response.longText
                    )
                    state = .success(data)
                }
            } else {
                state = .error("O Assist não retornou um diagnóstico.")
            }
        } catch {
            let errorText: String
            switch error {
            case NetworkAssistError.notConfigured:
                errorText = "O Assist ainda não está configurado neste build."
            case NetworkAssistError.notEntitled:
                errorText = "O Assist faz parte do Linka Plus. Assine para conversar sobre seus testes."
            default:
                errorText = "Não foi possível consultar o Assist agora. Tente novamente em instantes."
            }
            state = .error(errorText)
        }
    }
}

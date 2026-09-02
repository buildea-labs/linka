import Foundation
import NetworkAssist
import NetworkCore
import NetworkInsights

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
    private static var analysisCache: [UUID: DiagnosticData] = [:]

    public static func clearCache() {
        analysisCache.removeAll()
    }

    init(assistProvider: any NetworkAssistProviding) {
        self.assistProvider = assistProvider
    }

    func load(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        usageContext: String? = nil,
        failureSignal: NetworkAssistFailureSignal?,
        objective: String? = nil,
        subcategory: String? = nil,
        reportedProblem: String? = nil
    ) async {
        guard case .idle = state else { return }

        guard let current = currentMeasurement else {
            state = .error("Nenhuma medição encontrada para diagnóstico.")
            return
        }

        // Se já foi diagnosticado para esta mesma medição, recupera do cache imediatamente
        if let cached = Self.analysisCache[current.id] {
            state = .success(cached)
            return
        }

        state = .loading

        let context = Self.makeContext(
            currentMeasurement: current,
            recentMeasurements: recentMeasurements,
            usageContext: usageContext,
            objective: objective,
            subcategory: subcategory,
            reportedProblem: reportedProblem
        )

        do {
            var finalResponse: NetworkAssistResponse?
            
            for try await event in assistProvider.streamAnswer(context) {
                if case .completed(let response) = event {
                    finalResponse = response
                }
            }
            
            if let response = finalResponse {
                guard response.disposition == .answered else {
                    state = .error(Self.message(for: response.disposition))
                    return
                }

                if let title = response.title, let summary = response.summary {
                    let data = DiagnosticData(
                        headerStatus: response.headerStatus ?? "DIAGNÓSTICO CONCLUÍDO",
                        title: title,
                        summary: summary,
                        recommendation: response.recommendation,
                        dimensions: response.dimensions ?? [],
                        fallbackText: nil
                    )
                    Self.analysisCache[current.id] = data
                    state = .success(data)
                } else {
                    let data = DiagnosticData(
                        headerStatus: "Assist",
                        title: "Conclusão",
                        summary: response.text,
                        recommendation: response.recommendation,
                        dimensions: response.dimensions ?? [],
                        fallbackText: response.longText
                    )
                    Self.analysisCache[current.id] = data
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
                #if DEBUG
                errorText = "Erro (\(error)): \(error.localizedDescription)"
                #else
                errorText = "Não foi possível consultar o Assist agora. Tente novamente em instantes."
                #endif
            }
            state = .error(errorText)
        }
    }

    /// Monta somente o contexto que a tela realmente possui. Histórico é
    /// limitado ao contrato do Assist, e uma finalidade de uso só passa se
    /// tiver sido informada por uma superfície que a coletou.
    static func makeContext(
        currentMeasurement: NetworkMeasurement,
        recentMeasurements: [NetworkMeasurement],
        usageContext: String? = nil,
        objective: String? = nil,
        subcategory: String? = nil,
        reportedProblem: String? = nil
    ) -> NetworkAssistContext {
        let recent = recentMeasurements
            .filter { $0.id != currentMeasurement.id }
            .prefix(20)

        let currentEvidence = NetworkAssistEvidence(
            id: NetworkAssistRequest.currentMeasurementEvidenceID(currentMeasurement.id),
            kind: .metric,
            metricKey: "measurement",
            sourceMeasurementIDs: [currentMeasurement.id]
        )
        let recentEvidence = recent.map { measurement in
            NetworkAssistEvidence(
                id: NetworkAssistRequest.recentMeasurementEvidenceID(measurement.id),
                kind: .metric,
                metricKey: "measurement",
                sourceMeasurementIDs: [measurement.id]
            )
        }

        var allEvidence = [currentEvidence] + recentEvidence
        
        let responsivenessResult = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: currentMeasurement.latencyMs,
            loadedDownloadLatencyMs: currentMeasurement.loadedLatencyMs,
            loadedUploadLatencyMs: currentMeasurement.loadedLatencyUploadMs
        )
        if responsivenessResult.category != .notAssessed {
            allEvidence.append(NetworkAssistEvidence(
                id: "responsiveness:\(currentMeasurement.id.uuidString.lowercased())",
                kind: .statistic,
                metricKey: "loadResponsivenessCategory",
                direction: responsivenessResult.category.rawValue,
                sourceMeasurementIDs: [currentMeasurement.id]
            ))
            if let downloadDelta = responsivenessResult.downloadComparison.absoluteDelta {
                allEvidence.append(NetworkAssistEvidence(
                    id: "responsiveness-dl-delta:\(currentMeasurement.id.uuidString.lowercased())",
                    kind: .comparison,
                    metricKey: "loadedLatencyMsDelta",
                    value: downloadDelta,
                    unit: "ms",
                    sourceMeasurementIDs: [currentMeasurement.id]
                ))
            }
            if let uploadDelta = responsivenessResult.uploadComparison.absoluteDelta {
                allEvidence.append(NetworkAssistEvidence(
                    id: "responsiveness-ul-delta:\(currentMeasurement.id.uuidString.lowercased())",
                    kind: .comparison,
                    metricKey: "loadedLatencyUploadMsDelta",
                    value: uploadDelta,
                    unit: "ms",
                    sourceMeasurementIDs: [currentMeasurement.id]
                ))
            }
        }

        return NetworkAssistContext(
            question: "Interprete esta medição com os dados disponíveis.",
            currentMeasurement: currentMeasurement,
            recentMeasurements: Array(recent),
            evidence: allEvidence,
            usageContext: usageContext?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            objective: objective,
            subcategory: subcategory,
            reportedProblem: reportedProblem?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }

    private static func message(for disposition: NetworkAssistDisposition) -> String {
        switch disposition {
        case .insufficientEvidence:
            return "Ainda não há dados suficientes para uma interpretação confiável."
        case .requiresDiagnosis:
            return "Esta pergunta exige uma investigação que o Linka não pode concluir só com esta medição."
        case .unsupported:
            return "O Assist não consegue responder a esse tipo de solicitação."
        case .answered:
            return ""
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

import Foundation
import NetworkAssist
import NetworkCore
import NetworkInsights

public struct BuildeaDiagnosticTransport: NetworkAssistTransport {
    public let api: BuildeaDiagnosticAPI
    private let coordinator = DiagnosticCopyCoordinator()

    public init(api: BuildeaDiagnosticAPI) {
        self.api = api
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        let diagnosticContext = request.usageContext.map {
            NDSRequest.DiagnosticContext(objective: $0)
        }
        let historical = Self.historicalSnapshot(
            current: request.currentMeasurement,
            recent: request.recentMeasurements,
            referenceDate: Date(),
            lookbackDays: api.configuration.historyLookbackDays
        )
        let ndsResponse = try await api.evaluate(
            request.currentMeasurement,
            requestAI: true,
            diagnosticContext: diagnosticContext,
            historical: historical
        )
        
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
        
        let evidenceIDs = [
            NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)
        ] + request.recentMeasurements.map {
            NetworkAssistRequest.recentMeasurementEvidenceID($0.id)
        }
        
        let headerStatus = (veredicto == "bom" || veredicto == "excelente") ? "✓ TUDO CERTO" : "⚠ PRECISA DE ATENÇÃO"
        
        var parsedRecommendation: NetworkAssistRecommendation? = nil
        if let rec = ndsResponse.recommendation {
            parsedRecommendation = NetworkAssistRecommendation(
                title: rec.title,
                description: rec.description,
                steps: rec.steps
            )
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

    static func historicalSnapshot(
        current: NetworkMeasurement,
        recent: [NetworkMeasurement],
        referenceDate: Date,
        lookbackDays: Int
    ) -> NDSRequest.Historical? {
        let lowerBound = referenceDate.addingTimeInterval(-Double(max(1, lookbackDays)) * 86_400)
        let measurements = ([current] + recent)
            .filter { $0.measuredAt >= lowerBound && NetworkMeasurementContract.isValid($0) }
        guard !measurements.isEmpty else { return nil }

        let sevenDayBound = referenceDate.addingTimeInterval(-7 * 86_400)
        let last7 = measurements.filter { $0.measuredAt >= sevenDayBound }
        let analyzer = BasicNetworkInsightsAnalyzer()
        let summary30 = try? analyzer.summarize(measurements)
        let summary7 = last7.isEmpty ? nil : try? analyzer.summarize(last7)

        func average(_ summary: NetworkInsightsSummary?, _ metric: NetworkMetric) -> Double? {
            summary?.statistics(for: metric)?.average
        }

        let historical = NDSRequest.Historical(
            avgDownload30d: average(summary30, .downloadMbps),
            avgDownload7d: average(summary7, .downloadMbps),
            avgUpload30d: average(summary30, .uploadMbps),
            avgUpload7d: average(summary7, .uploadMbps),
            avgPing30d: average(summary30, .latencyMs),
            avgPing7d: average(summary7, .latencyMs),
            tests30d: measurements.count,
            tests7d: last7.count
        )

        return [
            historical.avgDownload30d,
            historical.avgDownload7d,
            historical.avgUpload30d,
            historical.avgUpload7d,
            historical.avgPing30d,
            historical.avgPing7d
        ].contains(where: { $0 != nil }) ? historical : nil
    }
}

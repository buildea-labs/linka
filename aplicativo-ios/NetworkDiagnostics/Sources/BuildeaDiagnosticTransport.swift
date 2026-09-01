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
        // Fluxo guiado (`AssistProblemSelectionView`) tem prioridade sobre o
        // resumo de uso sintetizado (`usageContext`): quando o usuário
        // passou pela seleção, `objective`/`subcategory` são as chaves
        // fechadas do contrato v2, não um texto livre derivado da medição.
        // Sem seleção guiada, o comportamento observacional de hoje
        // continua idêntico — só `objective` (texto de `usageContext`),
        // sem `subcategory`. "Outro problema" (texto livre) chega em
        // `request.reportedProblem` sem `objective`/`subcategory` — vai só
        // como `reported_problem`, que o NDS usa como contexto adicional
        // para a IA na explicação, NUNCA para priorizar regras (isso
        // continua vindo só de objective/subcategory/métricas). Toda
        // requisição vai sempre para o endpoint v2 (`BuildeaDiagnosticAPI`
        // não tem mais fallback v1).
        let diagnosticContext: NDSRequest.DiagnosticContext?
        if let objective = request.objective {
            diagnosticContext = NDSRequest.DiagnosticContext(
                reportedProblem: request.reportedProblem,
                objective: objective,
                subcategory: request.subcategory
            )
        } else if let reportedProblem = request.reportedProblem {
            diagnosticContext = NDSRequest.DiagnosticContext(reportedProblem: reportedProblem)
        } else if let usageContext = request.usageContext {
            diagnosticContext = NDSRequest.DiagnosticContext(objective: usageContext)
        } else {
            diagnosticContext = nil
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
        
        // `effectiveResults`/`effectiveRecommendation` leem do bloco `raw`
        // quando a resposta é v2 (`raw.results`/`raw.recommendation`) e do
        // nível raiz quando é v1 — mesmo achado, mesma dimensão de
        // scoring, independente de qual contrato respondeu.
        let results = ndsResponse.effectiveResults
        let scoringModule = results?.first(where: { $0.module == "scoring" })?.result
        let score = scoringModule?.score
        let veredicto = scoringModule?.veredicto
        let findings = results?.compactMap { $0.cards }.flatMap { $0 } ?? []

        let copy: DiagnosticCopy
        if let v2Explanation = ndsResponse.explanation {
            // Contrato v2: texto já tratado pelo servidor
            // (`explanation.titulo`/`descricao`/`dados`/`acao_usuario`),
            // sem passar pelo coordenador de copy v1 (esse texto não é
            // "AI" nem "determinístico" no sentido do v1 — já chega
            // pronto). `sem_causa_identificada == true` é tratado à parte
            // (AGENTS.md §9 — nunca inventar causa sem lastro).
            copy = Self.copy(fromV2Explanation: v2Explanation)
        } else {
            let aiResult = results?.first(where: { $0.module == "ai" })?.result
            let aiExplanation = aiResult?.explanation

            let input = DiagnosticCopyInput(
                recommendationTitle: ndsResponse.effectiveRecommendation?.title,
                recommendationDescription: ndsResponse.effectiveRecommendation?.description,
                score: score,
                findings: findings,
                aiTitle: aiExplanation?.tituloAmigavel,
                aiSummary: aiExplanation?.resumoTecnicoTraduzido,
                veredicto: veredicto,
                aiSourceFindingIds: aiResult?.sourceFindingIds
            )
            copy = await coordinator.resolveCopy(for: input)
        }

        let evidenceIDs = [
            NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)
        ] + request.recentMeasurements.map {
            NetworkAssistRequest.recentMeasurementEvidenceID($0.id)
        }
        
        // headerStatus não pode olhar só o veredicto: um veredicto "bom"
        // com achados de atenção/crítico (ex.: latência oscilando) ainda
        // é "tudo certo" no header enquanto a IA descreve o problema no
        // resumo — a tela contradizia a si mesma. Mesmo critério do
        // fallback determinístico (`isHealthyScore && !hasProblemCards`).
        let hasProblemCards = findings.contains { $0.status == "attention" || $0.status == "critical" }
        let isHealthyVerdict = veredicto == "bom" || veredicto == "excelente" || (veredicto == nil && !hasProblemCards)
        let isSemCausa = ndsResponse.explanation?.semCausaIdentificada == true
        let headerStatus = (isSemCausa || (!hasProblemCards && isHealthyVerdict)) ? "✓ TUDO CERTO" : "⚠ PRECISA DE ATENÇÃO"
        
        var parsedRecommendation: NetworkAssistRecommendation? = nil
        if let v2Explanation = ndsResponse.explanation {
            // `acao_usuario` é a ação; `dados` é a evidência que sustenta
            // essa ação, mostrada em "Por que recomendamos isso?" na
            // `AssistView` — mesmo papel que `description` já cumpre para
            // uma recomendação v1. `sem_causa_identificada == true` não
            // tem ação a recomendar: nenhuma regra disparou.
            if v2Explanation.semCausaIdentificada != true, let acao = v2Explanation.acaoUsuario {
                let evidenceCards = findings.filter { card in v2Explanation.dados?.contains(card.id) == true }
                let evidenceDesc = evidenceCards.isEmpty
                    ? (v2Explanation.dados?.joined(separator: ", ") ?? "")
                    : evidenceCards.map { $0.mensagemUsuario.isEmpty ? $0.titulo : $0.mensagemUsuario }.joined(separator: " • ")

                parsedRecommendation = NetworkAssistRecommendation(
                    title: acao,
                    description: evidenceDesc,
                    steps: []
                )
            }
        } else if let rec = ndsResponse.effectiveRecommendation {
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

    /// Mensagem transparente (issue v2/objective+subcategory) para
    /// `explanation.sem_causa_identificada == true`: nenhuma regra do NDS
    /// disparou para esta medição+subcategoria. Mesmo tom direto e sem
    /// jargão do resto da `AssistView` ("Tudo certo com a conexão",
    /// "Diagnóstico inconclusivo") — nunca inventa uma causa que os dados
    /// não sustentam (AGENTS.md §9).
    static let semCausaIdentificadaSummary = "Não encontramos uma causa específica — os dados da sua conexão parecem normais."

    /// Constrói o `DiagnosticCopy` a partir do bloco `explanation` do
    /// contrato v2. `titulo`/`descricao` podem faltar mesmo sem
    /// `sem_causa_identificada` (o NDS ainda está em implementação em
    /// paralelo) — nesse caso caímos no mesmo texto transparente em vez de
    /// apresentar título/resumo vazios.
    static func copy(fromV2Explanation explanation: NDSV2Explanation) -> DiagnosticCopy {
        if explanation.semCausaIdentificada == true {
            return DiagnosticCopy(
                title: "Sem causa específica identificada",
                summary: semCausaIdentificadaSummary,
                source: .deterministic
            )
        }
        guard let titulo = explanation.titulo, let descricao = explanation.descricao else {
            return DiagnosticCopy(
                title: "Sem causa específica identificada",
                summary: semCausaIdentificadaSummary,
                source: .deterministic
            )
        }
        return DiagnosticCopy(title: titulo, summary: descricao, source: .deterministic)
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

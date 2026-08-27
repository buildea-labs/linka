import Foundation

public struct DiagnosticCopyInput: Equatable, Sendable {
    public let recommendationTitle: String?
    public let recommendationDescription: String?
    public let score: Int?
    public let findings: [NDSCard]
    public let aiTitle: String?
    public let aiSummary: String?
    public let veredicto: String?
    /// IDs dos achados que a explicação de IA (`aiTitle`/`aiSummary`) cita
    /// como evidência (issue #129) — permite recusar uma explicação que
    /// afirma problema sem nenhum achado que a sustente.
    public let aiSourceFindingIds: [String]?

    public init(
        recommendationTitle: String?,
        recommendationDescription: String?,
        score: Int?,
        findings: [NDSCard],
        aiTitle: String? = nil,
        aiSummary: String? = nil,
        veredicto: String? = nil,
        aiSourceFindingIds: [String]? = nil
    ) {
        self.recommendationTitle = recommendationTitle
        self.recommendationDescription = recommendationDescription
        self.score = score
        self.findings = findings
        self.aiTitle = aiTitle
        self.aiSummary = aiSummary
        self.veredicto = veredicto
        self.aiSourceFindingIds = aiSourceFindingIds
    }
}

public struct DiagnosticCopy: Equatable, Sendable {
    public let title: String
    public let summary: String
    public let source: CopySource
    
    public enum CopySource: String, Equatable, Sendable {
        case deterministic
        case ai
    }
}

public protocol DiagnosticCopyRenderer: Sendable {
    func render(input: DiagnosticCopyInput) async throws -> DiagnosticCopy
}

public struct DeterministicDiagnosticCopyRenderer: DiagnosticCopyRenderer {
    public init() {}
    public func render(input: DiagnosticCopyInput) async throws -> DiagnosticCopy {
        if let title = input.recommendationTitle, let desc = input.recommendationDescription {
            return DiagnosticCopy(
                title: title,
                summary: desc,
                source: .deterministic
            )
        }
        let isHealthyScore = input.veredicto == "bom" || input.veredicto == "excelente"
        let hasProblemCards = input.findings.contains { $0.status == "attention" || $0.status == "critical" }
        
        if isHealthyScore && !hasProblemCards {
            return DiagnosticCopy(
                title: "Tudo certo com a conexão",
                summary: "Seu resultado está bom. Não encontrei nada que exija atenção agora.",
                source: .deterministic
            )
        } else {
            return DiagnosticCopy(
                title: "Diagnóstico inconclusivo",
                summary: "Não há dados suficientes para concluir.",
                source: .deterministic
            )
        }
    }
}

public struct NDSAIDiagnosticCopyRenderer: DiagnosticCopyRenderer {
    public init() {}
    public func render(input: DiagnosticCopyInput) async throws -> DiagnosticCopy {
        guard let title = input.aiTitle, let summary = input.aiSummary else {
            throw NetworkDiagnosticsError.decoding("O módulo ai do NDS não retornou texto na resposta.")
        }

        // O módulo `ai` do NDS às vezes afirma um problema (veredicto não
        // bom/excelente) sem nenhum achado (`source_finding_ids`) que o
        // sustente — confirmado testando o serviço real (issue #129): uma
        // medição só com velocidade, sem nenhum achado disparado, recebeu
        // de volta um texto dizendo que a conexão "apresenta instabilidade".
        // Isso viola a própria instrução do NDS ("não invente sinais
        // ausentes") e o Linka não pode repassar essa afirmação sem lastro
        // ao usuário (AGENTS.md §9). Um veredito bom/excelente sem achado é
        // o caso normal (nada errado para citar) e continua aceito.
        let isHealthyVerdict = input.veredicto == "bom" || input.veredicto == "excelente"
        let hasSupportingEvidence = !(input.aiSourceFindingIds?.isEmpty ?? true)
        guard isHealthyVerdict || hasSupportingEvidence else {
            throw NetworkDiagnosticsError.decoding("Explicação de IA sem achado que a sustente para um veredito não saudável.")
        }

        return DiagnosticCopy(
            title: title,
            summary: summary,
            source: .ai
        )
    }
}

public struct DiagnosticCopyCoordinator: Sendable {
    private let deterministic: DeterministicDiagnosticCopyRenderer
    private let foundation: NDSAIDiagnosticCopyRenderer
    
    public init(
        deterministic: DeterministicDiagnosticCopyRenderer = DeterministicDiagnosticCopyRenderer(),
        foundation: NDSAIDiagnosticCopyRenderer = NDSAIDiagnosticCopyRenderer()
    ) {
        self.deterministic = deterministic
        self.foundation = foundation
    }
    
    public func resolveCopy(for input: DiagnosticCopyInput) async -> DiagnosticCopy {
        // Tenta primeiro a explicação de IA já incluída na resposta do NDS
        // (módulo `ai`, server-side) — não é Apple Foundation Models: essa
        // camada de IA local foi cancelada (issue #126, fechada). Cai pro
        // fallback determinístico sempre que a IA não respondeu ou (ver
        // `NDSAIDiagnosticCopyRenderer`) afirmou algo sem achado que sustente.
        if let aiCopy = try? await foundation.render(input: input) {
            return aiCopy
        }

        // Fallback determinístico
        return (try? await deterministic.render(input: input)) ?? DiagnosticCopy(
            title: input.recommendationTitle ?? "Diagnóstico inconclusivo",
            summary: input.recommendationDescription ?? "Não há dados suficientes para concluir.",
            source: .deterministic
        )
    }
}

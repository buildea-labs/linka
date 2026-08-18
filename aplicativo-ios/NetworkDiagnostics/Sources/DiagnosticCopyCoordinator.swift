import Foundation

public struct DiagnosticCopyInput: Equatable, Sendable {
    public let recommendationTitle: String?
    public let recommendationDescription: String?
    public let score: Int?
    public let findings: [NDSCard]
    public let aiTitle: String?
    public let aiSummary: String?
    public let veredicto: String?

    public init(
        recommendationTitle: String?,
        recommendationDescription: String?,
        score: Int?,
        findings: [NDSCard],
        aiTitle: String? = nil,
        aiSummary: String? = nil,
        veredicto: String? = nil
    ) {
        self.recommendationTitle = recommendationTitle
        self.recommendationDescription = recommendationDescription
        self.score = score
        self.findings = findings
        self.aiTitle = aiTitle
        self.aiSummary = aiSummary
        self.veredicto = veredicto
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
            throw NetworkDiagnosticsError.decoding("Foundation Models não retornou texto na resposta NDS.")
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
        // Try Foundation Models first
        if let aiCopy = try? await foundation.render(input: input) {
            return aiCopy
        }
        
        // Fallback to deterministic
        return (try? await deterministic.render(input: input)) ?? DiagnosticCopy(
            title: input.recommendationTitle ?? "Diagnóstico inconclusivo",
            summary: input.recommendationDescription ?? "Não há dados suficientes para concluir.",
            source: .deterministic
        )
    }
}

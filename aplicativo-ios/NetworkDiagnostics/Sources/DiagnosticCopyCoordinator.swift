import Foundation

public struct DiagnosticCopyInput: Equatable, Sendable {
    public let recommendationTitle: String
    public let recommendationDescription: String
    public let score: Int?
    public let findings: [NDSFinding]
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
        return DiagnosticCopy(
            title: input.recommendationTitle,
            summary: input.recommendationDescription,
            source: .deterministic
        )
    }
}

public struct FoundationModelsDiagnosticCopyRenderer: DiagnosticCopyRenderer {
    public init() {}
    public func render(input: DiagnosticCopyInput) async throws -> DiagnosticCopy {
        // Mock throwing "indisponível" logic for SDK not supporting Foundation Models yet
        throw NetworkDiagnosticsError.decoding("Foundation Models indisponível via SDK.")
    }
}

public struct DiagnosticCopyCoordinator: Sendable {
    private let deterministic: DeterministicDiagnosticCopyRenderer
    private let foundation: FoundationModelsDiagnosticCopyRenderer
    
    public init(
        deterministic: DeterministicDiagnosticCopyRenderer = DeterministicDiagnosticCopyRenderer(),
        foundation: FoundationModelsDiagnosticCopyRenderer = FoundationModelsDiagnosticCopyRenderer()
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
            title: input.recommendationTitle,
            summary: input.recommendationDescription,
            source: .deterministic
        )
    }
}

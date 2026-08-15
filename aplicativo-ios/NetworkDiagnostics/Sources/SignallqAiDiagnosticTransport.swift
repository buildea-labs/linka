import Foundation
import NetworkAssist
import NetworkCore

/// Transporte conversacional: envia `question` como `feedbackUsuario` para o
/// `ai-diagnosis-worker` e monta uma `NetworkAssistResponse` com o texto
/// gerado (`resumo` + `textoLaudo`).
public struct SignallqAiDiagnosticTransport: NetworkAssistTransport {
    public let configuration: NetworkDiagnosticsConfiguration
    public let httpClient: DiagnosticHTTPClient
    public let platformProvider: PlatformSignalProviding
    private let payloadBuilder = AiDiagnosisPayloadBuilder()

    public init(
        configuration: NetworkDiagnosticsConfiguration,
        httpClient: DiagnosticHTTPClient = URLSessionDiagnosticHTTPClient(),
        platformProvider: PlatformSignalProviding = NoopPlatformSignalProvider()
    ) {
        self.configuration = configuration
        self.httpClient = httpClient
        self.platformProvider = platformProvider
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        let hints = await platformProvider.currentHints()
        let payload = payloadBuilder.payload(
            question: request.question,
            current: request.currentMeasurement,
            history: request.recentMeasurements,
            platform: hints,
            appVersion: configuration.appVersion,
            platformIdentifier: configuration.platformIdentifier
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let body = try encoder.encode(payload)

        let (data, status) = try await httpClient.postJSON(
            url: configuration.aiEndpoint,
            body: body,
            timeout: configuration.requestTimeout
        )
        guard (200..<300).contains(status) else {
            throw NetworkDiagnosticsError.httpStatus(status)
        }

        let decoder = JSONDecoder()
        let result: AiDiagnosisResult
        do {
            result = try decoder.decode(AiDiagnosisResult.self, from: data)
        } catch {
            throw NetworkDiagnosticsError.decoding(String(describing: error))
        }

        return responseFrom(result: result, request: request)
    }

    private func responseFrom(
        result: AiDiagnosisResult,
        request: NetworkAssistRequest
    ) -> NetworkAssistResponse {
        // Divulgação progressiva: `resumo` (1 frase) é o texto default do card.
        // `textoLaudo` (3-5 linhas, mais técnico) vai atrás de "Ver mais".
        // Se só um dos campos veio, usa como texto principal sem "Ver mais".
        let resumo = trimmed(result.resumo)
        let laudo = trimmed(result.textoLaudo)
        let titulo = trimmed(usefulTitle(result.titulo))

        let short: String?
        let long: String?
        switch (resumo, laudo) {
        case (.some(let r), .some(let l)) where r != l:
            short = r
            long = l
        case (.some(let r), _):
            short = r
            long = nil
        case (_, .some(let l)):
            short = l
            long = nil
        default:
            short = titulo
            long = nil
        }

        let disposition: NetworkAssistDisposition
        switch (result.status ?? "").lowercased() {
        case "inconclusivo":
            disposition = .insufficientEvidence
        case "":
            disposition = (short?.isEmpty ?? true) ? .insufficientEvidence : .answered
        default:
            disposition = .answered
        }

        guard let primary = short, !primary.isEmpty else {
            return NetworkAssistResponse(
                text: "Não consegui gerar uma resposta agora.",
                disposition: .insufficientEvidence,
                evidenceIDs: []
            )
        }

        let evidenceIDs: [String] = disposition == .answered
            ? [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
            : []

        return NetworkAssistResponse(
            text: primary,
            longText: long,
            disposition: disposition,
            evidenceIDs: evidenceIDs
        )
    }

    private func trimmed(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    /// Descarta títulos genéricos que o worker devolve como placeholder do
    /// schema em modo chat (ex.: literalmente "Resposta").
    private func usefulTitle(_ titulo: String?) -> String? {
        guard let trimmed = titulo?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        let genericTitles: Set<String> = ["resposta", "diagnostico", "diagnóstico"]
        return genericTitles.contains(trimmed.lowercased()) ? nil : trimmed
    }
}

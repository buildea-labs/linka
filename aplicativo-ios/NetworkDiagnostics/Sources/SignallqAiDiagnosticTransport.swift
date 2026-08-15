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
        let text = joinNonEmpty([
            result.textoLaudo,
            result.resumo,
            result.titulo
        ])

        let disposition: NetworkAssistDisposition
        switch (result.status ?? "").lowercased() {
        case "inconclusivo":
            disposition = .insufficientEvidence
        case "":
            disposition = text.isEmpty ? .insufficientEvidence : .answered
        default:
            disposition = .answered
        }

        if text.isEmpty {
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
            text: text,
            disposition: disposition,
            evidenceIDs: evidenceIDs
        )
    }

    private func joinNonEmpty(_ parts: [String?]) -> String {
        parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}

import Foundation
import NetworkAssist
import NetworkCore

/// Transporte determinístico: consulta o motor de regras do SignallQ
/// (`signallq-diagnostic-worker`, `POST /diagnostic/evaluate`) e converte a
/// `decisao` + `recomendacoes` em `NetworkAssistResponse`.
///
/// Ignora a `question` do usuário — este worker é classificador, não
/// conversacional. Serve bem para respostas passivas (Insight, "como está
/// minha rede?"). Para perguntas em linguagem natural use
/// `SignallqAiDiagnosticTransport`.
public struct SignallqDiagnosticTransport: NetworkAssistTransport {
    public let configuration: NetworkDiagnosticsConfiguration
    public let httpClient: DiagnosticHTTPClient
    public let platformProvider: PlatformSignalProviding
    private let snapshotBuilder = DiagnosticSnapshotBuilder()

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
        let snapshot = snapshotBuilder.snapshot(
            current: request.currentMeasurement,
            history: request.recentMeasurements,
            platform: hints,
            appVersion: configuration.appVersion,
            platformIdentifier: configuration.platformIdentifier
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let body = try encoder.encode(snapshot)

        let (data, status) = try await httpClient.postJSON(
            url: configuration.rulesEndpoint,
            body: body,
            timeout: configuration.requestTimeout
        )
        guard (200..<300).contains(status) else {
            throw NetworkDiagnosticsError.httpStatus(status)
        }

        let decoder = JSONDecoder()
        let report: DiagnosticReport
        do {
            report = try decoder.decode(DiagnosticReport.self, from: data)
        } catch {
            throw NetworkDiagnosticsError.decoding(String(describing: error))
        }

        return responseFrom(report: report, request: request)
    }

    private func responseFrom(
        report: DiagnosticReport,
        request: NetworkAssistRequest
    ) -> NetworkAssistResponse {
        guard let decisao = report.decisao else {
            return NetworkAssistResponse(
                text: "Não consegui concluir um diagnóstico com os dados atuais.",
                disposition: .insufficientEvidence,
                evidenceIDs: []
            )
        }

        // Divulgação progressiva: a `mensagemUsuario` da decisão é o texto
        // principal. A recomendação e cards secundários vão para o "Ver mais".
        let primary = decisao.mensagemUsuario.trimmingCharacters(in: .whitespacesAndNewlines)
        var longParts: [String] = []
        if let recomendacao = decisao.recomendacao?.trimmingCharacters(in: .whitespacesAndNewlines),
           !recomendacao.isEmpty {
            longParts.append(recomendacao)
        }
        for card in report.recomendacoes ?? [] {
            let msg = card.mensagemUsuario.trimmingCharacters(in: .whitespacesAndNewlines)
            if !msg.isEmpty { longParts.append(msg) }
        }
        let long = longParts.isEmpty ? nil : longParts.joined(separator: "\n\n")

        let disposition = mapDisposition(status: decisao.status, podeConcluir: decisao.podeConcluir)
        let evidenceIDs = defaultEvidenceIDs(for: request, disposition: disposition)

        return NetworkAssistResponse(
            text: primary.isEmpty ? decisao.titulo : primary,
            longText: long,
            disposition: disposition,
            evidenceIDs: evidenceIDs
        )
    }

    private func mapDisposition(status: String, podeConcluir: Bool?) -> NetworkAssistDisposition {
        switch status.lowercased() {
        case "ok", "info", "attention", "critical":
            return .answered
        case "inconclusive":
            return podeConcluir == false ? .requiresDiagnosis : .insufficientEvidence
        default:
            return .answered
        }
    }

    private func defaultEvidenceIDs(
        for request: NetworkAssistRequest,
        disposition: NetworkAssistDisposition
    ) -> [String] {
        guard disposition == .answered else { return [] }
        return [NetworkAssistRequest.currentMeasurementEvidenceID(request.currentMeasurement.id)]
    }
}

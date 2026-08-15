import Foundation

/// HTTP mínimo, injetável para testes. Não fazemos multi-part, streaming, nada.
/// Só POST JSON → JSON.
public protocol DiagnosticHTTPClient: Sendable {
    func postJSON(url: URL, body: Data, timeout: TimeInterval) async throws -> (Data, Int)
}

public struct URLSessionDiagnosticHTTPClient: DiagnosticHTTPClient {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func postJSON(url: URL, body: Data, timeout: TimeInterval) async throws -> (Data, Int) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkDiagnosticsError.transport("resposta inválida do servidor")
        }
        return (data, http.statusCode)
    }
}

public enum NetworkDiagnosticsError: Error, Equatable, Sendable {
    case transport(String)
    case httpStatus(Int)
    case decoding(String)
    case emptyResult
}

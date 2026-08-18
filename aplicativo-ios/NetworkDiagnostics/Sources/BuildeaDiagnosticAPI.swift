import Foundation
import NetworkCore

public struct BuildeaDiagnosticAPI: Sendable {
    public let configuration: NetworkDiagnosticsConfiguration
    public let httpClient: DiagnosticHTTPClient
    public let platformProvider: PlatformSignalProviding
    private let builder = NDSRequestBuilder()

    public init(
        configuration: NetworkDiagnosticsConfiguration,
        httpClient: DiagnosticHTTPClient = URLSessionDiagnosticHTTPClient(),
        platformProvider: PlatformSignalProviding = NoopPlatformSignalProvider()
    ) {
        self.configuration = configuration
        self.httpClient = httpClient
        self.platformProvider = platformProvider
    }

    public func evaluate(_ measurement: NetworkMeasurement, requestAI: Bool) async throws -> NDSResponse {
        let hints = await platformProvider.currentHints()
        let payload = builder.buildRequest(
            current: measurement,
            platformHints: hints,
            appVersion: configuration.appVersion,
            platformIdentifier: configuration.platformIdentifier,
            requestAI: requestAI
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let body = try encoder.encode(payload)

        print("\n--- NDS REQUEST ---")
        print("URL: \(configuration.rulesEndpoint.absoluteString)")
        print("TOKEN INJECTED: \(configuration.bearerToken?.prefix(10) ?? "nil")...")

        // Nota: Assumimos que a rulesEndpoint agora aponta para /v1/diagnostics/evaluate
        let (data, status) = try await httpClient.postJSON(
            url: configuration.rulesEndpoint,
            body: body,
            timeout: configuration.requestTimeout,
            bearerToken: configuration.bearerToken
        )
        guard (200..<300).contains(status) else {
            throw NetworkDiagnosticsError.httpStatus(status)
        }

        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(NDSResponse.self, from: data)
            if let str = String(data: data, encoding: .utf8) {
                print("NDS RESPONSE (HTTP \(status)): \(str)")
            }
            return decoded
        } catch {
            print("BuildeaDiagnosticAPI decoding error: \(error)")
            if let str = String(data: data, encoding: .utf8) {
                print("Response data: \(str)")
            }
            throw NetworkDiagnosticsError.decoding(String(describing: error))
        }
    }
}

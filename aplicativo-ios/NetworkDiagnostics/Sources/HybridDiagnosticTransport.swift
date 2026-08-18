import Foundation
import NetworkAssist

/// Coordenador que decide o meio de processamento. Tenta utilizar a Inteligência
/// Apple local primariamente, e aciona o fallback remoto em caso de hardware não suportado
/// ou falha de inferência.
public struct HybridDiagnosticTransport: NetworkAssistTransport {
    public let localTransport: AppleIntelligenceDiagnosticTransport
    public let remoteTransport: BuildeaDiagnosticTransport

    public init(localTransport: AppleIntelligenceDiagnosticTransport, remoteTransport: BuildeaDiagnosticTransport) {
        self.localTransport = localTransport
        self.remoteTransport = remoteTransport
    }

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        if deviceSupportsAppleIntelligence() {
            do {
                return try await localTransport.answer(request)
            } catch {
                // Em caso de falha no modelo local (ex: timeout, erro interno), tenta fallback.
                return try await remoteTransport.answer(request)
            }
        } else {
            return try await remoteTransport.answer(request)
        }
    }

    private func deviceSupportsAppleIntelligence() -> Bool {
        // TODO: Substituir por verificação real do iOS 18 (ex: via Gestalt ou capabilities
        // do novo framework Intelligence) quando disponível.
        // Simulamos o suporte:
        return ProcessInfo.processInfo.environment["FORCE_APPLE_INTELLIGENCE"] == "1"
    }
}

import Foundation
import NetworkCore
import NetworkDiagnostics
import LinkaEngine
import MeasurementHistory

@MainActor
public final class AssistDiagnosticOrchestrator {
    private let speedTestEngine = SpeedTestCore()
    
    public init() {}
    
    public func runSpeedTestInline(
        progressCallback: @escaping (MeasurementState) -> Void
    ) async throws -> NetworkMeasurement {
        var lastState: MeasurementState? = nil
        let stream = await speedTestEngine.runTest()
        for try await state in stream {
            lastState = state
            progressCallback(state)
        }
        
        guard let finalState = lastState,
              let dl = finalState.downloadSpeed,
              let ul = finalState.uploadSpeed,
              let p = finalState.ping else {
            throw NSError(domain: "LinkaEngineError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Teste incompleto"])
        }
        
        return NetworkMeasurement(
            outcome: .complete,
            downloadMbps: dl,
            uploadMbps: ul,
            latencyMs: p,
            jitterMs: finalState.jitter ?? 0.0,
            packetLossPercent: 0.0,
            loadedLatencyMs: nil,
            durationMs: 10000,
            connectionKind: .wifi,
            wifiBandGHz: nil,
            networkIdentifier: "Inline Assist Test",
            serverIdentifier: "Auto",
            engineVersion: "1.0",
            location: nil
        )
    }
    
    public func runDiagnostics(on measurement: NetworkMeasurement) async throws -> String {
        let config = NetworkDiagnosticsConfiguration(
            rulesEndpoint: URL(string: "https://api.buildea.com/v1/diagnostics/evaluate")!,
            bearerToken: nil,
            requestTimeout: 15.0,
            appVersion: "1.0",
            platformIdentifier: "iOS"
        )
        let api = BuildeaDiagnosticAPI(configuration: config)
        
        do {
            let response = try await api.evaluate(measurement, requestAI: true)
            var report = ""
            if let rec = response.recommendation {
                report += "Recomendação: \(rec.title) - \(rec.description)\n"
            }
            if let results = response.results {
                for result in results {
                    report += "Módulo \(result.module ?? ""): Pontuação \(result.score ?? 0).\n"
                }
            }
            return report.isEmpty ? "Diagnóstico concluído sem observações notáveis." : report
        } catch {
            return "Falha ao rodar diagnóstico: \(error.localizedDescription)"
        }
    }
}

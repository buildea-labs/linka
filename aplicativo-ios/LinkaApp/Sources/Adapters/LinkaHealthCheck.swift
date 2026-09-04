import Foundation
import Network
import Combine
import LinkaEngine

@MainActor
public final class LinkaHealthCheck: ObservableObject {
    @Published public private(set) var statusText: String = "Verificando rede..."
    @Published public private(set) var isOnline: Bool = false
    @Published public private(set) var dnsMs: Double?
    @Published public private(set) var pingMs: Double?
    @Published public private(set) var jitterMs: Double?
    @Published public private(set) var httpMs: Double?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.linka.healthcheck")
    private var isRunning = false
    private var healthTask: Task<Void, Never>?

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let online = path.status == .satisfied
                self.isOnline = online
                if online {
                    self.statusText = "Conectado. Analisando..."
                    self.runMetrics()
                } else if path.status == .requiresConnection {
                    self.statusText = "Requer conexão"
                    self.clearMetrics()
                } else {
                    self.statusText = "Sem internet"
                    self.clearMetrics()
                }
            }
        }
        monitor.start(queue: queue)
    }

    public func stop() {
        isRunning = false
        healthTask?.cancel()
        healthTask = nil
        monitor.cancel()
    }
    
    private func clearMetrics() {
        dnsMs = nil
        pingMs = nil
        jitterMs = nil
        httpMs = nil
    }

    private func runMetrics() {
        healthTask?.cancel()
        healthTask = Task {
            // DNS
            let dns = await SpeedTestCore.resolveDNS()
            
            // Ping and Jitter (via performPingTest exposing PingOutcome)
            let pingOutcome = await SpeedTestCore.performPingTest()
            
            // HTTP / TLS / TCP (via performLoadedLatencyProbe)
            let httpLatency = await SpeedTestCore.performLoadedLatencyProbe()
            
            guard !Task.isCancelled else { return }
            
            self.dnsMs = dns
            self.httpMs = httpLatency
            
            if case .measured(let latency, let jitter, let loss) = pingOutcome {
                self.pingMs = latency
                self.jitterMs = jitter
                
                var details = [String]()
                if let p = self.pingMs, p > 0 { details.append("Ping: \(Int(p))ms") }
                if let j = self.jitterMs, j > 0 { details.append("Jitter: \(Int(j))ms") }
                if let d = self.dnsMs { details.append("DNS: \(Int(d))ms") }
                
                if details.isEmpty {
                    self.statusText = "Conectado"
                } else {
                    self.statusText = details.joined(separator: " • ")
                }
            } else {
                self.statusText = "Conectado"
            }
        }
    }
}

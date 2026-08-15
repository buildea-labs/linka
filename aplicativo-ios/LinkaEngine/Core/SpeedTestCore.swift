import Foundation
import Network

/// Contador thread-safe de bytes trafegados por fase. Isolamento via actor
/// (mais confiável que NSLock + delegate custom em iOS 26+).
actor ByteCounter {
    private var value: Int64 = 0
    func add(_ n: Int64) { value += n }
    func total() -> Int64 { value }
}

/// Abstrai a origem do dado bruto de provedor (hoje ipinfo.io) para permitir
/// injeção em teste, sem acoplar `SpeedTestCore` a `URLSession` diretamente.
public protocol ProviderOrgLookup: Sendable {
    /// Retorna o campo `org` bruto (ex.: "AS27699 TELEFÔNICA BRASIL S.A")
    /// ou `nil` se a resposta não trouxer o dado. Lança em erro de rede.
    func fetchOrg() async throws -> String?
}

/// Implementação real: consulta https://ipinfo.io/json.
public struct IPInfoOrgLookup: ProviderOrgLookup {
    public init() {}

    public func fetchOrg() async throws -> String? {
        guard let url = URL(string: "https://ipinfo.io/json") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["org"] as? String
    }
}

public actor SpeedTestCore {

    private let providerLookup: ProviderOrgLookup
    private let providerEnrichmentTimeout: TimeInterval

    /// - Parameters:
    ///   - providerLookup: fonte do dado bruto de provedor. Injetável para testes;
    ///     produção usa `IPInfoOrgLookup()` por padrão.
    ///   - providerEnrichmentTimeout: teto de tempo, em segundos, dedicado exclusivamente
    ///     ao enriquecimento de provedor. Roda em paralelo à medição, nunca soma ao
    ///     tempo de nenhuma fase (ping/download/upload).
    public init(
        providerLookup: ProviderOrgLookup = IPInfoOrgLookup(),
        providerEnrichmentTimeout: TimeInterval = 2.0
    ) {
        self.providerLookup = providerLookup
        self.providerEnrichmentTimeout = providerEnrichmentTimeout
    }

    /// Starts the speed test and yields updates via an AsyncThrowingStream
    public func runTest() -> AsyncThrowingStream<MeasurementState, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var state = MeasurementState(progress: 0.0, phase: .ping)

                    let testStart = Date()

                    let monitor = NWPathMonitor()
                    let queue = DispatchQueue(label: "NetworkMonitor")
                    monitor.start(queue: queue)

                    // Small delay to allow NWPathMonitor to fetch the initial path
                    try? await Task.sleep(nanoseconds: 100_000_000)

                    if monitor.currentPath.usesInterfaceType(.wifi) {
                        state.networkType = "Wi-Fi"
                    } else if monitor.currentPath.usesInterfaceType(.cellular) {
                        state.networkType = "Rede móvel"
                    } else {
                        state.networkType = "Desconhecido"
                    }
                    monitor.cancel()

                    // Descoberta de provedor (ipinfo.io) desacoplada do caminho crítico:
                    // dispara como Task detached em paralelo ao ping/download/upload e
                    // nunca bloqueia nenhum yield nem compete pelo executor do ator com
                    // as fases de medição. Tem timeout próprio, bem menor que qualquer
                    // fase — se falhar ou estourar o prazo, o resultado segue válido sem
                    // provedor (nil), sem inventar "Desconhecido".
                    let providerTask = Task.detached(priority: .utility) { [providerLookup, providerEnrichmentTimeout] in
                        await SpeedTestCore.resolveProviderName(
                            lookup: providerLookup,
                            timeout: providerEnrichmentTimeout
                        )
                    }

                    continuation.yield(state)

                    // Measure Ping and Packet Loss
                    let (pingMs, jitterMs, lossPercent) = await performPingTest()

                    state.ping = pingMs
                    state.jitter = jitterMs
                    state.packetLossPercent = lossPercent
                    state.phase = .download
                    state.progress = 0.1
                    continuation.yield(state)

                    // ----------------------------------------------------
                    // Measure Download
                    // 18s duration, 4 streams, 10MB chunk. Chunks menores +
                    // menos streams reduzem drasticamente a chance de tomar
                    // 429 do Cloudflare em uso real (cada request pesa 60%
                    // menos e a rajada por segundo cai pela metade).
                    // ----------------------------------------------------
                    let downloadSpeed = try await runPhaseTimeBased(
                        phase: .download,
                        duration: 18.0,
                        streams: 4,
                        bytes: 10_000_000, // 10 MB
                        state: &state,
                        continuation: continuation,
                        testStart: testStart
                    )

                    state.downloadSpeed = downloadSpeed
                    state.phase = .upload
                    state.progress = 0.5
                    continuation.yield(state)

                    // Pausa dramática para o respiro visual e percepção de mudança de fase
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    // ----------------------------------------------------
                    // Measure Upload
                    // 18s duration, 4 streams, 5MB chunk. Mesmo motivo do
                    // download: agressividade reduzida pra fugir de 429.
                    // ----------------------------------------------------
                    let uploadSpeed = try await runPhaseTimeBased(
                        phase: .upload,
                        duration: 18.0,
                        streams: 4,
                        bytes: 5_000_000, // 5 MB
                        state: &state,
                        continuation: continuation,
                        testStart: testStart
                    )

                    state.uploadSpeed = uploadSpeed

                    // Anexa o provedor somente aqui, na virada para o resultado final.
                    // A essa altura download (18s) + upload (18s) já consumiram muito
                    // mais tempo que o timeout de enriquecimento (2s por padrão), então
                    // a Task já terminou (sucesso, timeout ou falha) e este await não
                    // introduz espera real nem atrasa o resultado. Se por algum motivo
                    // ainda estiver pendente, o próprio timeout interno da Task garante
                    // que ela não segura o resultado além do prazo dedicado ao enriquecimento.
                    state.provider = await providerTask.value

                    state.phase = .result
                    state.progress = 1.0
                    state.duration = Date().timeIntervalSince(testStart)
                    continuation.yield(state)

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func runPhaseTimeBased(
        phase: Phase,
        duration: TimeInterval,
        streams: Int,
        bytes: Int,
        state: inout MeasurementState,
        continuation: AsyncThrowingStream<MeasurementState, Error>.Continuation,
        testStart: Date
    ) async throws -> Double {

        let phaseStart = Date()
        let sampleInterval = 0.3 // 300ms
        let counter = ByteCounter()

        // Random payload for upload to avoid compression caching at network level.
        let payload = phase == .upload ? generateRandomPayload(size: bytes) : nil

        // Ephemeral session sem delegate custom. Confiamos na API async
        // de URLSession pra contar bytes por requisição concluída — muito
        // mais confiável que o esquema anterior de delegate + NSLock, que
        // silenciosamente não contabilizava dados de download em iOS 26.
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.httpMaximumConnectionsPerHost = streams + 2
        config.timeoutIntervalForRequest = 30.0
        let session = URLSession(configuration: config)

        let workersTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<streams {
                    group.addTask {
                        // Backoff progressivo quando o servidor devolve 429 —
                        // Cloudflare rate-limita agressivamente esses endpoints
                        // sob rajada. Começa em 100ms e cresce até 2s.
                        var backoffMs: UInt64 = 100
                        while Date().timeIntervalSince(phaseStart) < duration && !Task.isCancelled {
                            do {
                                let bytesGained: Int64
                                let statusCode: Int
                                if phase == .download {
                                    guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") else { return }
                                    let (data, response) = try await session.data(from: url)
                                    statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                                    bytesGained = statusCode == 200 ? Int64(data.count) : 0
                                } else {
                                    guard let url = URL(string: "https://speed.cloudflare.com/__up") else { return }
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "POST"
                                    guard let payload else { return }
                                    let (_, response) = try await session.upload(for: request, from: payload)
                                    statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                                    bytesGained = statusCode == 200 ? Int64(payload.count) : 0
                                }
                                if bytesGained > 0 {
                                    await counter.add(bytesGained)
                                    backoffMs = 100  // sucesso — reseta backoff
                                } else if statusCode == 429 || statusCode >= 500 {
                                    // Rate-limit ou erro upstream — recua antes de tentar de novo.
                                    try? await Task.sleep(nanoseconds: backoffMs * 1_000_000)
                                    backoffMs = min(backoffMs * 2, 2_000)
                                }
                            } catch {
                                // Erros transientes de rede — segue tentando até a fase terminar.
                            }
                        }
                    }
                }
            }
        }

        var mbpsSamples: [Double] = []
        var smoothedMbps: Double = 0.0
        var lastTotal: Int64 = 0

        while Date().timeIntervalSince(phaseStart) < duration {
            try? await Task.sleep(nanoseconds: UInt64(sampleInterval * 1_000_000_000))
            if Task.isCancelled { break }

            let total = await counter.total()
            let deltaBytes = total - lastTotal
            lastTotal = total
            let instantMbps = (Double(deltaBytes) * 8.0) / sampleInterval / 1_000_000.0

            if instantMbps > 0 {
                smoothedMbps = smoothedMbps == 0 ? instantMbps : 0.3 * instantMbps + 0.7 * smoothedMbps
                mbpsSamples.append(instantMbps)

                if phase == .download {
                    state.downloadSpeed = smoothedMbps
                } else {
                    state.uploadSpeed = smoothedMbps
                }
            }

            // Progress interpolation
            let elapsed = Date().timeIntervalSince(phaseStart)
            let phaseProgress = min(elapsed / duration, 1.0)
            let baseProgress = phase == .download ? 0.1 : 0.5
            let totalPhaseRange = phase == .download ? 0.4 : 0.5
            state.progress = baseProgress + (phaseProgress * totalPhaseRange)

            continuation.yield(state)
        }

        workersTask.cancel()
        _ = await workersTask.result
        session.invalidateAndCancel()

        // Fallback: se nenhum sample instantâneo pegou nada (rede muito
        // rápida ou requisição única muito lenta), calcula pela média
        // global bytes / duração da fase — nunca retorna 0 se algum byte
        // foi contabilizado.
        let elapsedTotal = Date().timeIntervalSince(phaseStart)
        let totalBytes = await counter.total()
        let averageMbps = elapsedTotal > 0
            ? (Double(totalBytes) * 8.0) / elapsedTotal / 1_000_000.0
            : 0.0

        // Janela estável (últimos 65%) — mesma técnica do SignallQ, corta warmup TCP.
        let valid = mbpsSamples.filter { $0 > 0 }
        let stableStart = Int(ceil(Double(valid.count) * 0.35))
        let stable = valid.count > stableStart ? Array(valid[stableStart...]) : valid
        let stableAvg = stable.isEmpty ? 0.0 : stable.reduce(0, +) / Double(stable.count)

        return stableAvg > 0 ? stableAvg : averageMbps
    }

    private func generateRandomPayload(size: Int) -> Data {
        var data = Data(count: size)
        data.withUnsafeMutableBytes { buffer in
            arc4random_buf(buffer.baseAddress, size)
        }
        return data
    }

    private func performPingTest() async -> (latency: Double, jitter: Double, packetLoss: Double) {
        var latencies: [Double] = []
        var failures = 0
        let totalPings = 10

        for _ in 0..<totalPings {
            let start = Date()
            do {
                guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=0") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 1.0
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let latency = Date().timeIntervalSince(start) * 1000.0
                    latencies.append(latency)
                } else {
                    failures += 1
                }
            } catch {
                failures += 1
            }
            // Small delay between pings
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        let lossPercent = (Double(failures) / Double(totalPings)) * 100.0

        guard !latencies.isEmpty else {
            return (0.0, 0.0, lossPercent) // 100% loss
        }

        let avgLatency = latencies.reduce(0, +) / Double(latencies.count)

        // Calculate Jitter (average of differences between consecutive pings)
        var jitterSum = 0.0
        if latencies.count > 1 {
            for i in 1..<latencies.count {
                jitterSum += abs(latencies[i] - latencies[i-1])
            }
            let avgJitter = jitterSum / Double(latencies.count - 1)
            return (avgLatency, avgJitter, lossPercent)
        }

        return (avgLatency, 0.0, lossPercent)
    }

    /// Resolve o nome comercial do provedor com um timeout dedicado, isolado do
    /// orçamento de tempo de qualquer fase de medição. `nonisolated` + `static`
    /// de propósito: não precisa (nem deve) tocar o estado do ator, e assim a
    /// corrida abaixo não faz nenhum hop de volta para `SpeedTestCore`.
    ///
    /// Implementado como corrida entre a consulta real e um timer de timeout —
    /// o primeiro que terminar decide o resultado. Sucesso rápido não espera o
    /// timeout; timeout ou erro nunca produzem "Desconhecido", só `nil`.
    nonisolated static func resolveProviderName(
        lookup: ProviderOrgLookup,
        timeout: TimeInterval
    ) async -> String? {
        await withTaskGroup(of: String?.self) { group in
            group.addTask {
                do {
                    guard let org = try await lookup.fetchOrg() else { return nil }
                    return ProviderNormalizer.shared.displayName(for: org)
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(max(timeout, 0) * 1_000_000_000))
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}

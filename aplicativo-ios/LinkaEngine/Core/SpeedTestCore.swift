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

    // ----------------------------------------------------------------
    // Duração adaptativa por fase (issue #62).
    //
    // O preset anterior usava 18s fixos em download e upload, herdados do
    // preset "pesado" do SignallQ — adequado para métodos de diagnóstico
    // mais profundos, desnecessário para o objetivo do Linka (medir rápido
    // e mostrar resultado). Em vez de um teto fixo, cada fase roda até a
    // vazão amostrada convergir (ver `hasConverged`/`shouldStopPhase`),
    // respeitando sempre um piso (`phaseMinDuration`) e um teto
    // (`phaseMaxDuration`) conhecidos:
    //
    //   - `phaseMinDuration` (6s) garante amostras suficientes após o
    //     warmup de conexão TCP/TLS antes de sequer considerar encerrar —
    //     evita "convergência" espúria por poucas amostras iniciais.
    //   - `phaseMaxDuration` (18s) preserva o teto de hoje: em conexões
    //     instáveis que nunca convergem, o consumo de dados e o tempo
    //     total no pior caso não pioram em relação ao comportamento atual.
    //
    // Mesmos valores para download e upload — nenhuma evidência coletada
    // (ver PR #62) justifica um piso/teto assimétrico entre as duas fases;
    // ambas usam os mesmos 4 streams e a mesma técnica de amostragem.
    // ----------------------------------------------------------------
    private static let phaseMinDuration: TimeInterval = 6.0
    private static let phaseMaxDuration: TimeInterval = 18.0

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
                    // 6s–18s adaptativo (issue #62), 4 streams, 10MB chunk.
                    // Chunks menores + menos streams reduzem drasticamente a
                    // chance de tomar 429 do Cloudflare em uso real (cada
                    // request pesa 60% menos e a rajada por segundo cai pela
                    // metade).
                    // ----------------------------------------------------
                    let downloadSpeed = try await runPhaseTimeBased(
                        phase: .download,
                        minDuration: Self.phaseMinDuration,
                        maxDuration: Self.phaseMaxDuration,
                        streams: 4,
                        bytes: 10_000_000, // 10 MB
                        state: &state,
                        continuation: continuation
                    )

                    state.downloadSpeed = downloadSpeed
                    state.phase = .upload
                    state.progress = 0.5
                    continuation.yield(state)

                    // Pausa dramática para o respiro visual e percepção de mudança de fase
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    // ----------------------------------------------------
                    // Measure Upload
                    // 6s–18s adaptativo (issue #62), 4 streams, 5MB chunk.
                    // Mesmo motivo do download: agressividade reduzida pra
                    // fugir de 429.
                    // ----------------------------------------------------
                    let uploadSpeed = try await runPhaseTimeBased(
                        phase: .upload,
                        minDuration: Self.phaseMinDuration,
                        maxDuration: Self.phaseMaxDuration,
                        streams: 4,
                        bytes: 5_000_000, // 5 MB
                        state: &state,
                        continuation: continuation
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
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        streams: Int,
        bytes: Int,
        state: inout MeasurementState,
        continuation: AsyncThrowingStream<MeasurementState, Error>.Continuation
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
                        while Date().timeIntervalSince(phaseStart) < maxDuration && !Task.isCancelled {
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

        while Date().timeIntervalSince(phaseStart) < maxDuration {
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

            // Progress interpolation — baseado em maxDuration (teto), não na
            // duração real da fase. Como a fase pode encerrar antes por
            // convergência (ver `shouldStopPhase` abaixo), isso evita que o
            // progresso "estoure" 1.0 sempre que termina cedo e evita um
            // salto visual brusco quando a próxima fase assume seu
            // baseProgress — motion continua só transmitindo estado, sem
            // chamar atenção pra si (AGENTS.md §6).
            let elapsed = Date().timeIntervalSince(phaseStart)
            let phaseProgress = min(elapsed / maxDuration, 1.0)
            let baseProgress = phase == .download ? 0.1 : 0.5
            let totalPhaseRange = phase == .download ? 0.4 : 0.5
            state.progress = baseProgress + (phaseProgress * totalPhaseRange)

            continuation.yield(state)

            // Encerra a fase cedo quando a vazão amostrada já convergiu e o
            // piso mínimo já foi respeitado (issue #62) — conexões estáveis
            // terminam antes de `maxDuration`, economizando tempo, franquia
            // e bateria. Conexões instáveis seguem até `maxDuration`, igual
            // ao comportamento anterior.
            if Self.shouldStopPhase(
                samples: mbpsSamples,
                elapsed: elapsed,
                minDuration: minDuration,
                maxDuration: maxDuration
            ) {
                break
            }
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

    /// Critério de convergência de vazão (issue #62): decide se uma janela
    /// recente de amostras de mbps já está "estável o suficiente" para
    /// considerar a medição da fase concluída.
    ///
    /// `nonisolated static` de propósito — igual a `resolveProviderName`:
    /// não toca `Date()` ao vivo, não toca URLSession, não toca o estado do
    /// ator. Recebe só o array de amostras já coletadas, o que a torna
    /// inteiramente exercitável em teste com arrays sintéticos.
    ///
    /// - Parameters:
    ///   - samples: amostras de mbps instantâneo coletadas na fase até agora,
    ///     em ordem cronológica (uma por `sampleInterval`, hoje 300ms).
    ///   - window: quantas das amostras mais recentes considerar. 5 amostras
    ///     a 300ms cobre 1.5s de janela — sensível o bastante para detectar
    ///     estabilização sem reagir a um único pico/vale isolado.
    ///   - tolerance: variação relativa máxima, como fração da média da
    ///     janela, para considerar a vazão estável. 0.08 (8%) tolera o ruído
    ///     normal de uma conexão saudável sem aceitar como "estável" uma
    ///     vazão que ainda está subindo ou caindo de forma clara.
    /// - Returns: `true` quando há amostras válidas suficientes (>= `window`,
    ///   descartando zeros — que indicam ausência de dado na janela, não
    ///   vazão real) e a variação relativa entre elas está dentro de
    ///   `tolerance`. `false` quando não há amostras suficientes ainda ou a
    ///   vazão segue variando além da tolerância.
    nonisolated static func hasConverged(
        samples: [Double],
        window: Int = 5,
        tolerance: Double = 0.08
    ) -> Bool {
        let valid = samples.filter { $0 > 0 }
        guard valid.count >= window else { return false }

        let recent = Array(valid.suffix(window))
        let mean = recent.reduce(0, +) / Double(recent.count)
        guard mean > 0 else { return false }

        let maxRelativeDeviation = recent.map { abs($0 - mean) / mean }.max() ?? .infinity
        return maxRelativeDeviation <= tolerance
    }

    /// Decisão completa de "encerrar a fase agora?" (issue #62): compõe o
    /// critério de convergência (`hasConverged`) com o piso e o teto de
    /// duração da fase. `nonisolated static` pela mesma razão de
    /// `hasConverged` — sem `Date()` ao vivo, `elapsed` é passado pelo
    /// chamador, então é inteiramente testável com valores sintéticos.
    ///
    /// - Returns: `true` se `elapsed` já alcançou `maxDuration` (teto —
    ///   sempre encerra, convergindo ou não, preservando o pior caso de
    ///   tempo/consumo de dados do comportamento anterior); ou se `elapsed`
    ///   já alcançou `minDuration` **e** `hasConverged` é `true` (encerra
    ///   cedo). Caso contrário `false` — a fase continua amostrando.
    nonisolated static func shouldStopPhase(
        samples: [Double],
        elapsed: TimeInterval,
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        window: Int = 5,
        tolerance: Double = 0.08
    ) -> Bool {
        if elapsed >= maxDuration { return true }
        guard elapsed >= minDuration else { return false }
        return hasConverged(samples: samples, window: window, tolerance: tolerance)
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

import Foundation
import Network

/// Contador thread-safe de bytes trafegados por fase. Isolamento via actor
/// (mais confiável que NSLock + delegate custom em iOS 26+).
actor ByteCounter {
    private var value: Int64 = 0
    func add(_ n: Int64) { value += n }
    func total() -> Int64 { value }
}

/// Coletor thread-safe de amostras double por fase (issue #52). Usado para
/// juntar as sondagens de latência sob carga coletadas em paralelo à
/// transferência real, sem acoplar a task de amostragem ao estado do ator.
actor DoubleSampleCollector {
    private var values: [Double] = []
    func add(_ value: Double) { values.append(value) }
    func all() -> [Double] { values }
}

/// Contador thread-safe de falhas fatais de transporte consecutivas por fase
/// (issue #66) — mesmo padrão ator de `ByteCounter`. Compartilhado entre os
/// `streams` concorrentes de uma fase: cada falha classificada como fatal
/// por `SpeedTestCore.isFatalTransportError` incrementa; qualquer sucesso de
/// qualquer stream zera, porque um sucesso concorrente já prova que a
/// conexão de transporte não está de fato perdida.
actor FatalErrorTracker {
    private var consecutiveCount: Int = 0
    func recordFailure() -> Int {
        consecutiveCount += 1
        return consecutiveCount
    }
    func recordSuccess() {
        consecutiveCount = 0
    }
    func currentCount() -> Int { consecutiveCount }
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

/// Abstrai a checagem de conectividade de rede (issue #66) para permitir
/// injeção em teste, no mesmo padrão de `ProviderOrgLookup`/`IPInfoOrgLookup`
/// — sem essa abstração, testar o caminho "offline" exigiria desligar a
/// rede de verdade durante o teste.
public protocol PathStatusProvider: Sendable {
    /// `true` quando há conectividade de rede no momento da checagem.
    func hasConnectivity() async -> Bool
}

/// Guarda thread-safe de resumo único (issue #66): `NWPathMonitor` pode
/// disparar `pathUpdateHandler` mais de uma vez antes de `cancel()` surtir
/// efeito — sem isso, a segunda chamada resumiria a continuation duas vezes
/// e provocaria crash em runtime.
private final class ResumeOnceGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    /// `true` na primeira chamada; `false` em qualquer chamada seguinte.
    func tryResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return false }
        didResume = true
        return true
    }
}

/// Implementação real: consulta o `NWPathMonitor` do sistema.
public struct NWPathStatusProvider: PathStatusProvider {
    public init() {}

    public func hasConnectivity() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "PathStatusProvider")
        let resumeGuard = ResumeOnceGuard()
        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                guard resumeGuard.tryResume() else { return }
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: queue)
        }
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
    private let pathStatusProvider: PathStatusProvider

    /// - Parameters:
    ///   - providerLookup: fonte do dado bruto de provedor. Injetável para testes;
    ///     produção usa `IPInfoOrgLookup()` por padrão.
    ///   - providerEnrichmentTimeout: teto de tempo, em segundos, dedicado exclusivamente
    ///     ao enriquecimento de provedor. Roda em paralelo à medição, nunca soma ao
    ///     tempo de nenhuma fase (ping/download/upload).
    ///   - pathStatusProvider: fonte da checagem de conectividade prévia ao ping
    ///     (issue #66). Injetável para testes; produção usa `NWPathStatusProvider()`
    ///     por padrão.
    public init(
        providerLookup: ProviderOrgLookup = IPInfoOrgLookup(),
        providerEnrichmentTimeout: TimeInterval = 2.0,
        pathStatusProvider: PathStatusProvider = NWPathStatusProvider()
    ) {
        self.providerLookup = providerLookup
        self.providerEnrichmentTimeout = providerEnrichmentTimeout
        self.pathStatusProvider = pathStatusProvider
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

                    // ----------------------------------------------------
                    // Checagem de conectividade prévia ao ping (issue #66).
                    // Sem rede desde o início não é uma falha transitória
                    // de fase — é um estado explícito: pára aqui, antes de
                    // gastar qualquer request, e devolve o fato tipado
                    // (`.offline`) em vez de deixar ping/download/upload
                    // falharem silenciosamente um a um.
                    // ----------------------------------------------------
                    guard await pathStatusProvider.hasConnectivity() else {
                        let errored = Self.errorState(preserving: state, reason: .offline)
                        continuation.yield(errored)
                        continuation.finish()
                        return
                    }

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
                    let downloadOutcome = try await runPhaseTimeBased(
                        phase: .download,
                        minDuration: Self.phaseMinDuration,
                        maxDuration: Self.phaseMaxDuration,
                        streams: 4,
                        bytes: 10_000_000, // 10 MB
                        state: &state,
                        continuation: continuation
                    )

                    switch downloadOutcome {
                    case .measured(let speed):
                        state.downloadSpeed = speed
                    case .fatalFailure(let reason):
                        // Preserva ping/jitter/packetLoss já capturados nesta
                        // fase anterior — só marca o fato tipado, sem
                        // descartar dado real já medido (AGENTS.md §8).
                        let errored = Self.errorState(preserving: state, reason: reason)
                        continuation.yield(errored)
                        continuation.finish()
                        return
                    }

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
                    let uploadOutcome = try await runPhaseTimeBased(
                        phase: .upload,
                        minDuration: Self.phaseMinDuration,
                        maxDuration: Self.phaseMaxDuration,
                        streams: 4,
                        bytes: 5_000_000, // 5 MB
                        state: &state,
                        continuation: continuation
                    )

                    switch uploadOutcome {
                    case .measured(let speed):
                        state.uploadSpeed = speed
                    case .fatalFailure(let reason):
                        // Preserva o download já medido (e ping/jitter) —
                        // mesma regra do aborto na fase de download acima.
                        let errored = Self.errorState(preserving: state, reason: reason)
                        continuation.yield(errored)
                        continuation.finish()
                        return
                    }

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

    /// Resultado de uma fase de transferência (issue #66): ou ela produziu
    /// uma vazão medida normalmente, ou abortou por falha fatal de
    /// transporte (`shouldAbortPhase`) antes de conseguir medir nada.
    private enum PhaseOutcome {
        case measured(Double)
        case fatalFailure(EngineFailureReason)
    }

    private func runPhaseTimeBased(
        phase: Phase,
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        streams: Int,
        bytes: Int,
        state: inout MeasurementState,
        continuation: AsyncThrowingStream<MeasurementState, Error>.Continuation
    ) async throws -> PhaseOutcome {

        let phaseStart = Date()
        let sampleInterval = 0.3 // 300ms
        let counter = ByteCounter()
        let fatalErrorTracker = FatalErrorTracker()

        // Random payload for upload to avoid compression caching at network level.
        let payload = phase == .upload ? generateRandomPayload(size: bytes) : nil

        // ------------------------------------------------------------
        // Latência sob carga (issue #52), só na fase de download.
        //
        // Sonda HEAD leve (0 bytes) contra o mesmo endpoint Cloudflare,
        // concorrente à carga real dos `streams` de download — é essa
        // concorrência que a diferencia da latência ociosa de
        // `performPingTest` (que roda isolada, antes de qualquer carga).
        //
        // Fica presa à mesma janela da fase (`phaseStart`/`maxDuration`) e é
        // cancelada assim que o loop principal termina, cedo por convergência
        // ou no teto — nunca estende a duração calibrada por #62. O
        // intervalo de 1s entre sondagens mantém o custo de dados desprezível
        // (HEAD de 0 bytes) e não compete por banda com os streams de carga.
        let latencyCollector: DoubleSampleCollector? = phase == .download ? DoubleSampleCollector() : nil
        let latencySamplingTask: Task<Void, Never>? = latencyCollector.map { collector in
            Task.detached(priority: .utility) {
                while Date().timeIntervalSince(phaseStart) < maxDuration && !Task.isCancelled {
                    if let sample = await SpeedTestCore.performLoadedLatencyProbe() {
                        await collector.add(sample)
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s entre sondagens
                }
            }
        }

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
                                    // Sucesso concorrente prova que o transporte não está
                                    // de fato perdido — zera a sequência de falhas fatais
                                    // acumulada por qualquer outro stream (issue #66).
                                    await fatalErrorTracker.recordSuccess()
                                } else if statusCode == 429 || statusCode >= 500 {
                                    // Rate-limit ou erro upstream — recua antes de tentar de novo.
                                    try? await Task.sleep(nanoseconds: backoffMs * 1_000_000)
                                    backoffMs = min(backoffMs * 2, 2_000)
                                }
                            } catch let urlError as URLError where SpeedTestCore.isFatalTransportError(urlError) {
                                // Falha fatal de transporte (issue #66) — distinta de erro
                                // transitório isolado. Conta pra decisão de aborto
                                // (`shouldAbortPhase`, checada no loop principal); uma
                                // pausa curta evita busy-loop batendo num host inacessível.
                                _ = await fatalErrorTracker.recordFailure()
                                try? await Task.sleep(nanoseconds: 200_000_000)
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

            // Aborto por falha fatal persistente (issue #66): só quando a
            // fase ainda não entregou nenhum byte real (`total == 0`) — um
            // erro isolado numa fase que já está fluindo throughput nunca
            // aborta, mesmo que a sequência de falhas fatais acumule (ver
            // `shouldAbortPhase`).
            let fatalCount = await fatalErrorTracker.currentCount()
            if Self.shouldAbortPhase(consecutiveFatalErrors: fatalCount, bytesTransferred: total) {
                workersTask.cancel()
                _ = await workersTask.result
                session.invalidateAndCancel()
                latencySamplingTask?.cancel()
                _ = await latencySamplingTask?.value
                return .fatalFailure(.connectionLost(phase: phase))
            }

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

        // Encerra a sondagem de latência sob carga na mesma virada da carga
        // real — nunca sobrevive além da janela da fase. Falha ou ausência
        // total de amostras aqui nunca lança nem afeta `downloadSpeed`
        // (aceite #4): `aggregateLoadedLatency` simplesmente devolve `nil`.
        latencySamplingTask?.cancel()
        _ = await latencySamplingTask?.value
        if phase == .download, let latencyCollector {
            let latencySamples = await latencyCollector.all()
            state.loadedLatencyMs = Self.aggregateLoadedLatency(samples: latencySamples)
        }

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

        // Variação objetiva de vazão (issue #52): desvio relativo dentro da
        // mesma janela estável usada para `stableAvg`, com o mesmo piso de
        // robustez de `hasConverged` (>= window amostras válidas). Fica só
        // em `MeasurementState` — motor-interno nesta primeira entrega, não
        // entra no contrato canônico `NetworkMeasurement` (ver notas do
        // plano da issue #52).
        let variation = Self.throughputVariation(stableSamples: stable)
        if phase == .download {
            state.downloadThroughputVariation = variation
        } else {
            state.uploadThroughputVariation = variation
        }

        return .measured(stableAvg > 0 ? stableAvg : averageMbps)
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

    /// Classifica um `URLError` como falha fatal de transporte ou falha
    /// transitória recuperável (issue #66).
    ///
    /// `nonisolated static` de propósito — puro, exercitável diretamente com
    /// instâncias sintéticas de `URLError`, sem precisar disparar uma
    /// request de verdade.
    ///
    /// - Returns: `true` para códigos que indicam perda de conectividade de
    ///   transporte (`notConnectedToInternet`, `networkConnectionLost`,
    ///   `cannotConnectToHost`, `cannotFindHost`, `dataNotAllowed`) — nenhum
    ///   deles se recupera tentando de novo no mesmo caminho de rede.
    ///   `false` para os demais (ex.: `timedOut`), que o motor já trata como
    ///   recuperáveis (junto com HTTP 429/5xx, tratados à parte por
    ///   status code em `runPhaseTimeBased`).
    nonisolated static func isFatalTransportError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dataNotAllowed:
            return true
        default:
            return false
        }
    }

    /// Decide se uma fase deve abortar por falha fatal de transporte
    /// persistente (issue #66).
    ///
    /// `nonisolated static` de propósito — mesmo padrão de `shouldStopPhase`:
    /// puro, sem tocar o estado do ator, exercitável com valores sintéticos.
    ///
    /// - Parameters:
    ///   - consecutiveFatalErrors: contagem corrente de falhas fatais
    ///     consecutivas (`FatalErrorTracker.currentCount()`), zerada por
    ///     qualquer sucesso concorrente de qualquer stream da fase.
    ///   - bytesTransferred: bytes acumulados na fase até agora (mesmo
    ///     `total` já lido de `ByteCounter` no loop de amostragem).
    ///   - threshold: piso de falhas fatais consecutivas exigido antes de
    ///     sequer considerar abortar — um valor isolado nunca aborta.
    /// - Returns: `true` somente quando **ambas** as condições valem: já
    ///   houve `threshold` falhas fatais seguidas **e** a fase ainda não
    ///   entregou nenhum byte real (`bytesTransferred == 0`). Uma fase que
    ///   já está entregando throughput real nunca aborta por erro isolado,
    ///   mesmo que a sequência de falhas fatais atinja o piso — dado real já
    ///   medido vale mais que uma sondagem de erro (AGENTS.md §8).
    nonisolated static func shouldAbortPhase(
        consecutiveFatalErrors: Int,
        bytesTransferred: Int64,
        threshold: Int = 6
    ) -> Bool {
        consecutiveFatalErrors >= threshold && bytesTransferred == 0
    }

    /// Constrói o `MeasurementState` final de uma falha fatal (issue #66):
    /// preserva integralmente o estado já capturado nas fases anteriores
    /// (ping, jitter, packetLoss, downloadSpeed, provider, networkType…) e
    /// só marca `phase` como `.error` e anota o motivo tipado — nunca perde
    /// dado real já medido por causa de uma falha posterior (AGENTS.md §8).
    ///
    /// `nonisolated static` de propósito — puro, sem tocar o estado do ator,
    /// exercitável diretamente com um `MeasurementState` sintético.
    nonisolated static func errorState(
        preserving state: MeasurementState,
        reason: EngineFailureReason
    ) -> MeasurementState {
        var errored = state
        errored.phase = .error
        errored.failureReason = reason
        return errored
    }

    /// Agregação da latência sob carga (issue #52): reduz as sondagens
    /// coletadas por `performLoadedLatencyProbe` durante a fase de download
    /// a um único valor representativo.
    ///
    /// `nonisolated static` de propósito — mesmo padrão de `hasConverged`:
    /// não toca `Date()` ao vivo nem estado do ator, então é inteiramente
    /// exercitável com arrays sintéticos em teste.
    ///
    /// Usa a mediana, não a média: sob carga real é comum que uma sondagem
    /// isolada colida com uma rajada de um dos streams de download e saia
    /// bem mais alta que as demais — a mediana absorve esse outlier sem
    /// exigir lógica extra de filtragem.
    ///
    /// - Parameters:
    ///   - samples: latências em ms coletadas durante a fase, em qualquer
    ///     ordem (sondagens já vêm filtradas de falha por
    ///     `performLoadedLatencyProbe`, que só produz valores positivos).
    ///   - minSamples: piso mínimo de amostras válidas para produzir um
    ///     valor — evita reportar "latência sob carga" a partir de uma
    ///     única sondagem que pode não ser representativa.
    /// - Returns: a mediana das amostras válidas (finitas e positivas), ou
    ///   `nil` quando não há amostras suficientes — nunca inventa um valor.
    nonisolated static func aggregateLoadedLatency(
        samples: [Double],
        minSamples: Int = 3
    ) -> Double? {
        let valid = samples.filter { $0.isFinite && $0 > 0 }
        guard valid.count >= minSamples else { return nil }

        let sorted = valid.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return sorted[mid]
    }

    /// Medida objetiva de variação de vazão (issue #52): coeficiente de
    /// variação (desvio padrão relativo à média) das amostras de mbps já
    /// coletadas na janela estável da fase (`stable`, a mesma usada para
    /// `stableAvg` — descarta os primeiros 35% para cortar o warmup
    /// TCP/TLS). Não introduz nenhuma amostragem nova: reaproveita
    /// integralmente `mbpsSamples` já coletado no ritmo de `sampleInterval`.
    ///
    /// `nonisolated static` pelo mesmo motivo de `hasConverged`: puro,
    /// sem tocar estado do ator, testável com arrays sintéticos.
    ///
    /// - Parameters:
    ///   - stableSamples: amostras de mbps da janela estável da fase.
    ///   - window: piso mínimo de amostras válidas para produzir um valor —
    ///     mesmo piso de robustez de `hasConverged` (5 amostras).
    /// - Returns: desvio padrão / média das amostras válidas (>0), como
    ///   fração — quanto maior, mais instável a vazão dentro da janela
    ///   estável. `nil` quando não há amostras suficientes ou a média é
    ///   zero — nunca inventa um valor com dado insuficiente.
    nonisolated static func throughputVariation(
        stableSamples: [Double],
        window: Int = 5
    ) -> Double? {
        let valid = stableSamples.filter { $0 > 0 }
        guard valid.count >= window else { return nil }

        let mean = valid.reduce(0, +) / Double(valid.count)
        guard mean > 0 else { return nil }

        let variance = valid.map { pow($0 - mean, 2) }.reduce(0, +) / Double(valid.count)
        let stdDev = variance.squareRoot()
        return stdDev / mean
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

    /// Uma única sondagem de latência sob carga (issue #52): HEAD leve
    /// (0 bytes) contra o mesmo endpoint Cloudflare usado pela fase de
    /// download, disparada em paralelo à carga real dos streams de
    /// transferência — é essa concorrência com carga que a diferencia da
    /// latência ociosa de `performPingTest`, que roda isolada antes de
    /// qualquer transferência.
    ///
    /// `nonisolated static` de propósito, igual a `resolveProviderName`:
    /// não toca estado do ator, então pode ser chamada de dentro de uma
    /// `Task.detached` sem nenhum hop de volta para `SpeedTestCore`.
    ///
    /// - Returns: a latência em milissegundos quando a sondagem responde
    ///   200, ou `nil` em qualquer falha/timeout/status diferente — nunca
    ///   lança, para nunca derrubar a task de amostragem que a chama em
    ///   loop.
    nonisolated static func performLoadedLatencyProbe() async -> Double? {
        let start = Date()
        do {
            guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=0") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 1.0
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return Date().timeIntervalSince(start) * 1000.0
        } catch {
            return nil
        }
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

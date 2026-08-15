import Foundation
import Network

/// Delegate to track download and upload progress continuously
final class NetworkProgressDelegate: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var bytesAccumulated: Int64 = 0
    private var continuations: [Int: CheckedContinuation<Void, Error>] = [:]
    
    func setContinuation(for taskIdentifier: Int, continuation: CheckedContinuation<Void, Error>) {
        lock.lock()
        continuations[taskIdentifier] = continuation
        lock.unlock()
    }
    
    // For download
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        self.bytesAccumulated += Int64(data.count)
        lock.unlock()
    }
    
    // For upload
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        lock.lock()
        self.bytesAccumulated += bytesSent
        lock.unlock()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let cont = continuations.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
        
        if let e = error {
            cont?.resume(throwing: e)
        } else {
            cont?.resume(returning: ())
        }
    }
    
    func getAndResetBytes() -> Int64 {
        lock.lock()
        let b = bytesAccumulated
        self.bytesAccumulated = 0
        lock.unlock()
        return b
    }
}

public actor SpeedTestCore {
    
    public init() {}
    
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
                        state.networkType = "5G/4G Cellular"
                    } else {
                        state.networkType = "Desconhecido"
                    }
                    monitor.cancel()
                    
                    do {
                        if let url = URL(string: "https://ipinfo.io/json") {
                            var request = URLRequest(url: url)
                            request.timeoutInterval = 2.0
                            let (data, _) = try await URLSession.shared.data(for: request)
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let org = json["org"] as? String {
                                state.provider = ProviderNormalizer.shared.displayName(for: org)
                            }
                        }
                    } catch {
                        state.provider = "Desconhecido"
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
                    // Measure Download (SignallQ COMPLETE preset)
                    // 18s duration, 8 streams, 25MB chunk
                    // ----------------------------------------------------
                    let downloadSpeed = try await runPhaseTimeBased(
                        phase: .download,
                        duration: 18.0,
                        streams: 8,
                        bytes: 25_000_000, // 25 MB
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
                    // Measure Upload (SignallQ COMPLETE preset)
                    // 18s duration, 8 streams, 10MB chunk
                    // ----------------------------------------------------
                    let uploadSpeed = try await runPhaseTimeBased(
                        phase: .upload,
                        duration: 18.0,
                        streams: 8,
                        bytes: 10_000_000, // 10 MB
                        state: &state,
                        continuation: continuation,
                        testStart: testStart
                    )
                    
                    state.uploadSpeed = uploadSpeed
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
        
        let delegate = NetworkProgressDelegate()
        let phaseStart = Date()
        let sampleInterval = 0.3 // 300ms
        
        // Random payload for upload to avoid compression caching at network level
        let payload = phase == .upload ? generateRandomPayload(size: bytes) : nil
        
        // Custom ephemeral session to bypass caching aggressively and not limit max connections
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.httpMaximumConnectionsPerHost = streams + 2
        config.timeoutIntervalForRequest = 5.0
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        let workersTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<streams {
                    group.addTask {
                        while Date().timeIntervalSince(phaseStart) < duration && !Task.isCancelled {
                            do {
                                if phase == .download {
                                    guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") else { return }
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "GET"
                                    
                                    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                                        let task = session.dataTask(with: request)
                                        delegate.setContinuation(for: task.taskIdentifier, continuation: cont)
                                        task.resume()
                                    }
                                } else {
                                    guard let url = URL(string: "https://speed.cloudflare.com/__up") else { return }
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "POST"
                                    
                                    if let p = payload {
                                        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                                            let task = session.uploadTask(with: request, from: p)
                                            delegate.setContinuation(for: task.taskIdentifier, continuation: cont)
                                            task.resume()
                                        }
                                    }
                                }
                            } catch {
                                // Ignore intermittent network errors, just retry until duration ends
                            }
                        }
                    }
                }
            }
        }
        
        var mbpsSamples: [Double] = []
        var smoothedMbps: Double = 0.0
        
        while Date().timeIntervalSince(phaseStart) < duration {
            try? await Task.sleep(nanoseconds: UInt64(sampleInterval * 1_000_000_000))
            if Task.isCancelled { break }
            
            let tickBytes = delegate.getAndResetBytes()
            let instantMbps = (Double(tickBytes) * 8.0) / sampleInterval / 1_000_000.0
            
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
        
        // Calculate stable speed (SignallQ stable window: last 65% of valid samples)
        let valid = mbpsSamples.filter { $0 > 0 }
        let stableStart = Int(ceil(Double(valid.count) * 0.35))
        let stable = valid.count > stableStart ? Array(valid[stableStart...]) : valid
        
        let finalMbps = stable.isEmpty ? 0.0 : stable.reduce(0, +) / Double(stable.count)
        return finalMbps
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
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        
        let lossPercent = (Double(failures) / Double(totalPings)) * 100.0
        
        guard !latencies.isEmpty else {
            return (0.0, 0.0, lossPercent)
        }
        
        let avgLatency = latencies.reduce(0, +) / Double(latencies.count)
        
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
}

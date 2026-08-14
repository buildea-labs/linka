import Foundation
import Network

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
                                let parts = org.split(separator: " ", maxSplits: 1)
                                state.provider = parts.count > 1 ? String(parts[1]) : org
                            }
                        }
                    } catch {
                        state.provider = "Desconhecido"
                    }
                    
                    continuation.yield(state)
                    
                    // Measure Ping
                    let pingStart = Date()
                    _ = try await performDownload(bytes: 100) // small request for ping
                    let pingMs = Date().timeIntervalSince(pingStart) * 1000.0
                    
                    state.ping = pingMs
                    state.jitter = pingMs * 0.1 // Simulated jitter for now
                    state.phase = .download
                    state.progress = 0.1
                    continuation.yield(state)
                    
                    // Measure Download
                    // 25MB payload
                    let downloadBytes = 25_000_000
                    let downloadStart = Date()
                    _ = try await performDownload(bytes: downloadBytes)
                    let downloadDuration = Date().timeIntervalSince(downloadStart)
                    
                    // Mbps = (Bytes * 8 / Duration) / 1,000,000
                    let downloadSpeed = (Double(downloadBytes) * 8.0 / downloadDuration) / 1_000_000.0
                    
                    state.downloadSpeed = downloadSpeed
                    state.phase = .upload
                    state.progress = 0.5
                    continuation.yield(state)
                    
                    // Measure Upload
                    // 10MB payload
                    let uploadBytes = 10_000_000
                    let uploadStart = Date()
                    _ = try await performUpload(bytes: uploadBytes)
                    let uploadDuration = Date().timeIntervalSince(uploadStart)
                    
                    let uploadSpeed = (Double(uploadBytes) * 8.0 / uploadDuration) / 1_000_000.0
                    
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
    
    private func performDownload(bytes: Int) async throws -> Data {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    private func performUpload(bytes: Int) async throws -> Data {
        guard let url = URL(string: "https://speed.cloudflare.com/__up") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // Generate random data for upload payload
        let payload = Data(count: bytes)
        request.httpBody = payload
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

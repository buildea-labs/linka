import Foundation

public final class LinkaEngine {
    public static let shared = LinkaEngine()
    
    private init() {}
    
    public func startSpeedTest(progress: @escaping (Double) -> Void, completion: @escaping (Result<SpeedTestResult, Error>) -> Void) {
        // Placeholder for network core logic
        var currentProgress: Double = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            currentProgress += 0.05
            progress(currentProgress)
            if currentProgress >= 1.0 {
                timer.invalidate()
                completion(.success(SpeedTestResult(download: 500.0, upload: 100.0, ping: 12)))
            }
        }
    }
}

public struct SpeedTestResult {
    public let download: Double
    public let upload: Double
    public let ping: Int
}

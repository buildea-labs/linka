import Foundation
import Combine
import LinkaEngine

public enum SpeedTestUIPhase {
    case idle
    case connecting
    case downloading
    case uploading
    case done
}

@MainActor
public class SpeedTestViewModel: ObservableObject {
    @Published public var isTesting: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var downloadSpeed: Double = 0.0
    @Published public var uploadSpeed: Double = 0.0
    @Published public var ping: Int = 0
    @Published public var jitter: Double = 0.0
    @Published public var uiPhase: SpeedTestUIPhase = .idle
    
    // UI states
    @Published public var showOnboarding: Bool = false
    @Published public var showSettings: Bool = false
    @Published public var showPurchase: Bool = false
    
    private let engine = SpeedTestCore()
    private var testTask: Task<Void, Never>?
    
    public init() {}
    
    public func startTest() {
        guard !isTesting else { return }
        isTesting = true
        progress = 0.0
        downloadSpeed = 0.0
        uploadSpeed = 0.0
        ping = 0
        jitter = 0.0
        uiPhase = .connecting
        
        testTask?.cancel()
        testTask = Task {
            do {
                var lastUpdateTime = Date()
                
                for try await state in await engine.runTest() {
                    let now = Date()
                    // Throttle updates to ~30fps
                    if now.timeIntervalSince(lastUpdateTime) >= 0.033 || state.progress >= 1.0 || state.progress == 0.0 {
                        self.update(with: state)
                        lastUpdateTime = now
                    }
                }
                
                self.isTesting = false
            } catch {
                self.isTesting = false
            }
        }
    }
    
    public func stopTest() {
        testTask?.cancel()
        isTesting = false
        uiPhase = .idle
    }
    
    private func update(with state: MeasurementState) {
        self.progress = state.progress
        if let p = state.ping { self.ping = Int(p) }
        if let j = state.jitter { self.jitter = j }
        if let d = state.downloadSpeed { self.downloadSpeed = d }
        if let u = state.uploadSpeed { self.uploadSpeed = u }
        
        switch state.phase {
        case .idle: self.uiPhase = .idle
        case .ping: self.uiPhase = .connecting
        case .download: self.uiPhase = .downloading
        case .upload: self.uiPhase = .uploading
        case .result: self.uiPhase = .done
        }
    }
}

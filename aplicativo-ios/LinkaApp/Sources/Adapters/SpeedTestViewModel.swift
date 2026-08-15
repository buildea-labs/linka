import Foundation
import Combine
import LinkaEngine
import MeasurementHistory
import NetworkCore

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
    @Published public var provider: String = ""
    @Published public var networkType: String = ""
    @Published public var testDuration: String = ""
    @Published public var packetLossPercent: Double? = nil
    @Published public var uiPhase: SpeedTestUIPhase = .idle
    
    @Published public var lastTestSpeedString: String? = nil
    
    // UI states
    @Published public var showSettings: Bool = false
    @Published public var showPurchase: Bool = false
    
    private let engine = SpeedTestCore()
    private var testTask: Task<Void, Never>?
    
    public init() {
        loadLastTest()
    }
    
    public func loadLastTest() {
        Task { @MainActor in
            let repository = FileMeasurementHistoryRepository(
                fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json")
            )
            if let count = try? await repository.totalCount(), count > 0 {
                let query = MeasurementQuery(limit: 1, sortOrder: .newestFirst)
                let results = try? await repository.measurements(matching: query)
                if let last = results?.first, let dl = last.downloadMbps {
                    let formattedSpeed = String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "pt_BR")
                    if Calendar.current.isDateInToday(last.measuredAt) {
                        self.lastTestSpeedString = "\(formattedSpeed) Mbps · Hoje"
                    } else {
                        formatter.dateFormat = "dd/MM"
                        self.lastTestSpeedString = "\(formattedSpeed) Mbps · \(formatter.string(from: last.measuredAt))"
                    }
                }
            }
        }
    }
    
    public func startTest() {
        guard !isTesting else { return }
        isTesting = true
        progress = 0.0
        downloadSpeed = 0.0
        uploadSpeed = 0.0
        ping = 0
        jitter = 0.0
        provider = ""
        networkType = ""
        testDuration = ""
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
                
                if self.uiPhase == .done {
                    let m = NetworkMeasurement(
                        outcome: .complete,
                        downloadMbps: self.downloadSpeed,
                        uploadMbps: self.uploadSpeed,
                        latencyMs: Double(self.ping),
                        jitterMs: self.jitter,
                        packetLossPercent: self.packetLossPercent,
                        connectionKind: self.networkType == "Wi-Fi" ? .wifi : (self.networkType.isEmpty ? .other : .cellular),
                        networkIdentifier: self.provider
                    )
                    let repo = FileMeasurementHistoryRepository(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json"))
                    try? await repo.save(m)
                    self.loadLastTest()
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
        if let prov = state.provider { self.provider = prov }
        if let net = state.networkType { self.networkType = net }
        if let dur = state.duration { self.testDuration = String(format: "%.1fs", dur).replacingOccurrences(of: ".", with: ",") }
        if let loss = state.packetLossPercent { self.packetLossPercent = loss }
        
        switch state.phase {
        case .idle: self.uiPhase = .idle
        case .ping: self.uiPhase = .connecting
        case .download: self.uiPhase = .downloading
        case .upload: self.uiPhase = .uploading
        case .result: self.uiPhase = .done
        }
    }
}

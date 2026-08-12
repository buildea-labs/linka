import Foundation

public struct MeasurementState {
    public var ping: Double?
    public var jitter: Double?
    public var downloadSpeed: Double? // in Mbps
    public var uploadSpeed: Double? // in Mbps
    public var progress: Double // 0.0 to 1.0
    public var phase: Phase
    
    public init(ping: Double? = nil, jitter: Double? = nil, downloadSpeed: Double? = nil, uploadSpeed: Double? = nil, progress: Double = 0.0, phase: Phase = .idle) {
        self.ping = ping
        self.jitter = jitter
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.progress = progress
        self.phase = phase
    }
}

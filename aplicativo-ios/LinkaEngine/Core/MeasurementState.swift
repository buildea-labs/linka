import Foundation

public struct MeasurementState {
    public var ping: Double?
    public var jitter: Double?
    public var packetLossPercent: Double?
    public var downloadSpeed: Double? // in Mbps
    public var uploadSpeed: Double? // in Mbps
    public var progress: Double // 0.0 to 1.0
    public var phase: Phase
    public var provider: String?
    public var networkType: String?
    public var duration: Double?
    
    public init(ping: Double? = nil, jitter: Double? = nil, packetLossPercent: Double? = nil, downloadSpeed: Double? = nil, uploadSpeed: Double? = nil, progress: Double = 0.0, phase: Phase = .idle, provider: String? = nil, networkType: String? = nil, duration: Double? = nil) {
        self.ping = ping
        self.jitter = jitter
        self.packetLossPercent = packetLossPercent
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.progress = progress
        self.phase = phase
        self.provider = provider
        self.networkType = networkType
        self.duration = duration
    }
}

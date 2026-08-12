import Foundation

public struct MeasurementSnapshot: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let measuredAt: Date
    public let downloadMbps: Double?
    public let uploadMbps: Double?
    public let latencyMs: Double?
    public let networkIdentifier: String?
    public let serverIdentifier: String?

    public init(
        id: UUID = UUID(),
        measuredAt: Date = Date(),
        downloadMbps: Double? = nil,
        uploadMbps: Double? = nil,
        latencyMs: Double? = nil,
        networkIdentifier: String? = nil,
        serverIdentifier: String? = nil
    ) {
        self.id = id
        self.measuredAt = measuredAt
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.latencyMs = latencyMs
        self.networkIdentifier = networkIdentifier
        self.serverIdentifier = serverIdentifier
    }
}

public enum LinkaTier: String, Codable, Sendable {
    case free
    case plus
}

public enum LinkaCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case speedTest
    case history
    case insights
    case assist
    case appleIntegrations
}

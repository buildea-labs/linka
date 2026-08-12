import Foundation

/// Compatibilidade temporária com a fundação inicial da branch.
/// Código novo deve depender do contrato canônico `NetworkMeasurement`.
@available(*, deprecated, renamed: "NetworkMeasurement")
public typealias MeasurementSnapshot = NetworkMeasurement

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

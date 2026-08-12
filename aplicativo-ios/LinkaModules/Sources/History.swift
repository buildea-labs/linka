import Foundation

public protocol HistoryProviding: Sendable {
    func save(_ measurement: NetworkMeasurement) async throws
    func recent(limit: Int) async throws -> [NetworkMeasurement]
    func all() async throws -> [NetworkMeasurement]
    func clear() async throws
}

public actor InMemoryHistoryStore: HistoryProviding {
    private var measurements: [NetworkMeasurement]

    public init(measurements: [NetworkMeasurement] = []) {
        self.measurements = measurements.sorted { $0.measuredAt > $1.measuredAt }
    }

    public func save(_ measurement: NetworkMeasurement) async throws {
        measurements.removeAll { $0.id == measurement.id }
        measurements.append(measurement)
        measurements.sort { $0.measuredAt > $1.measuredAt }
    }

    public func recent(limit: Int) async throws -> [NetworkMeasurement] {
        guard limit > 0 else { return [] }
        return Array(measurements.prefix(limit))
    }

    public func all() async throws -> [NetworkMeasurement] {
        measurements
    }

    public func clear() async throws {
        measurements.removeAll()
    }
}

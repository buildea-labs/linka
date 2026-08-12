import Foundation

public protocol HistoryProviding: Sendable {
    func save(_ measurement: MeasurementSnapshot) async throws
    func recent(limit: Int) async throws -> [MeasurementSnapshot]
    func all() async throws -> [MeasurementSnapshot]
    func clear() async throws
}

public actor InMemoryHistoryStore: HistoryProviding {
    private var measurements: [MeasurementSnapshot]

    public init(measurements: [MeasurementSnapshot] = []) {
        self.measurements = measurements.sorted { $0.measuredAt > $1.measuredAt }
    }

    public func save(_ measurement: MeasurementSnapshot) async throws {
        measurements.removeAll { $0.id == measurement.id }
        measurements.append(measurement)
        measurements.sort { $0.measuredAt > $1.measuredAt }
    }

    public func recent(limit: Int) async throws -> [MeasurementSnapshot] {
        guard limit > 0 else { return [] }
        return Array(measurements.prefix(limit))
    }

    public func all() async throws -> [MeasurementSnapshot] {
        measurements
    }

    public func clear() async throws {
        measurements.removeAll()
    }
}

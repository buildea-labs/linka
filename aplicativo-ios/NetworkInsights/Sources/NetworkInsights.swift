import Foundation
import NetworkCore

public enum NetworkMetric: String, Codable, CaseIterable, Sendable {
    case downloadMbps
    case uploadMbps
    case latencyMs
    case jitterMs
    case packetLossPercent
    case loadedLatencyMs

    public var preference: MetricPreference {
        switch self {
        case .downloadMbps, .uploadMbps:
            return .higherIsBetter
        case .latencyMs, .jitterMs, .packetLossPercent, .loadedLatencyMs:
            return .lowerIsBetter
        }
    }
}

public enum MetricPreference: String, Codable, Sendable {
    case higherIsBetter
    case lowerIsBetter
}

public enum InsightDirection: String, Codable, Sendable {
    case improved
    case worsened
    case stable
    case unavailable
}

public enum TrendDirection: String, Codable, Sendable {
    case rising
    case falling
    case stable
    case insufficientData
}

public struct MetricComparison: Codable, Equatable, Sendable {
    public let metric: NetworkMetric
    public let currentValue: Double?
    public let baselineValue: Double?
    public let absoluteDelta: Double?
    public let percentDelta: Double?
    public let direction: InsightDirection

    public init(
        metric: NetworkMetric,
        currentValue: Double?,
        baselineValue: Double?,
        absoluteDelta: Double?,
        percentDelta: Double?,
        direction: InsightDirection
    ) {
        self.metric = metric
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.absoluteDelta = absoluteDelta
        self.percentDelta = percentDelta
        self.direction = direction
    }
}

public struct NetworkMeasurementComparison: Codable, Equatable, Sendable {
    public let currentID: UUID
    public let baselineID: UUID
    public let metrics: [MetricComparison]

    public init(currentID: UUID, baselineID: UUID, metrics: [MetricComparison]) {
        self.currentID = currentID
        self.baselineID = baselineID
        self.metrics = metrics
    }

    public func comparison(for metric: NetworkMetric) -> MetricComparison? {
        metrics.first { $0.metric == metric }
    }
}

public struct MetricStatistics: Codable, Equatable, Sendable {
    public let metric: NetworkMetric
    public let sampleCount: Int
    public let minimum: Double?
    public let maximum: Double?
    public let average: Double?
    public let median: Double?
    public let standardDeviation: Double?
    public let relativeVariationPercent: Double?
}

public struct MetricTrend: Codable, Equatable, Sendable {
    public let metric: NetworkMetric
    public let sampleCount: Int
    public let direction: TrendDirection
    public let slopePerDay: Double?
    public let fittedChangePercent: Double?
}

public struct NetworkInsightsSummary: Codable, Equatable, Sendable {
    public let measurementCount: Int
    public let statistics: [MetricStatistics]
    public let trends: [MetricTrend]

    public func statistics(for metric: NetworkMetric) -> MetricStatistics? {
        statistics.first { $0.metric == metric }
    }

    public func trend(for metric: NetworkMetric) -> MetricTrend? {
        trends.first { $0.metric == metric }
    }
}

public struct NetworkPeriodComparison: Codable, Equatable, Sendable {
    public let currentSampleCount: Int
    public let baselineSampleCount: Int
    public let metrics: [MetricComparison]

    public func comparison(for metric: NetworkMetric) -> MetricComparison? {
        metrics.first { $0.metric == metric }
    }
}

public struct NetworkInsightsConfiguration: Equatable, Sendable {
    public let stableChangeThresholdPercent: Double
    public let minimumTrendSamples: Int

    public init(
        stableChangeThresholdPercent: Double = 3,
        minimumTrendSamples: Int = 3
    ) {
        self.stableChangeThresholdPercent = max(0, stableChangeThresholdPercent)
        self.minimumTrendSamples = max(2, minimumTrendSamples)
    }
}

public enum NetworkInsightsError: Error, Equatable, Sendable {
    case invalidMeasurement(UUID)

    /// Não é lançado por `BasicNetworkInsightsAnalyzer` — este pacote é
    /// cálculo puro e não conhece entitlement. Reservado para consumidores
    /// que envolvem `NetworkInsightsAnalyzing` com uma checagem de acesso
    /// (ver `LinkaModules.EntitlementGatedNetworkInsightsAnalyzer`).
    case notEntitled
}

public protocol NetworkInsightsAnalyzing: Sendable {
    func compare(
        current: NetworkMeasurement,
        against baseline: NetworkMeasurement
    ) throws -> NetworkMeasurementComparison

    func summarize(_ measurements: [NetworkMeasurement]) throws -> NetworkInsightsSummary

    func comparePeriods(
        current: [NetworkMeasurement],
        baseline: [NetworkMeasurement]
    ) throws -> NetworkPeriodComparison
}

public struct BasicNetworkInsightsAnalyzer: NetworkInsightsAnalyzing {
    public let configuration: NetworkInsightsConfiguration

    public init(configuration: NetworkInsightsConfiguration = .init()) {
        self.configuration = configuration
    }

    public func compare(
        current: NetworkMeasurement,
        against baseline: NetworkMeasurement
    ) throws -> NetworkMeasurementComparison {
        try validate([current, baseline])

        return NetworkMeasurementComparison(
            currentID: current.id,
            baselineID: baseline.id,
            metrics: NetworkMetric.allCases.map { metric in
                compareValues(
                    metric: metric,
                    current: value(of: metric, in: current),
                    baseline: value(of: metric, in: baseline)
                )
            }
        )
    }

    public func summarize(_ measurements: [NetworkMeasurement]) throws -> NetworkInsightsSummary {
        try validate(measurements)

        return NetworkInsightsSummary(
            measurementCount: measurements.count,
            statistics: NetworkMetric.allCases.map { metric in
                statistics(for: metric, measurements: measurements)
            },
            trends: NetworkMetric.allCases.map { metric in
                trend(for: metric, measurements: measurements)
            }
        )
    }

    public func comparePeriods(
        current: [NetworkMeasurement],
        baseline: [NetworkMeasurement]
    ) throws -> NetworkPeriodComparison {
        try validate(current)
        try validate(baseline)

        return NetworkPeriodComparison(
            currentSampleCount: current.count,
            baselineSampleCount: baseline.count,
            metrics: NetworkMetric.allCases.map { metric in
                compareValues(
                    metric: metric,
                    current: averageValue(of: metric, in: current),
                    baseline: averageValue(of: metric, in: baseline)
                )
            }
        )
    }

    private func validate(_ measurements: [NetworkMeasurement]) throws {
        for measurement in measurements where !NetworkMeasurementContract.isValid(measurement) {
            throw NetworkInsightsError.invalidMeasurement(measurement.id)
        }
    }

    private func compareValues(
        metric: NetworkMetric,
        current: Double?,
        baseline: Double?
    ) -> MetricComparison {
        guard let current, let baseline else {
            return MetricComparison(
                metric: metric,
                currentValue: current,
                baselineValue: baseline,
                absoluteDelta: nil,
                percentDelta: nil,
                direction: .unavailable
            )
        }

        let delta = current - baseline
        let percentDelta = baseline == 0 ? nil : (delta / abs(baseline)) * 100

        let isStable: Bool
        if let percentDelta {
            isStable = abs(percentDelta) <= configuration.stableChangeThresholdPercent
        } else {
            isStable = delta == 0
        }

        let direction: InsightDirection
        if isStable {
            direction = .stable
        } else {
            switch metric.preference {
            case .higherIsBetter:
                direction = delta > 0 ? .improved : .worsened
            case .lowerIsBetter:
                direction = delta < 0 ? .improved : .worsened
            }
        }

        return MetricComparison(
            metric: metric,
            currentValue: current,
            baselineValue: baseline,
            absoluteDelta: delta,
            percentDelta: percentDelta,
            direction: direction
        )
    }

    private func statistics(
        for metric: NetworkMetric,
        measurements: [NetworkMeasurement]
    ) -> MetricStatistics {
        let values = measurements.compactMap { value(of: metric, in: $0) }
        guard !values.isEmpty else {
            return MetricStatistics(
                metric: metric,
                sampleCount: 0,
                minimum: nil,
                maximum: nil,
                average: nil,
                median: nil,
                standardDeviation: nil,
                relativeVariationPercent: nil
            )
        }

        let sorted = values.sorted()
        let count = sorted.count
        let average = sorted.reduce(0, +) / Double(count)
        let median: Double
        if count.isMultiple(of: 2) {
            median = (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            median = sorted[count / 2]
        }

        let variance = sorted.reduce(0) { partial, value in
            let difference = value - average
            return partial + difference * difference
        } / Double(count)
        let standardDeviation = sqrt(variance)
        let relativeVariation = average == 0
            ? nil
            : (standardDeviation / abs(average)) * 100

        return MetricStatistics(
            metric: metric,
            sampleCount: count,
            minimum: sorted.first,
            maximum: sorted.last,
            average: average,
            median: median,
            standardDeviation: standardDeviation,
            relativeVariationPercent: relativeVariation
        )
    }

    private func trend(
        for metric: NetworkMetric,
        measurements: [NetworkMeasurement]
    ) -> MetricTrend {
        let points = measurements
            .compactMap { measurement -> (Date, Double)? in
                guard let metricValue = value(of: metric, in: measurement) else { return nil }
                return (measurement.measuredAt, metricValue)
            }
            .sorted { $0.0 < $1.0 }

        guard points.count >= configuration.minimumTrendSamples,
              let firstDate = points.first?.0,
              let lastDate = points.last?.0,
              lastDate > firstDate else {
            return MetricTrend(
                metric: metric,
                sampleCount: points.count,
                direction: .insufficientData,
                slopePerDay: nil,
                fittedChangePercent: nil
            )
        }

        let secondsPerDay = 86_400.0
        let xs = points.map { $0.0.timeIntervalSince(firstDate) / secondsPerDay }
        let ys = points.map(\.1)
        let meanX = xs.reduce(0, +) / Double(xs.count)
        let meanY = ys.reduce(0, +) / Double(ys.count)

        let numerator = zip(xs, ys).reduce(0.0) { partial, pair in
            partial + (pair.0 - meanX) * (pair.1 - meanY)
        }
        let denominator = xs.reduce(0.0) { partial, x in
            let difference = x - meanX
            return partial + difference * difference
        }

        guard denominator > 0 else {
            return MetricTrend(
                metric: metric,
                sampleCount: points.count,
                direction: .insufficientData,
                slopePerDay: nil,
                fittedChangePercent: nil
            )
        }

        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        let spanDays = lastDate.timeIntervalSince(firstDate) / secondsPerDay
        let fittedStart = intercept
        let fittedEnd = intercept + slope * spanDays
        let fittedChange = fittedStart == 0
            ? nil
            : ((fittedEnd - fittedStart) / abs(fittedStart)) * 100

        let direction: TrendDirection
        if let fittedChange {
            if abs(fittedChange) <= configuration.stableChangeThresholdPercent {
                direction = .stable
            } else {
                direction = fittedChange > 0 ? .rising : .falling
            }
        } else if slope == 0 {
            direction = .stable
        } else {
            direction = slope > 0 ? .rising : .falling
        }

        return MetricTrend(
            metric: metric,
            sampleCount: points.count,
            direction: direction,
            slopePerDay: slope,
            fittedChangePercent: fittedChange
        )
    }

    private func averageValue(
        of metric: NetworkMetric,
        in measurements: [NetworkMeasurement]
    ) -> Double? {
        let values = measurements.compactMap { value(of: metric, in: $0) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func value(of metric: NetworkMetric, in measurement: NetworkMeasurement) -> Double? {
        switch metric {
        case .downloadMbps:
            return measurement.downloadMbps
        case .uploadMbps:
            return measurement.uploadMbps
        case .latencyMs:
            return measurement.latencyMs
        case .jitterMs:
            return measurement.jitterMs
        case .packetLossPercent:
            return measurement.packetLossPercent
        case .loadedLatencyMs:
            return measurement.loadedLatencyMs
        }
    }
}

import Foundation
import NetworkCore
import NetworkInsights

/// Regras puras para transformar medições reais em oportunidades assistidas.
/// Não conhece UI, assinatura, rede ativa ou configurações do sistema.
public enum OptimizationOpportunityKind: String, Codable, CaseIterable, Sendable {
    case responsivenessUnderLoad
    case unstableConnection
    case belowUsualQuality
}

public enum OptimizationGuidedAction: String, Codable, CaseIterable, Sendable {
    case reduceConcurrentUse
    case moveCloserToRouter
    case restartRouter
}

public struct OptimizationOpportunity: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let ruleVersion: Int
    public let kind: OptimizationOpportunityKind
    public let action: OptimizationGuidedAction
    public let evidenceMeasurementIDs: [UUID]
    public let confidence: Double

    public init(
        id: String,
        ruleVersion: Int = 1,
        kind: OptimizationOpportunityKind,
        action: OptimizationGuidedAction,
        evidenceMeasurementIDs: [UUID],
        confidence: Double
    ) {
        self.id = id
        self.ruleVersion = ruleVersion
        self.kind = kind
        self.action = action
        self.evidenceMeasurementIDs = evidenceMeasurementIDs
        self.confidence = min(1, max(0, confidence))
    }
}

public struct OptimizationPlan: Codable, Equatable, Sendable {
    public let baselineMeasurementID: UUID
    public let opportunities: [OptimizationOpportunity]

    public init(baselineMeasurementID: UUID, opportunities: [OptimizationOpportunity]) {
        self.baselineMeasurementID = baselineMeasurementID
        self.opportunities = Array(opportunities.prefix(3))
    }
}

public struct OptimizationPlanBuilder: Sendable {
    public let minimumHistorySamples: Int
    public let highJitterMs: Double
    public let meaningfulLossPercent: Double

    public init(
        minimumHistorySamples: Int = 3,
        highJitterMs: Double = 15,
        meaningfulLossPercent: Double = 2
    ) {
        self.minimumHistorySamples = max(2, minimumHistorySamples)
        self.highJitterMs = max(0, highJitterMs)
        self.meaningfulLossPercent = max(0, meaningfulLossPercent)
    }

    public func build(baseline: NetworkMeasurement, history: [NetworkMeasurement]) -> OptimizationPlan {
        var opportunities: [OptimizationOpportunity] = []

        let responsiveness = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: baseline.latencyMs,
            loadedDownloadLatencyMs: baseline.loadedLatencyMs,
            loadedUploadLatencyMs: baseline.loadedLatencyUploadMs
        )
        if responsiveness.category == .medium || responsiveness.category == .low {
            opportunities.append(OptimizationOpportunity(
                id: "responsiveness-under-load-v1",
                kind: .responsivenessUnderLoad,
                action: .reduceConcurrentUse,
                evidenceMeasurementIDs: [baseline.id],
                confidence: responsiveness.category == .low ? 0.9 : 0.7
            ))
        }

        let hasInstability = (baseline.jitterMs ?? 0) >= highJitterMs ||
            (baseline.packetLossPercent ?? 0) >= meaningfulLossPercent
        if hasInstability {
            opportunities.append(OptimizationOpportunity(
                id: "unstable-connection-v1",
                kind: .unstableConnection,
                action: .moveCloserToRouter,
                evidenceMeasurementIDs: [baseline.id],
                confidence: baseline.packetLossPercent.map { $0 >= meaningfulLossPercent } == true ? 0.85 : 0.65
            ))
        }

        if let historicalIDs = degradedHistoryEvidence(for: baseline, in: history) {
            opportunities.append(OptimizationOpportunity(
                id: "below-usual-quality-v1",
                kind: .belowUsualQuality,
                action: .restartRouter,
                evidenceMeasurementIDs: [baseline.id] + historicalIDs,
                confidence: 0.75
            ))
        }

        let ordered = opportunities.sorted {
            if $0.confidence != $1.confidence { return $0.confidence > $1.confidence }
            return $0.id < $1.id
        }
        return OptimizationPlan(baselineMeasurementID: baseline.id, opportunities: ordered)
    }

    private func degradedHistoryEvidence(
        for baseline: NetworkMeasurement,
        in history: [NetworkMeasurement]
    ) -> [UUID]? {
        guard let kind = baseline.connectionKind,
              let identity = networkIdentity(for: baseline),
              let currentLatency = baseline.latencyMs else { return nil }

        let comparable = history.filter {
            $0.id != baseline.id && $0.connectionKind == kind && networkIdentity(for: $0) == identity
        }
        let latencies = comparable.compactMap(\.latencyMs).sorted()
        guard latencies.count >= minimumHistorySamples else { return nil }
        let median = latencies[latencies.count / 2]
        let comparison = MetricComparator.compare(
            metric: .latencyMs,
            current: currentLatency,
            baseline: median,
            stableChangeThresholdPercent: NetworkInsightsConfiguration().stableChangeThresholdPercent
        )
        guard comparison.direction == .worsened else { return nil }
        return comparable.map(\.id).sorted { $0.uuidString < $1.uuidString }
    }

    private func networkIdentity(for measurement: NetworkMeasurement) -> String? {
        if measurement.connectionKind == .wifi {
            return measurement.wifiContext?.ssid
        }
        return measurement.networkIdentifier
    }
}

public enum OptimizationRetestComparison: Equatable, Sendable {
    case notComparable
    case noSignificantGain
    case improved([MetricComparison])
}

public enum OptimizationRetestComparator {
    public static func compare(
        baseline: NetworkMeasurement,
        retest: NetworkMeasurement,
        analyzer: any NetworkInsightsAnalyzing = BasicNetworkInsightsAnalyzer()
    ) -> OptimizationRetestComparison {
        guard baseline.outcome == .complete,
              retest.outcome == .complete,
              baseline.connectionKind == retest.connectionKind,
              sameNetworkWhenWiFi(baseline, retest),
              let comparison = try? analyzer.compare(current: retest, against: baseline) else {
            return .notComparable
        }
        let improvements = comparison.metrics.filter { $0.direction == .improved }
        return improvements.isEmpty ? .noSignificantGain : .improved(improvements)
    }

    private static func sameNetworkWhenWiFi(_ baseline: NetworkMeasurement, _ retest: NetworkMeasurement) -> Bool {
        guard baseline.connectionKind == .wifi else { return true }
        guard let first = baseline.wifiContext?.ssid, let second = retest.wifiContext?.ssid else { return false }
        return first == second
    }
}

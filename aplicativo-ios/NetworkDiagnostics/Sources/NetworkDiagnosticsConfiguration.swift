import Foundation

public struct NetworkDiagnosticsConfiguration: Sendable {
    public let rulesEndpoint: URL
    public let aiEndpoint: URL
    public let requestTimeout: TimeInterval
    public let appVersion: String?
    public let platformIdentifier: String
    public let historyLookbackDays: Int
    public let recentMeasurementsLimit: Int

    public init(
        rulesEndpoint: URL,
        aiEndpoint: URL,
        requestTimeout: TimeInterval = 8,
        appVersion: String? = nil,
        platformIdentifier: String,
        historyLookbackDays: Int = 30,
        recentMeasurementsLimit: Int = 20
    ) {
        self.rulesEndpoint = rulesEndpoint
        self.aiEndpoint = aiEndpoint
        self.requestTimeout = max(1, requestTimeout)
        self.appVersion = appVersion
        self.platformIdentifier = platformIdentifier
        self.historyLookbackDays = max(1, historyLookbackDays)
        self.recentMeasurementsLimit = max(0, recentMeasurementsLimit)
    }

    public static let defaultRulesEndpoint = URL(string: "https://signallq-diagnostic.giammattey-luiz.workers.dev/diagnostic/evaluate")!
    public static let defaultAiEndpoint = URL(string: "https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev/api/ai/diagnostico-conexao")!
}

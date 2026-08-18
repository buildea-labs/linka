import Foundation

public struct NetworkDiagnosticsConfiguration: Sendable {
    public let rulesEndpoint: URL
    public let bearerToken: String?
    public let requestTimeout: TimeInterval
    public let appVersion: String?
    public let platformIdentifier: String
    public let historyLookbackDays: Int
    public let recentMeasurementsLimit: Int

    public init(
        rulesEndpoint: URL,
        bearerToken: String? = nil,
        requestTimeout: TimeInterval = 8,
        appVersion: String? = nil,
        platformIdentifier: String,
        historyLookbackDays: Int = 30,
        recentMeasurementsLimit: Int = 20
    ) {
        self.rulesEndpoint = rulesEndpoint
        self.bearerToken = bearerToken
        self.requestTimeout = max(1, requestTimeout)
        self.appVersion = appVersion
        self.platformIdentifier = platformIdentifier
        self.historyLookbackDays = max(1, historyLookbackDays)
        self.recentMeasurementsLimit = max(0, recentMeasurementsLimit)
    }

    public static let defaultRulesEndpoint = URL(string: "https://nds.signallq.com/v1/diagnostics/evaluate")!
}

import Foundation

public enum LinkaWidgetShared {
    public static let appGroupIdentifier = "group.com.linka.assist"
    public static let widgetKind = "LinkaSpeedTestWidget"
    private static let latestSummaryKey = "com.linka.speedtest.widget.latestSummary"

    public struct LatestMeasurementSummary: Codable, Equatable, Sendable {
        public let downloadMbps: Double
        public let uploadMbps: Double?
        public let latencyMs: Double?
        public let measuredAt: Date

        public init(
            downloadMbps: Double,
            uploadMbps: Double?,
            latencyMs: Double?,
            measuredAt: Date
        ) {
            self.downloadMbps = downloadMbps
            self.uploadMbps = uploadMbps
            self.latencyMs = latencyMs
            self.measuredAt = measuredAt
        }
    }

    public static func writeLatestSummary(
        _ summary: LatestMeasurementSummary,
        userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)
    ) {
        guard let defaults = userDefaults,
              let data = try? JSONEncoder().encode(summary) else { return }
        defaults.set(data, forKey: latestSummaryKey)
    }

    public static func readLatestSummary(
        userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)
    ) -> LatestMeasurementSummary? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: latestSummaryKey) else { return nil }
        return try? JSONDecoder().decode(LatestMeasurementSummary.self, from: data)
    }
}

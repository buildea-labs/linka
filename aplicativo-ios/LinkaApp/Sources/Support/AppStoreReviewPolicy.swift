import Foundation

struct AppStoreReviewPolicy {
    static let minimumCompletedMeasurements = 3
    static let minimumDaysSinceFirstMeasurement = 7
    static let cooldown: TimeInterval = 120 * 24 * 60 * 60

    private enum Key {
        static let lastAutomaticRequestAt = "linka.app-store-review.v1.last-automatic-request-at"
        static let lastAutomaticRequestVersion = "linka.app-store-review.v1.last-automatic-request-version"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func shouldRequestReview(completedMeasurementCount: Int, firstCompletedMeasurementAt: Date?, hasInteractedWithCurrentResult: Bool, now: Date = Date(), appVersion: String) -> Bool {
        guard completedMeasurementCount >= Self.minimumCompletedMeasurements,
              let firstCompletedMeasurementAt,
              now.timeIntervalSince(firstCompletedMeasurementAt) >= TimeInterval(Self.minimumDaysSinceFirstMeasurement * 24 * 60 * 60),
              hasInteractedWithCurrentResult else { return false }
        if let lastRequestAt = defaults.object(forKey: Key.lastAutomaticRequestAt) as? Date,
           now.timeIntervalSince(lastRequestAt) < Self.cooldown { return false }
        return defaults.string(forKey: Key.lastAutomaticRequestVersion) != appVersion
    }

    /// StoreKit não informa se o diálogo foi mostrado, fechado ou convertido em nota.
    func recordAutomaticRequest(now: Date = Date(), appVersion: String) {
        defaults.set(now, forKey: Key.lastAutomaticRequestAt)
        defaults.set(appVersion, forKey: Key.lastAutomaticRequestVersion)
    }
}

enum AppStoreReviewPromptPresentationPolicy {
    static func isSafe(sceneIsActive: Bool, resultIsVisible: Bool, hasBlockingPresentation: Bool) -> Bool {
        sceneIsActive && resultIsVisible && !hasBlockingPresentation
    }
}

import Foundation

public enum LinkaSystemAction: String, Codable, CaseIterable, Hashable, Sendable {
    case startSpeedTest
    case openLatestMeasurement
    case openHistory
    case getLatestResult
}

public struct LinkaSystemActionResponse: Equatable, Sendable {
    public let action: LinkaSystemAction
    public let value: String?

    public init(
        action: LinkaSystemAction,
        value: String? = nil
    ) {
        self.action = action
        self.value = value
    }
}

public enum LinkaAppIntentExecutionError: Error, Equatable, Sendable {
    case notConfigured
    case mismatchedResponse(expected: LinkaSystemAction, actual: LinkaSystemAction)
    case missingValue(action: LinkaSystemAction)
}

public struct LinkaAppIntentExecutor: Sendable {
    public typealias Handler = @Sendable (LinkaSystemAction) async throws -> LinkaSystemActionResponse

    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func execute(_ action: LinkaSystemAction) async throws -> LinkaSystemActionResponse {
        let response = try await handler(action)

        guard response.action == action else {
            throw LinkaAppIntentExecutionError.mismatchedResponse(
                expected: action,
                actual: response.action
            )
        }

        if action == .getLatestResult {
            let value = response.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else {
                throw LinkaAppIntentExecutionError.missingValue(action: action)
            }
        }

        return response
    }

    public static let unconfigured = LinkaAppIntentExecutor { _ in
        throw LinkaAppIntentExecutionError.notConfigured
    }
}

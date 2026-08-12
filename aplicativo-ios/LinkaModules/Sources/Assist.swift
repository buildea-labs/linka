import Foundation

public struct AssistContext: Codable, Equatable, Sendable {
    public let question: String
    public let currentMeasurement: NetworkMeasurement
    public let recentMeasurements: [NetworkMeasurement]

    public init(
        question: String,
        currentMeasurement: NetworkMeasurement,
        recentMeasurements: [NetworkMeasurement] = []
    ) {
        self.question = question
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
    }
}

public struct AssistResponse: Codable, Equatable, Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol AssistProviding: Sendable {
    func answer(_ context: AssistContext) async throws -> AssistResponse
}

public protocol AssistTransport: Sendable {
    func answer(_ request: AssistContext) async throws -> AssistResponse
}

public struct TransportBackedAssistProvider<Transport: AssistTransport>: AssistProviding {
    private let transport: Transport

    public init(transport: Transport) {
        self.transport = transport
    }

    public func answer(_ context: AssistContext) async throws -> AssistResponse {
        try await transport.answer(context)
    }
}

public enum AssistError: Error, Equatable, Sendable {
    case notConfigured
}

public struct UnconfiguredAssistTransport: AssistTransport {
    public init() {}

    public func answer(_ request: AssistContext) async throws -> AssistResponse {
        throw AssistError.notConfigured
    }
}

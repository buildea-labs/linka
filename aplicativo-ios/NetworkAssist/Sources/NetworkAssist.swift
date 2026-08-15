import Foundation
import NetworkCore

public enum NetworkAssistDisposition: String, Codable, Equatable, Sendable {
    case answered
    case insufficientEvidence
    case requiresDiagnosis
    case unsupported
}

public enum NetworkAssistEvidenceKind: String, Codable, Equatable, Sendable {
    case metric
    case comparison
    case statistic
    case trend
    case context
}

public struct NetworkAssistEvidence: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let kind: NetworkAssistEvidenceKind
    public let metricKey: String?
    public let value: Double?
    public let baselineValue: Double?
    public let percentChange: Double?
    public let unit: String?
    public let direction: String?
    public let sourceMeasurementIDs: [UUID]

    public init(
        id: String,
        kind: NetworkAssistEvidenceKind,
        metricKey: String? = nil,
        value: Double? = nil,
        baselineValue: Double? = nil,
        percentChange: Double? = nil,
        unit: String? = nil,
        direction: String? = nil,
        sourceMeasurementIDs: [UUID] = []
    ) {
        self.id = id
        self.kind = kind
        self.metricKey = metricKey
        self.value = value
        self.baselineValue = baselineValue
        self.percentChange = percentChange
        self.unit = unit
        self.direction = direction
        self.sourceMeasurementIDs = sourceMeasurementIDs
    }
}

public struct NetworkAssistPolicy: Codable, Equatable, Sendable {
    public let observationalOnly: Bool
    public let mayInferRootCause: Bool
    public let mayRecommendRepair: Bool
    public let mustGroundInProvidedData: Bool
    public let handoffWhenDiagnosisIsRequired: Bool

    public static let measurementUnderstanding = NetworkAssistPolicy(
        observationalOnly: true,
        mayInferRootCause: false,
        mayRecommendRepair: false,
        mustGroundInProvidedData: true,
        handoffWhenDiagnosisIsRequired: true
    )
}

public struct NetworkAssistContext: Codable, Equatable, Sendable {
    public let question: String
    public let currentMeasurement: NetworkMeasurement
    public let recentMeasurements: [NetworkMeasurement]
    public let evidence: [NetworkAssistEvidence]
    public let locale: String?

    public init(
        question: String,
        currentMeasurement: NetworkMeasurement,
        recentMeasurements: [NetworkMeasurement] = [],
        evidence: [NetworkAssistEvidence] = [],
        locale: String? = nil
    ) {
        self.question = question
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.evidence = evidence
        self.locale = locale
    }
}

public struct NetworkAssistRequest: Codable, Equatable, Sendable {
    public let question: String
    public let currentMeasurement: NetworkMeasurement
    public let recentMeasurements: [NetworkMeasurement]
    public let evidence: [NetworkAssistEvidence]
    public let locale: String?
    public let policy: NetworkAssistPolicy

    init(validated context: NetworkAssistContext) {
        self.question = context.question.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currentMeasurement = context.currentMeasurement
        self.recentMeasurements = context.recentMeasurements
        self.evidence = context.evidence
        self.locale = context.locale
        self.policy = .measurementUnderstanding
    }

    public var knownEvidenceIDs: Set<String> {
        var ids = Set(evidence.map(\.id))
        ids.insert(Self.currentMeasurementEvidenceID(currentMeasurement.id))
        for measurement in recentMeasurements {
            ids.insert(Self.recentMeasurementEvidenceID(measurement.id))
        }
        return ids
    }

    public static func currentMeasurementEvidenceID(_ id: UUID) -> String {
        "current:\(id.uuidString.lowercased())"
    }

    public static func recentMeasurementEvidenceID(_ id: UUID) -> String {
        "recent:\(id.uuidString.lowercased())"
    }
}

public struct NetworkAssistResponse: Codable, Equatable, Sendable {
    public let text: String
    public let longText: String?
    public let disposition: NetworkAssistDisposition
    public let evidenceIDs: [String]

    public init(
        text: String,
        longText: String? = nil,
        disposition: NetworkAssistDisposition = .answered,
        evidenceIDs: [String] = []
    ) {
        self.text = text
        self.longText = longText
        self.disposition = disposition
        self.evidenceIDs = evidenceIDs
    }
}

public struct NetworkAssistConfiguration: Equatable, Sendable {
    public let maximumQuestionLength: Int
    public let maximumRecentMeasurements: Int
    public let maximumEvidenceItems: Int

    public init(
        maximumQuestionLength: Int = 500,
        maximumRecentMeasurements: Int = 20,
        maximumEvidenceItems: Int = 50
    ) {
        self.maximumQuestionLength = max(1, maximumQuestionLength)
        self.maximumRecentMeasurements = max(0, maximumRecentMeasurements)
        self.maximumEvidenceItems = max(0, maximumEvidenceItems)
    }
}

public enum NetworkAssistError: Error, Equatable, Sendable {
    case notConfigured
    case emptyQuestion
    case questionTooLong(maximum: Int)
    case invalidMeasurement(UUID)
    case tooManyRecentMeasurements(maximum: Int)
    case tooManyEvidenceItems(maximum: Int)
    case invalidEvidenceID(String)
    case duplicateEvidenceID(String)
    case unknownEvidenceSource(UUID)
    case emptyResponse
    case unknownResponseEvidenceID(String)
    case answeredWithoutEvidence
}

public protocol NetworkAssistProviding: Sendable {
    func answer(_ context: NetworkAssistContext) async throws -> NetworkAssistResponse
}

public protocol NetworkAssistTransport: Sendable {
    func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse
}

public struct NetworkAssistService<Transport: NetworkAssistTransport>: NetworkAssistProviding {
    private let transport: Transport
    public let configuration: NetworkAssistConfiguration

    public init(
        transport: Transport,
        configuration: NetworkAssistConfiguration = .init()
    ) {
        self.transport = transport
        self.configuration = configuration
    }

    public func answer(_ context: NetworkAssistContext) async throws -> NetworkAssistResponse {
        try validate(context)
        let request = NetworkAssistRequest(validated: context)
        let response = try await transport.answer(request)
        try validate(response, against: request)
        let trimmedLong = response.longText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return NetworkAssistResponse(
            text: response.text.trimmingCharacters(in: .whitespacesAndNewlines),
            longText: (trimmedLong?.isEmpty == false) ? trimmedLong : nil,
            disposition: response.disposition,
            evidenceIDs: response.evidenceIDs
        )
    }

    private func validate(_ context: NetworkAssistContext) throws {
        let question = context.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            throw NetworkAssistError.emptyQuestion
        }
        guard question.count <= configuration.maximumQuestionLength else {
            throw NetworkAssistError.questionTooLong(maximum: configuration.maximumQuestionLength)
        }
        guard NetworkMeasurementContract.isValid(context.currentMeasurement) else {
            throw NetworkAssistError.invalidMeasurement(context.currentMeasurement.id)
        }
        guard context.recentMeasurements.count <= configuration.maximumRecentMeasurements else {
            throw NetworkAssistError.tooManyRecentMeasurements(maximum: configuration.maximumRecentMeasurements)
        }
        for measurement in context.recentMeasurements where !NetworkMeasurementContract.isValid(measurement) {
            throw NetworkAssistError.invalidMeasurement(measurement.id)
        }
        guard context.evidence.count <= configuration.maximumEvidenceItems else {
            throw NetworkAssistError.tooManyEvidenceItems(maximum: configuration.maximumEvidenceItems)
        }

        let knownMeasurementIDs = Set([context.currentMeasurement.id] + context.recentMeasurements.map(\.id))
        var evidenceIDs = Set<String>()
        for evidence in context.evidence {
            let normalizedID = evidence.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedID.isEmpty else {
                throw NetworkAssistError.invalidEvidenceID(evidence.id)
            }
            guard evidenceIDs.insert(normalizedID).inserted else {
                throw NetworkAssistError.duplicateEvidenceID(normalizedID)
            }
            for sourceID in evidence.sourceMeasurementIDs where !knownMeasurementIDs.contains(sourceID) {
                throw NetworkAssistError.unknownEvidenceSource(sourceID)
            }
            let numericValues = [evidence.value, evidence.baselineValue, evidence.percentChange]
            if numericValues.contains(where: { value in
                guard let value else { return false }
                return !value.isFinite
            }) {
                throw NetworkAssistError.invalidEvidenceID(normalizedID)
            }
        }
    }

    private func validate(
        _ response: NetworkAssistResponse,
        against request: NetworkAssistRequest
    ) throws {
        guard !response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NetworkAssistError.emptyResponse
        }

        let knownIDs = request.knownEvidenceIDs
        for evidenceID in response.evidenceIDs where !knownIDs.contains(evidenceID) {
            throw NetworkAssistError.unknownResponseEvidenceID(evidenceID)
        }

        if response.disposition == .answered && response.evidenceIDs.isEmpty {
            throw NetworkAssistError.answeredWithoutEvidence
        }
    }
}

public struct UnconfiguredNetworkAssistTransport: NetworkAssistTransport {
    public init() {}

    public func answer(_ request: NetworkAssistRequest) async throws -> NetworkAssistResponse {
        throw NetworkAssistError.notConfigured
    }
}

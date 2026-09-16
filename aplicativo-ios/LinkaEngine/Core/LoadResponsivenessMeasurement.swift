import Foundation

/// Ambiente lógico da medição. Produção usa os três endpoints oficiais da
/// Cloudflare; testes podem injetar URLs e um transporte sem tocar a rede.
public struct SpeedTestEnvironment: Equatable, Sendable {
    public let identifier: String
    public let downloadEndpoint: URL
    public let uploadEndpoint: URL
    public let latencyProbeEndpoint: URL

    public init(identifier: String, downloadEndpoint: URL, uploadEndpoint: URL, latencyProbeEndpoint: URL) {
        self.identifier = identifier
        self.downloadEndpoint = downloadEndpoint
        self.uploadEndpoint = uploadEndpoint
        self.latencyProbeEndpoint = latencyProbeEndpoint
    }

    public static let cloudflare = SpeedTestEnvironment(
        identifier: "cloudflare-speedtest-v1",
        downloadEndpoint: URL(string: "https://speed.cloudflare.com/__down")!,
        uploadEndpoint: URL(string: "https://speed.cloudflare.com/__up")!,
        latencyProbeEndpoint: URL(string: "https://speed.cloudflare.com/__down?bytes=0")!
    )

    public func downloadURL(bytes: Int) -> URL {
        var components = URLComponents(url: downloadEndpoint, resolvingAgainstBaseURL: false)!
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "bytes" }
        items.append(URLQueryItem(name: "bytes", value: String(bytes)))
        components.queryItems = items
        return components.url!
    }
}

public enum SpeedTestTransportRequest: Sendable {
    case download(URL)
    case upload(URL, Data)
    case probe(URL)
}

public struct SpeedTestTransportResponse: Sendable {
    public let statusCode: Int
    public let byteCount: Int

    public init(statusCode: Int, byteCount: Int) {
        self.statusCode = statusCode
        self.byteCount = byteCount
    }
}

/// Transporte injetável para que o motor possa ser validado contra respostas
/// determinísticas. Não escolhe metodologia nem altera o ambiente lógico.
public protocol SpeedTestTransport: Sendable {
    func execute(_ request: SpeedTestTransportRequest) async throws -> SpeedTestTransportResponse
}

public final class URLSessionSpeedTestTransport: SpeedTestTransport, @unchecked Sendable {
    private let session: URLSession

    public init(maximumConnectionsPerHost: Int = 6) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.httpMaximumConnectionsPerHost = maximumConnectionsPerHost
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }

    public func execute(_ request: SpeedTestTransportRequest) async throws -> SpeedTestTransportResponse {
        switch request {
        case .download(let url):
            let (data, response) = try await session.data(from: url)
            return SpeedTestTransportResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                byteCount: data.count
            )
        case .upload(let url, let payload):
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let (_, response) = try await session.upload(for: request, from: payload)
            return SpeedTestTransportResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                byteCount: payload.count
            )
        case .probe(let url):
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 1
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let (data, response) = try await session.data(for: request)
            return SpeedTestTransportResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                byteCount: data.count
            )
        }
    }
}

public enum EngineLoadResponsivenessIntegrity: String, Codable, Equatable, Hashable, Sendable {
    case valid
    case baselineInconclusive
    case downloadInconclusive
    case uploadInconclusive
}

public enum EngineLoadSaturation: String, Codable, Equatable, Hashable, Sendable {
    case sustained
    case insufficient
}

public struct EngineLatencyStatistics: Codable, Equatable, Hashable, Sendable {
    public let medianMs: Double
    public let p95Ms: Double
    public let maximumMs: Double
    public let sampleCount: Int
    public let timeoutCount: Int
    public let warmupDurationMs: Int
}

public struct EngineLoadedPhaseEvidence: Codable, Equatable, Hashable, Sendable {
    public let latency: EngineLatencyStatistics?
    public let usefulDurationMs: Int
    public let bytesTransferred: Int64
    public let averageMbps: Double?
    public let saturation: EngineLoadSaturation
}

public struct EngineLoadResponsivenessEvidence: Codable, Equatable, Hashable, Sendable {
    public static let methodologyVersion = 1

    public let methodologyVersion: Int
    public let environmentIdentifier: String
    public let integrity: EngineLoadResponsivenessIntegrity
    public let baseline: EngineLatencyStatistics?
    public let download: EngineLoadedPhaseEvidence?
    public let upload: EngineLoadedPhaseEvidence?

    public init(
        environmentIdentifier: String,
        integrity: EngineLoadResponsivenessIntegrity,
        baseline: EngineLatencyStatistics?,
        download: EngineLoadedPhaseEvidence?,
        upload: EngineLoadedPhaseEvidence?
    ) {
        self.methodologyVersion = Self.methodologyVersion
        self.environmentIdentifier = environmentIdentifier
        self.integrity = integrity
        self.baseline = baseline
        self.download = download
        self.upload = upload
    }
}

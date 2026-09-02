import Foundation

public protocol GatewayProbing: Sendable {
    func probe(gatewayIP: String) async -> GatewayInfo
}

public struct GatewayProber: GatewayProbing {
    private let session: URLSession

    public init(
        timeoutInterval: TimeInterval = 0.5,
        session: URLSession? = nil
    ) {
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = timeoutInterval
            config.timeoutIntervalForResource = timeoutInterval
            config.waitsForConnectivity = false
            config.allowsCellularAccess = false
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            self.session = URLSession(configuration: config)
        }
    }

    public func probe(gatewayIP: String) async -> GatewayInfo {
        let httpURL = "http://\(gatewayIP)"
        let httpsURL = "https://\(gatewayIP)"

        // Verifica ambos concorrentemente
        return await withTaskGroup(of: (String, Bool).self) { group in
            group.addTask {
                return (httpURL, await probeURL(urlString: httpURL))
            }
            group.addTask {
                return (httpsURL, await probeURL(urlString: httpsURL))
            }

            var httpWorks = false
            var httpsWorks = false

            for await (urlStr, works) in group {
                if urlStr == httpURL { httpWorks = works }
                if urlStr == httpsURL { httpsWorks = works }
            }

            let isAccessible = httpWorks || httpsWorks
            let finalURLStr = httpsWorks ? httpsURL : httpURL // Prefere HTTPS se ambos responderem, senão HTTP

            return GatewayInfo(
                ip: gatewayIP,
                isAccessible: isAccessible,
                adminURL: URL(string: finalURLStr)
            )
        }
    }

    private func probeURL(urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Usar HEAD para não baixar corpo

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                // Qualquer código HTTP entre 200 e 499 indica que o serviço web existe
                return (200...499).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}

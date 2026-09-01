import Foundation

public protocol GatewayProbing: Sendable {
    func probe(gatewayIP: String) async -> GatewayInfo
}

public struct GatewayProber: GatewayProbing {
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    public init(
        timeoutInterval: TimeInterval = 1.5,
        session: URLSession? = nil
    ) {
        self.timeoutInterval = timeoutInterval
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
        // Tenta primeiro HTTP
        if let info = await probeURL(urlString: "http://\(gatewayIP)", gatewayIP: gatewayIP) {
            return info
        }
        
        // Se falhar ou não responder HTTP, tenta HTTPS
        if let info = await probeURL(urlString: "https://\(gatewayIP)", gatewayIP: gatewayIP) {
            return info
        }

        // Se nenhuma porta web respondeu, retorna o gateway com fallback de URL padrão
        let fallbackURL = URL(string: "http://\(gatewayIP)")
        return GatewayInfo(
            ip: gatewayIP,
            isAccessible: false,
            vendorHint: nil,
            modelHint: nil,
            adminURL: fallbackURL
        )
    }

    private func probeURL(urlString: String, gatewayIP: String) async -> GatewayInfo? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }

            // Qualquer código HTTP entre 200 e 499 indica que o serviço web do roteador existe e respondeu
            let isAccessible = (200...499).contains(httpResponse.statusCode)
            guard isAccessible else { return nil }

            let serverHeader = httpResponse.value(forHTTPHeaderField: "Server")
            let authHeader = httpResponse.value(forHTTPHeaderField: "WWW-Authenticate")
            
            // Lê primeiros 4KB para buscar título HTML sem consumir memória excessiva
            let snippet = String(data: data.prefix(4096), encoding: .utf8) ?? ""
            let htmlTitle = extractHTMLTitle(from: snippet)

            let match = GatewayVendorFingerprinter.match(
                serverHeader: serverHeader,
                authHeader: authHeader,
                htmlTitle: htmlTitle,
                bodySnippet: snippet
            )

            return GatewayInfo(
                ip: gatewayIP,
                isAccessible: true,
                vendorHint: match?.vendor,
                modelHint: match?.model,
                adminURL: url
            )
        } catch {
            return nil
        }
    }

    private func extractHTMLTitle(from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "<title[^>]*>(.*?)</title>", options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           match.numberOfRanges > 1,
           let titleRange = Range(match.range(at: 1), in: html) {
            let title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? nil : title
        }
        return nil
    }
}

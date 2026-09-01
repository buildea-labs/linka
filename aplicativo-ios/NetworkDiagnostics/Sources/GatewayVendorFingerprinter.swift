import Foundation

/// Analisador de metadados HTTP/HTML para identificação de fabricantes e modelos de roteadores.
public enum GatewayVendorFingerprinter {
    public struct FingerprintMatch: Equatable, Sendable {
        public let vendor: String
        public let model: String?
        
        public init(vendor: String, model: String? = nil) {
            self.vendor = vendor
            self.model = model
        }
    }

    /// Analisa cabeçalhos e trechos HTML para identificar a marca e modelo provável do roteador.
    public static func match(
        serverHeader: String?,
        authHeader: String?,
        htmlTitle: String?,
        bodySnippet: String?
    ) -> FingerprintMatch? {
        let combined = [
            serverHeader ?? "",
            authHeader ?? "",
            htmlTitle ?? "",
            bodySnippet ?? ""
        ].joined(separator: " ").lowercased()

        // 1. TP-Link
        if combined.contains("tp-link") || combined.contains("tplink") || combined.contains("archer") || combined.contains("deco") || combined.contains("omada") {
            let model = extractModel(from: combined, patterns: ["archer [a-z0-9]+", "deco [a-z0-9]+", "tl-wr[0-9]+[a-z]*", "wr[0-9]+n"])
            return FingerprintMatch(vendor: "TP-Link", model: model?.capitalized)
        }

        // 2. Huawei
        if combined.contains("huawei") || combined.contains("echolife") || combined.contains("optixstar") || combined.contains("huaweihomegateway") {
            let model = extractModel(from: combined, patterns: ["hg[0-9]+[a-z0-9]*", "ws[0-9]+", "optixstar [a-z0-9]+"])
            return FingerprintMatch(vendor: "Huawei", model: model?.uppercased())
        }

        // 3. Intelbras
        if combined.contains("intelbras") || combined.contains("twibi") || combined.contains("action rg") || combined.contains("action rf") {
            let model = extractModel(from: combined, patterns: ["twibi [a-z0-9]+", "action r[a-z0-9]+", "w5-[0-9]+[a-z]*", "gf [0-9]+", "gx [0-9]+"])
            return FingerprintMatch(vendor: "Intelbras", model: model?.capitalized)
        }

        // 4. ZTE
        if combined.contains("zte") || combined.contains("zxhn") {
            let model = extractModel(from: combined, patterns: ["zxhn [a-z0-9]+", "f[0-9]{3,4}[a-z0-9]*"])
            return FingerprintMatch(vendor: "ZTE", model: model?.uppercased())
        }

        // 5. Nokia
        if combined.contains("nokia") || combined.contains("fastmile") {
            let model = extractModel(from: combined, patterns: ["beacon [0-9]+", "fastmile [a-z0-9]+"])
            return FingerprintMatch(vendor: "Nokia", model: model?.capitalized)
        }

        // 6. MikroTik
        if combined.contains("mikrotik") || combined.contains("routeros") {
            return FingerprintMatch(vendor: "MikroTik", model: "RouterOS")
        }

        // 7. ASUS
        if combined.contains("asus") || combined.contains("asuswrt") || combined.contains("zenwifi") {
            let model = extractModel(from: combined, patterns: ["rt-a[cx][0-9]+[a-z]*", "zenwifi [a-z0-9]+"])
            return FingerprintMatch(vendor: "ASUS", model: model?.uppercased())
        }

        // 8. Netgear
        if combined.contains("netgear") || combined.contains("nighthawk") || combined.contains("orbi") {
            let model = extractModel(from: combined, patterns: ["nighthawk [a-z0-9]+", "orbi [a-z0-9]+", "r[0-9]{4}"])
            return FingerprintMatch(vendor: "Netgear", model: model?.capitalized)
        }

        // 9. D-Link
        if combined.contains("d-link") || combined.contains("dlink") || combined.contains("dir-") {
            let model = extractModel(from: combined, patterns: ["dir-[0-9]+[a-z]*", "covr-[a-z0-9]+"])
            return FingerprintMatch(vendor: "D-Link", model: model?.uppercased())
        }

        // 10. Sagemcom
        if combined.contains("sagemcom") || combined.contains("fast 5") {
            let model = extractModel(from: combined, patterns: ["fast [0-9]{4}[a-z]*"])
            return FingerprintMatch(vendor: "Sagemcom", model: model?.uppercased())
        }

        // 11. Mercusys
        if combined.contains("mercusys") || combined.contains("halo s") || combined.contains("halo h") {
            let model = extractModel(from: combined, patterns: ["halo [a-z0-9]+", "mr[0-9]+[a-z]*"])
            return FingerprintMatch(vendor: "Mercusys", model: model?.capitalized)
        }

        // 12. Ubiquiti
        if combined.contains("ubiquiti") || combined.contains("unifi") || combined.contains("edgerouter") {
            let model = extractModel(from: combined, patterns: ["dream machine", "unifi [a-z0-9]+", "edgerouter [a-z0-9]+"])
            return FingerprintMatch(vendor: "Ubiquiti", model: model?.capitalized)
        }

        // 13. Cisco / Linksys
        if combined.contains("linksys") || combined.contains("cisco") {
            let model = extractModel(from: combined, patterns: ["velop [a-z0-9]+", "ea[0-9]{4}"])
            return FingerprintMatch(vendor: combined.contains("linksys") ? "Linksys" : "Cisco", model: model?.capitalized)
        }

        return nil
    }

    private static func extractModel(from text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: "\\b" + pattern + "\\b", options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let swiftRange = Range(match.range, in: text) {
                        return String(text[swiftRange])
                    }
                }
            }
        }
        return nil
    }
}

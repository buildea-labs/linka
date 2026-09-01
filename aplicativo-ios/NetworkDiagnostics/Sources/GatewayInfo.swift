import Foundation

/// Representa as informações descobertas sobre o roteador/gateway da rede local.
public struct GatewayInfo: Codable, Equatable, Hashable, Sendable {
    /// Endereço IPv4 do gateway (ex: "192.168.1.1").
    public let ip: String
    
    /// Indica se a interface web de administração respondeu via HTTP ou HTTPS.
    public let isAccessible: Bool
    
    /// Fabricante identificado (ex: "TP-Link", "Huawei", "Intelbras").
    public let vendorHint: String?
    
    /// Modelo provável identificado (ex: "Archer C6", "HG8245").
    public let modelHint: String?
    
    /// URL direta para acessar a página de administração (ex: "http://192.168.1.1").
    public let adminURL: URL?
    
    public init(
        ip: String,
        isAccessible: Bool = false,
        vendorHint: String? = nil,
        modelHint: String? = nil,
        adminURL: URL? = nil
    ) {
        self.ip = ip
        self.isAccessible = isAccessible
        self.vendorHint = vendorHint
        self.modelHint = modelHint
        self.adminURL = adminURL
    }
    
    /// Rótulo amigável para exibição na interface (ex: "TP-Link Archer C6" ou "TP-Link (192.168.1.1)" ou "Roteador").
    public var displayName: String {
        if let vendor = vendorHint, let model = modelHint {
            return "\(vendor) \(model)"
        } else if let vendor = vendorHint {
            return "\(vendor)"
        }
        return "Roteador"
    }
}

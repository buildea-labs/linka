import Foundation
import Network

struct DiscoveredGateway: Identifiable, Hashable {
    let id = UUID()
    var ipAddress: String
    var manufacturer: String?
    var hostname: String?
}

class GatewayScanner: ObservableObject {
    @Published var gateways: [DiscoveredGateway] = []
    @Published var isScanning = false
    
    private var monitor: NWPathMonitor?
    private var browser: NWBrowser?
    
    func startScan() {
        isScanning = true
        gateways = []
        
        monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let endpoints = path.gateways
            
            DispatchQueue.main.async {
                for endpoint in endpoints {
                    if case .hostPort(let host, _) = endpoint {
                        let ip = self.extractIP(from: host)
                        if !self.gateways.contains(where: { $0.ipAddress == ip }) {
                            self.gateways.append(DiscoveredGateway(ipAddress: ip))
                        }
                    }
                }
            }
        }
        monitor?.start(queue: DispatchQueue.global(qos: .userInitiated))
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: "local."), using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            guard let self = self else { return }
            for result in results {
                if case .service(let name, _, _, _) = result.endpoint {
                    let lowerName = name.lowercased()
                    var manufacturer: String? = nil
                    if lowerName.contains("tp-link") { manufacturer = "TP-Link" }
                    else if lowerName.contains("asus") { manufacturer = "ASUS" }
                    else if lowerName.contains("d-link") { manufacturer = "D-Link" }
                    else if lowerName.contains("netgear") { manufacturer = "Netgear" }
                    else if lowerName.contains("intelbras") { manufacturer = "Intelbras" }
                    else if lowerName.contains("huawei") { manufacturer = "Huawei" }
                    
                    DispatchQueue.main.async {
                        // For simplicity we associate bonjour findings with the first gateway or add it.
                        if let idx = self.gateways.firstIndex(where: { $0.hostname == nil }) {
                            self.gateways[idx].hostname = name
                            self.gateways[idx].manufacturer = manufacturer ?? name
                        } else {
                            // If monitor didn't find gateways yet
                            self.gateways.append(DiscoveredGateway(ipAddress: "", manufacturer: manufacturer ?? name, hostname: name))
                        }
                    }
                }
            }
        }
        browser?.start(queue: DispatchQueue.global(qos: .userInitiated))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.stopScan()
        }
    }
    
    func stopScan() {
        isScanning = false
        monitor?.cancel()
        monitor = nil
        browser?.cancel()
        browser = nil
    }
    
    private func extractIP(from host: NWEndpoint.Host) -> String {
        switch host {
        case .ipv4(let address):
            return address.rawValue.map { String($0) }.joined(separator: ".")
        case .ipv6(_):
            // Fallback for ipv6
            let desc = String(describing: host)
            return desc
        default:
            return String(describing: host)
        }
    }
}

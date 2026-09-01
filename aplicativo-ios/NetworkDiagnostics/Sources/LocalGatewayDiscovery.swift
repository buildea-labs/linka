import Foundation
#if canImport(Darwin)
import Darwin
#endif

public struct LocalInterfaceInfo: Equatable, Sendable {
    public let name: String
    public let ipv4Address: String
    public let netmask: String
    public let gatewayCandidate: String?
    
    public init(name: String, ipv4Address: String, netmask: String, gatewayCandidate: String?) {
        self.name = name
        self.ipv4Address = ipv4Address
        self.netmask = netmask
        self.gatewayCandidate = gatewayCandidate
    }
}

public protocol LocalGatewayDiscovering: Sendable {
    func discoverPrimaryInterface() -> LocalInterfaceInfo?
}

public struct LocalGatewayDiscovery: LocalGatewayDiscovering {
    public init() {}

    public func discoverPrimaryInterface() -> LocalInterfaceInfo? {
        #if canImport(Darwin)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        var bestInterface: LocalInterfaceInfo?

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && isRunning && !isLoopback,
               let addr = current.pointee.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET) {
                
                let name = String(cString: current.pointee.ifa_name)
                var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                var netmaskBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))

                let rawAddr = UnsafeRawPointer(addr).assumingMemoryBound(to: sockaddr_in.self)
                var sinAddr = rawAddr.pointee.sin_addr
                inet_ntop(AF_INET, &sinAddr, &ipBuffer, socklen_t(INET_ADDRSTRLEN))
                let ipStr = String(cString: ipBuffer)

                var netmaskStr = "255.255.255.0"
                if let netmask = current.pointee.ifa_netmask {
                    let rawNetmask = UnsafeRawPointer(netmask).assumingMemoryBound(to: sockaddr_in.self)
                    var sinNetmask = rawNetmask.pointee.sin_addr
                    inet_ntop(AF_INET, &sinNetmask, &netmaskBuffer, socklen_t(INET_ADDRSTRLEN))
                    netmaskStr = String(cString: netmaskBuffer)
                }

                let gateway = Self.resolveDefaultGateway(forIP: ipStr, netmask: netmaskStr)
                let info = LocalInterfaceInfo(name: name, ipv4Address: ipStr, netmask: netmaskStr, gatewayCandidate: gateway)

                // Prioritiza interface en0 (Wi-Fi padrão em iOS/macOS)
                if name == "en0" {
                    return info
                } else if bestInterface == nil {
                    bestInterface = info
                }
            }
            ptr = current.pointee.ifa_next
        }

        return bestInterface
        #else
        return nil
        #endif
    }

    /// Calcula o gateway provável a partir do IP e máscara de sub-rede
    public static func resolveDefaultGateway(forIP ip: String, netmask: String) -> String? {
        var ipAddr = in_addr()
        var maskAddr = in_addr()

        guard inet_pton(AF_INET, ip, &ipAddr) == 1,
              inet_pton(AF_INET, netmask, &maskAddr) == 1 else {
            return nil
        }

        let ipHost = UInt32(bigEndian: ipAddr.s_addr)
        let maskHost = UInt32(bigEndian: maskAddr.s_addr)
        let networkHost = ipHost & maskHost

        // O padrão da imensa maioria dos roteadores domésticos é o primeiro IP da sub-rede (.1)
        let gatewayHost = networkHost + 1
        var gatewayAddr = in_addr(s_addr: UInt32(bigEndian: gatewayHost))

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &gatewayAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
        return String(cString: buffer)
    }
}

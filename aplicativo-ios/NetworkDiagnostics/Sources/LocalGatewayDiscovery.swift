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

/// Abstract system calls for testability
public protocol NetworkSystemAPI: Sendable {
    func getInterfaces() -> [(name: String, flags: Int32, isLoopback: Bool, ipv4: String, netmask: String)]
    func getGateway(forInterface name: String) -> String?
}

public struct DefaultNetworkSystemAPI: NetworkSystemAPI {
    public init() {}

    public func getInterfaces() -> [(name: String, flags: Int32, isLoopback: Bool, ipv4: String, netmask: String)] {
        #if canImport(Darwin)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return []
        }
        defer { freeifaddrs(ifaddr) }

        var interfaces: [(name: String, flags: Int32, isLoopback: Bool, ipv4: String, netmask: String)] = []
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
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

                interfaces.append((name: name, flags: flags, isLoopback: isLoopback, ipv4: ipStr, netmask: netmaskStr))
            }
            ptr = current.pointee.ifa_next
        }
        return interfaces
        #else
        return []
        #endif
    }

    public func getGateway(forInterface name: String) -> String? {
        #if canImport(Darwin)
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY]
        var size: Int = 0
        if sysctl(&mib, 6, nil, &size, nil, 0) < 0 { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        if sysctl(&mib, 6, &buffer, &size, nil, 0) < 0 { return nil }

        var next = 0
        while next < size {
            let msg = buffer.withUnsafeBytes { $0.load(fromByteOffset: next, as: rt_msghdr2.self) }
            let msgLen = Int(msg.rtm_msglen)

            let saAddrOffset = MemoryLayout<rt_msghdr2>.stride
            let addrs = Int32(msg.rtm_addrs)

            var currentOffset = saAddrOffset
            var dest: sockaddr_in?
            var gateway: sockaddr_in?

            for i in 0..<RTAX_MAX {
                let flag = Int32(1 << i)
                if (addrs & flag) != 0 {
                    let sa = buffer.withUnsafeBytes { $0.load(fromByteOffset: next + currentOffset, as: sockaddr.self) }
                    let saLen = Int(sa.sa_len > 0 ? sa.sa_len : 16)
                    let advance = (saLen + 3) & ~3

                    if i == RTAX_DST {
                        dest = buffer.withUnsafeBytes { $0.load(fromByteOffset: next + currentOffset, as: sockaddr_in.self) }
                    } else if i == RTAX_GATEWAY {
                        gateway = buffer.withUnsafeBytes { $0.load(fromByteOffset: next + currentOffset, as: sockaddr_in.self) }
                    }
                    currentOffset += advance
                }
            }

            // Destino 0.0.0.0 indica rota default
            if let d = dest, d.sin_family == AF_INET, d.sin_addr.s_addr == 0 {
                if let g = gateway, g.sin_family == AF_INET {
                    let ifIndex = Int32(msg.rtm_index)
                    var ifNameBuffer = [CChar](repeating: 0, count: Int(IFNAMSIZ))
                    if_indextoname(UInt32(ifIndex), &ifNameBuffer)
                    let ifName = String(cString: ifNameBuffer)

                    if ifName == name {
                        var g_addr = g.sin_addr
                        var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        inet_ntop(AF_INET, &g_addr, &ipBuffer, socklen_t(INET_ADDRSTRLEN))
                        return String(cString: ipBuffer)
                    }
                }
            }
            next += msgLen
        }
        return nil
        #else
        return nil
        #endif
    }
}

public struct LocalGatewayDiscovery: LocalGatewayDiscovering {
    let systemAPI: NetworkSystemAPI

    public init(systemAPI: NetworkSystemAPI = DefaultNetworkSystemAPI()) {
        self.systemAPI = systemAPI
    }

    public func discoverPrimaryInterface() -> LocalInterfaceInfo? {
        let interfaces = systemAPI.getInterfaces()
        var bestInterface: LocalInterfaceInfo?

        #if canImport(Darwin)
        let iffUpAndRunning = Int32(IFF_UP | IFF_RUNNING)
        #else
        let iffUpAndRunning = Int32(0) // Dummy fallback
        #endif

        for iface in interfaces {
            let isUpAndRunning = (iface.flags & iffUpAndRunning) == iffUpAndRunning
            let isLoopback = iface.isLoopback

            // Somente interfaces de rede local (Wi-Fi = en0, ethernet = en1, etc). Ignora pdp_ip (celular) e utun (VPN).
            if isUpAndRunning && !isLoopback && iface.name.hasPrefix("en") {
                let gateway = systemAPI.getGateway(forInterface: iface.name)

                // Validação de segurança: apenas aceitar IPs privados/locais
                var validGateway: String? = nil
                if let gw = gateway, Self.isPrivateIPv4(gw) {
                    validGateway = gw
                }

                let info = LocalInterfaceInfo(name: iface.name, ipv4Address: iface.ipv4, netmask: iface.netmask, gatewayCandidate: validGateway)

                if iface.name == "en0" {
                    return info
                } else if bestInterface == nil {
                    bestInterface = info
                }
            }
        }
        return bestInterface
    }

    /// Retorna true se o IP estiver nas faixas de rede privada (RFC 1918) ou link-local
    public static func isPrivateIPv4(_ ip: String) -> Bool {
        var addr = in_addr()
        guard inet_pton(AF_INET, ip, &addr) == 1 else { return false }
        let host = UInt32(bigEndian: addr.s_addr)

        // 10.0.0.0/8
        if (host & 0xFF000000) == 0x0A000000 { return true }
        // 172.16.0.0/12
        if (host & 0xFFF00000) == 0xAC100000 { return true }
        // 192.168.0.0/16
        if (host & 0xFFFF0000) == 0xC0A80000 { return true }
        // 169.254.0.0/16 (Link-local)
        if (host & 0xFFFF0000) == 0xA9FE0000 { return true }

        return false
    }
}

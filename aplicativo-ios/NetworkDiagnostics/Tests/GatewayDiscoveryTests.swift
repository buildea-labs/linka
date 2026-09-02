import XCTest
@testable import NetworkDiagnostics

final class GatewayDiscoveryTests: XCTestCase {

    func testIsPrivateIPv4() {
        XCTAssertTrue(LocalGatewayDiscovery.isPrivateIPv4("192.168.1.1"))
        XCTAssertTrue(LocalGatewayDiscovery.isPrivateIPv4("10.0.0.1"))
        XCTAssertTrue(LocalGatewayDiscovery.isPrivateIPv4("172.16.0.1"))
        XCTAssertTrue(LocalGatewayDiscovery.isPrivateIPv4("172.31.255.254"))
        XCTAssertTrue(LocalGatewayDiscovery.isPrivateIPv4("169.254.0.1")) // Link-local
        
        XCTAssertFalse(LocalGatewayDiscovery.isPrivateIPv4("8.8.8.8"))
        XCTAssertFalse(LocalGatewayDiscovery.isPrivateIPv4("1.1.1.1"))
        XCTAssertFalse(LocalGatewayDiscovery.isPrivateIPv4("127.0.0.1")) // Loopback shouldn't be valid gateway
    }

    func testGatewayInfoDisplayName() {
        let info3 = GatewayInfo(ip: "192.168.1.1", isAccessible: false)
        XCTAssertEqual(info3.displayName, "Roteador")
    }
}

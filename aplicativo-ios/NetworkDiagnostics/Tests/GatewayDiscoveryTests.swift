import XCTest
@testable import NetworkDiagnostics

final class GatewayDiscoveryTests: XCTestCase {

    func testResolveDefaultGatewayCalculatesCorrectIP() {
        // Subrede clássica /24 (192.168.1.0/24)
        let gw1 = LocalGatewayDiscovery.resolveDefaultGateway(forIP: "192.168.1.145", netmask: "255.255.255.0")
        XCTAssertEqual(gw1, "192.168.1.1")

        // Subrede /24 com base zero (192.168.0.0/24)
        let gw2 = LocalGatewayDiscovery.resolveDefaultGateway(forIP: "192.168.0.22", netmask: "255.255.255.0")
        XCTAssertEqual(gw2, "192.168.0.1")

        // Subrede 10.0.0.0/24
        let gw3 = LocalGatewayDiscovery.resolveDefaultGateway(forIP: "10.0.0.77", netmask: "255.255.255.0")
        XCTAssertEqual(gw3, "10.0.0.1")

        // IP inválido
        let gwInvalid = LocalGatewayDiscovery.resolveDefaultGateway(forIP: "invalido", netmask: "255.255.255.0")
        XCTAssertNil(gwInvalid)
    }

    func testGatewayVendorFingerprinterMatchesTPLink() {
        let match1 = GatewayVendorFingerprinter.match(
            serverHeader: "RomPager/4.51",
            authHeader: "Basic realm=\"TP-Link Wireless Router Archer C6\"",
            htmlTitle: "Archer C6",
            bodySnippet: nil
        )
        XCTAssertEqual(match1?.vendor, "TP-Link")
        XCTAssertEqual(match1?.model, "Archer C6")

        let match2 = GatewayVendorFingerprinter.match(
            serverHeader: nil,
            authHeader: nil,
            htmlTitle: "Deco M4 Login",
            bodySnippet: "Bem-vindo ao TP-Link Deco M4"
        )
        XCTAssertEqual(match2?.vendor, "TP-Link")
        XCTAssertEqual(match2?.model, "Deco M4")
    }

    func testGatewayVendorFingerprinterMatchesHuawei() {
        let match = GatewayVendorFingerprinter.match(
            serverHeader: "HuaweiHomeGateway",
            authHeader: nil,
            htmlTitle: "EchoLife HG8245W5",
            bodySnippet: nil
        )
        XCTAssertEqual(match?.vendor, "Huawei")
        XCTAssertEqual(match?.model, "HG8245W5")
    }

    func testGatewayVendorFingerprinterMatchesIntelbras() {
        let match = GatewayVendorFingerprinter.match(
            serverHeader: "micro_httpd",
            authHeader: "Basic realm=\"Intelbras Twibi Giga\"",
            htmlTitle: "Intelbras Twibi",
            bodySnippet: nil
        )
        XCTAssertEqual(match?.vendor, "Intelbras")
        XCTAssertEqual(match?.model, "Twibi Giga")
    }

    func testGatewayVendorFingerprinterMatchesZTEAndMikroTik() {
        let matchZTE = GatewayVendorFingerprinter.match(
            serverHeader: "ZTE Web Server",
            authHeader: nil,
            htmlTitle: "ZXHN F670L",
            bodySnippet: nil
        )
        XCTAssertEqual(matchZTE?.vendor, "ZTE")
        XCTAssertEqual(matchZTE?.model, "ZXHN F670L")

        let matchMikroTik = GatewayVendorFingerprinter.match(
            serverHeader: "RouterOS v7.12",
            authHeader: nil,
            htmlTitle: "MikroTik RouterOS",
            bodySnippet: nil
        )
        XCTAssertEqual(matchMikroTik?.vendor, "MikroTik")
        XCTAssertEqual(matchMikroTik?.model, "RouterOS")
    }

    func testGatewayVendorFingerprinterReturnsNilForUnknown() {
        let match = GatewayVendorFingerprinter.match(
            serverHeader: "nginx",
            authHeader: nil,
            htmlTitle: "Welcome",
            bodySnippet: "Hello World"
        )
        XCTAssertNil(match)
    }

    func testGatewayInfoDisplayName() {
        let info1 = GatewayInfo(ip: "192.168.1.1", isAccessible: true, vendorHint: "TP-Link", modelHint: "Archer C6")
        XCTAssertEqual(info1.displayName, "TP-Link Archer C6")

        let info2 = GatewayInfo(ip: "192.168.1.1", isAccessible: true, vendorHint: "Huawei")
        XCTAssertEqual(info2.displayName, "Huawei")

        let info3 = GatewayInfo(ip: "192.168.1.1", isAccessible: false)
        XCTAssertEqual(info3.displayName, "Roteador")
    }
}

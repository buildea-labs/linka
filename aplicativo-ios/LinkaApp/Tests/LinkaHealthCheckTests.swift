import XCTest
@testable import LinkaApp

@MainActor
final class LinkaHealthCheckTests: XCTestCase {
    func testHealthCheckInitialState() {
        let healthCheck = LinkaHealthCheck()
        XCTAssertEqual(healthCheck.statusText, "Verificando rede...")
        XCTAssertFalse(healthCheck.isOnline)
    }
}

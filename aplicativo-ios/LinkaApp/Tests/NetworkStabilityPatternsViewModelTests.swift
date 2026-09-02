import XCTest
import LinkaEntitlements
import NetworkCore
import LinkaModules
@testable import LinkaApp

@MainActor
final class NetworkStabilityPatternsViewModelTests: XCTestCase {
    
    func testLoadWithNoNetworkIdentity() async {
        let viewModel = NetworkStabilityPatternsViewModel(entitlements: MockEntitlements(snapshot: .plus(status: .active, source: .subscription)))
        
        let measurement = NetworkMeasurement(
            connectionKind: nil,
            networkIdentifier: nil
        )
        
        await viewModel.load(currentMeasurement: measurement)
        
        XCTAssertEqual(viewModel.state, .unavailable)
    }
}

class MockEntitlements: StoreKitEntitlementProvider {
    var snapshot: LinkaEntitlementSnapshot
    
    init(snapshot: LinkaEntitlementSnapshot) {
        self.snapshot = snapshot
    }
    
    func refresh() async {}
}

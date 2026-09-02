import XCTest
import SwiftUI
#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import LinkaApp

final class SettingsProductionStateTests: XCTestCase {
    func testExternalLinksUseCanonicalOriginAndSpecificPaths() {
        XCTAssertEqual(LinkaExternalLinks.canonicalOrigin.absoluteString, "https://linka.app")
        XCTAssertEqual(LinkaExternalLinks.website.absoluteString, "https://linka.app")
        XCTAssertEqual(LinkaExternalLinks.about.absoluteString, "https://linka.app/sobre")
        XCTAssertEqual(LinkaExternalLinks.howWeMeasure.absoluteString, "https://linka.app/como-medimos")
        XCTAssertEqual(LinkaExternalLinks.privacy.absoluteString, "https://linka.app/privacidade")
        XCTAssertEqual(LinkaExternalLinks.terms.absoluteString, "https://linka.app/termos")
        XCTAssertEqual(LinkaExternalLinks.support.absoluteString, "https://linka.app/suporte")
    }

    func testAdvancedWiFiStateReflectsEntitlementConfigurationAndEnabledFlag() {
        XCTAssertEqual(
            LinkaAdvancedWiFiSettingsState.state(hasEntitlement: false, configured: false, enabled: true),
            .requiresPlus
        )
        XCTAssertEqual(
            LinkaAdvancedWiFiSettingsState.state(hasEntitlement: true, configured: false, enabled: true),
            .needsConfiguration
        )
        XCTAssertEqual(
            LinkaAdvancedWiFiSettingsState.state(hasEntitlement: true, configured: true, enabled: true),
            .active
        )
        XCTAssertEqual(
            LinkaAdvancedWiFiSettingsState.state(hasEntitlement: true, configured: true, enabled: false),
            .disabled
        )
    }

    func testAppearancePreferenceMapsToSystemLightAndDark() {
        XCTAssertNil(LinkaAppearancePreference.system.colorScheme)
        XCTAssertEqual(LinkaAppearancePreference.light.colorScheme, .light)
        XCTAssertEqual(LinkaAppearancePreference.dark.colorScheme, .dark)
        XCTAssertNil(LinkaAppearancePreference(rawValue: "unknown")?.colorScheme)
    }

    func testVersionDisplayUsesRealBundleKeysAndFallbacks() {
        XCTAssertEqual(
            LinkaAppVersion.displayString(
                infoDictionary: [
                    "CFBundleShortVersionString": "2.3.4",
                    "CFBundleVersion": "57"
                ]
            ),
            "2.3.4 (build 57)"
        )
        XCTAssertEqual(
            LinkaAppVersion.displayString(infoDictionary: [:]),
            "1.0 (build 1)"
        )
    }

    #if canImport(CoreLocation)
    func testWiFiIdentificationStateDistinguishesUserAndSystemStates() {
        XCTAssertEqual(
            WiFiNetworkPermission.state(
                enabled: false,
                authorizationStatus: .authorizedWhenInUse,
                accuracyAuthorization: .fullAccuracy
            ),
            .disabledByUser
        )
        XCTAssertEqual(
            WiFiNetworkPermission.state(
                enabled: true,
                authorizationStatus: .authorizedWhenInUse,
                accuracyAuthorization: .fullAccuracy
            ),
            .active
        )
        XCTAssertEqual(
            WiFiNetworkPermission.state(
                enabled: true,
                authorizationStatus: .authorizedWhenInUse,
                accuracyAuthorization: .reducedAccuracy
            ),
            .permissionRequired
        )
        XCTAssertEqual(
            WiFiNetworkPermission.state(
                enabled: true,
                authorizationStatus: .denied,
                accuracyAuthorization: .fullAccuracy
            ),
            .permissionDenied
        )
        XCTAssertEqual(
            WiFiNetworkPermission.state(
                enabled: true,
                authorizationStatus: .notDetermined,
                accuracyAuthorization: .fullAccuracy
            ),
            .permissionRequired
        )
    }
    #endif
}

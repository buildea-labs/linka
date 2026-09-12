import SwiftUI
import NetworkCore
#if canImport(CoreLocation) && os(iOS)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum WiFiNetworkIdentificationState: Equatable {
    case active
    case disabledByUser
    case permissionRequired
    case permissionDenied
    case unavailable

    var statusText: String {
        switch self {
        case .active: return LinkaCopy.value("wifi.identification.active")
        case .disabledByUser: return LinkaCopy.value("wifi.identification.disabled")
        case .permissionRequired: return LinkaCopy.value("wifi.identification.permissionRequired")
        case .permissionDenied: return LinkaCopy.value("wifi.identification.permissionDenied")
        case .unavailable: return LinkaCopy.value("common.unavailable")
        }
    }
}

enum WiFiNetworkPermission {
    #if canImport(CoreLocation) && os(iOS)
    private static let manager = CLLocationManager()

    static func state(enabled: Bool) -> WiFiNetworkIdentificationState {
        state(
            enabled: enabled,
            authorizationStatus: manager.authorizationStatus,
            accuracyAuthorization: manager.accuracyAuthorization
        )
    }

    static func state(
        enabled: Bool,
        authorizationStatus: CLAuthorizationStatus,
        accuracyAuthorization: CLAccuracyAuthorization
    ) -> WiFiNetworkIdentificationState {
        guard enabled else { return .disabledByUser }
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return accuracyAuthorization == .fullAccuracy ? .active : .permissionRequired
        case .denied, .restricted:
            return .permissionDenied
        case .notDetermined:
            return .permissionRequired
        @unknown default:
            return .permissionRequired
        }
    }

    static func statusText(enabled: Bool) -> String {
        state(enabled: enabled).statusText
    }
    static var canOpenSystemSettings: Bool { manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted }
    static var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }
    @MainActor static func requestIdentification() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if manager.accuracyAuthorization != .fullAccuracy {
                manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "WiFiIdentification")
            }
        case .denied, .restricted:
            openSystemSettings()
        @unknown default:
            break
        }
    }
    @MainActor static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    #else
    static func state(enabled: Bool) -> WiFiNetworkIdentificationState { .unavailable }
    static func statusText(enabled: Bool) -> String { state(enabled: enabled).statusText }
    static var canOpenSystemSettings: Bool { false }
    static var isAuthorized: Bool { false }
    static func requestIdentification() {}
    static func openSystemSettings() {}
    #endif
}

extension WiFiSecurityType {
    var displayLabel: String {
        switch self {
        case .open: return LinkaCopy.value("wifi.security.open")
        case .wep: return "WEP"
        case .personal: return LinkaCopy.value("wifi.security.personal")
        case .enterprise: return LinkaCopy.value("wifi.security.enterprise")
        case .unknown: return LinkaCopy.value("wifi.security.unknown")
        }
    }
}

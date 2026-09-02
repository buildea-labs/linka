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
        case .active: return "Ativada"
        case .disabledByUser: return "Desativada"
        case .permissionRequired: return "Permissão necessária"
        case .permissionDenied: return "Negada no sistema"
        case .unavailable: return "Não disponível"
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
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        else { openSystemSettings() }
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
        case .open: return "Aberta"
        case .wep: return "WEP"
        case .personal: return "Rede pessoal protegida"
        case .enterprise: return "Rede corporativa"
        case .unknown: return "Não informada"
        }
    }
}

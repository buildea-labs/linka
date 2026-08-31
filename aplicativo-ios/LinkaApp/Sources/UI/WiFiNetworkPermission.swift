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

enum WiFiNetworkPermission {
    #if canImport(CoreLocation) && os(iOS)
    private static let manager = CLLocationManager()
    static func statusText(enabled: Bool) -> String {
        guard enabled else { return "Desativada" }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return manager.accuracyAuthorization == .fullAccuracy ? "Ativada" : "Permissão necessária"
        case .denied, .restricted: return "Permissão necessária"
        case .notDetermined: return "Permissão necessária"
        @unknown default: return "Permissão necessária"
        }
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
    static func statusText(enabled: Bool) -> String { "Não disponível" }
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


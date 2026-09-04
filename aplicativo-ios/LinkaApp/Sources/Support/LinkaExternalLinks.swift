import Foundation
import SwiftUI

/// Destinos públicos do Linka. A base é única para que Ajustes, paywall e
/// futuras superfícies legais não divirjam silenciosamente.
enum LinkaExternalLinks {
    static let canonicalOrigin = URL(string: "https://linka.app")!
    static let website = canonicalOrigin
    static let about = canonicalOrigin.appending(path: "sobre")
    static let howWeMeasure = canonicalOrigin.appending(path: "como-medimos")
    static let privacy = canonicalOrigin.appending(path: "privacidade")
    static let terms = canonicalOrigin.appending(path: "termos")
    static let support = canonicalOrigin.appending(path: "suporte")
    static let subscriptionManagement = URL(string: "https://apps.apple.com/account/subscriptions")!
}

enum LinkaWiFiPreferences {
    static let identificationEnabledKey = "linka.wifi-identification.enabled.v1"
    static let advancedDiagnosticsEnabledKey = "linka.advanced-wifi.enabled.v1"
    static let advancedConfiguredKey = "linka.advanced-wifi.configured.v1"

    static var isIdentificationEnabled: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: identificationEnabledKey) != nil else { return true }
        return defaults.bool(forKey: identificationEnabledKey)
    }

    static var isAdvancedDiagnosticsEnabled: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: advancedDiagnosticsEnabledKey) != nil else { return true }
        return defaults.bool(forKey: advancedDiagnosticsEnabledKey)
    }
}

enum LinkaAdvancedWiFiIntegration {
    static let shortcutName = "Linka Wi-Fi Advanced"
    static let shortcutsAppURL = URL(string: "https://linka.app/atalho")!
    static let runShortcutURL = URL(string: "shortcuts://run-shortcut?name=Linka%20Wi-Fi%20Advanced")!
}

enum LinkaAdvancedWiFiSettingsState: Equatable {
    case requiresPlus
    case needsConfiguration
    case active
    case disabled

    var statusText: String {
        switch self {
        case .requiresPlus: return "Linka Plus"
        case .needsConfiguration: return "Configurar"
        case .active: return "Ativo"
        case .disabled: return "Desativado"
        }
    }

    static func state(hasEntitlement: Bool, configured: Bool, enabled: Bool) -> LinkaAdvancedWiFiSettingsState {
        guard hasEntitlement else { return .requiresPlus }
        guard configured else { return .needsConfiguration }
        return enabled ? .active : .disabled
    }
}

enum LinkaAppearancePreference: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum LinkaAppVersion {
    static func displayString(infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]) -> String {
        let version = infoDictionary["CFBundleShortVersionString"] as? String
        let build = infoDictionary["CFBundleVersion"] as? String
        return "\(clean(version, fallback: "1.0.0")) (\(clean(build, fallback: "1")))"
    }

    private static func clean(_ value: String?, fallback: String) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return fallback }
        return value
    }
}

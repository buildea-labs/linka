import Foundation

/// Destinos públicos do Linka. A base é única para que Ajustes, paywall e
/// futuras superfícies legais não divirjam silenciosamente.
enum LinkaExternalLinks {
    static let website = URL(string: "https://linka-speedtest.web.app")!
    static let howWeMeasure = URL(string: "https://linka-speedtest.web.app/como-medimos")!
    static let privacy = URL(string: "https://linka-speedtest.web.app/privacidade")!
    static let terms = URL(string: "https://linka-speedtest.web.app/termos")!
    static let subscriptionManagement = URL(string: "https://apps.apple.com/account/subscriptions")!

    /// Só ganha valor quando houver um canal oficial do Linka verificado.
    static let support: URL? = nil
}

enum LinkaWiFiPreferences {
    static let identificationEnabledKey = "linka.wifi-identification.enabled.v1"
    static let advancedDiagnosticsEnabledKey = "linka.advanced-wifi.enabled.v1"

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

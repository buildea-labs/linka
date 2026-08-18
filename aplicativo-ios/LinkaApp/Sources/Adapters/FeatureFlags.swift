import Foundation

public enum FeatureFlags {
    // Assist is enabled but paid
    // The following features are built but hidden for the MVP
    
    public static var isCoverageMapEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isCoverageMapEnabled") // default is false
    }
    
    public static var isBackgroundAutomationEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isBackgroundAutomationEnabled") // default is false
    }
    
    public static var isAppIntentsEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isAppIntentsEnabled") // default is false
    }
    
    public static var isAdsEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isAdsEnabled") // default is false
    }
}

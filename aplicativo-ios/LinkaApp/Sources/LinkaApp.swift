import SwiftUI

@main
struct LinkaApp: App {
    @State private var showSplash = true
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    
    var colorScheme: ColorScheme? {
        if appAppearance == "light" { return .light }
        if appAppearance == "dark" { return .dark }
        return nil
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    })
                } else {
                    MainView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(colorScheme)
        }
    }
}

import SwiftUI

@main
struct LinkaApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                // Use dark appearance by default according to Design System
                .preferredColorScheme(.dark)
        }
    }
}

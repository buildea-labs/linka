import AppIntents

public struct LinkaAppShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSpeedTestIntent(),
            phrases: [
                "Analisar conexão com \(.applicationName)",
                "Testar internet com \(.applicationName)",
                "Testar Wi-Fi com \(.applicationName)",
                "Medir velocidade no \(.applicationName)"
            ],
            shortTitle: "Analisar conexão",
            systemImageName: "network"
        )
        
        AppShortcut(
            intent: GetLatestResultIntent(),
            phrases: [
                "Último resultado do \(.applicationName)",
                "Ver resultado do \(.applicationName)",
                "Qual foi a última medição no \(.applicationName)"
            ],
            shortTitle: "Último resultado",
            systemImageName: "clock"
        )
    }
}

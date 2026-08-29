import AppIntents
import LinkaAppIntents

/// Atalhos que o sistema registra para o Linka.
///
/// O provedor precisa pertencer ao alvo do aplicativo: assim o processador
/// de metadados do Xcode o inclui em `Metadata.appintents` e o app Atalhos o
/// descobre no dispositivo. Os intents continuam no pacote dedicado, que
/// preserva o contrato independente da interface SwiftUI.
struct LinkaAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSpeedTestIntent(),
            phrases: [
                "Testar internet com \(.applicationName)",
                "Medir minha conexão com \(.applicationName)"
            ],
            shortTitle: "Testar internet",
            systemImageName: "gauge.with.dots.needle.50percent"
        )
    }
}

import Foundation

/// Ponte observável entre a execução de `LinkaAppIntentExecutor`
/// (Siri/Shortcuts/Widget — issue #55) e `MainView`.
///
/// App Intents com `openAppWhenRun = true` rodam dentro do processo do
/// app quando o sistema abre o Linka para executá-los, mas não têm
/// acesso ao `@StateObject` de `SpeedTestViewModel` que vive em `MainView`
/// — `perform()` de um `AppIntent` não é uma `View` e não recebe
/// ambiente SwiftUI. Este coordinator existe só para atravessar essa
/// fronteira: o executor publica que uma ação foi pedida, `MainView`
/// observa e é quem decide traduzir isso para `viewModel.startTest()`.
///
/// Não mede nada, não decide nada sobre o motor — é só o mensageiro
/// (mesmo espírito do "adapter não acopla UI ao motor" de
/// `escreverAdaptadorNativo`).
@MainActor
public final class AppIntentCoordinator: ObservableObject {
    /// Singleton porque o `Handler` do `LinkaAppIntentExecutor` é
    /// registrado uma única vez, cedo, em `LinkaApp.init`/`.task`
    /// (`AppDependencyManager.shared.add`), fora da árvore de `View` —
    /// não há como injetar isto via `@EnvironmentObject` no ponto onde o
    /// executor é construído. `MainView` observa a mesma instância via
    /// `@ObservedObject`.
    public static let shared = AppIntentCoordinator()

    /// Alterna para `true` quando o widget/Siri/Shortcuts pede uma
    /// medição; `MainView` consome (`consumeStartSpeedTestRequest()`)
    /// depois de reagir, para não disparar `startTest()` de novo em toda
    /// recomposição de view.
    @Published public private(set) var pendingStartSpeedTest: Bool = false

    /// Alterna para `true` quando o widget/Siri/Shortcuts é acionado por
    /// usuário Free — `MainView` abre `PurchaseSheet` em vez de rodar
    /// medição. Decisão do Luiz (2026-08-15): Widget/Siri/App Intents são
    /// exclusivos do Linka Plus, incluindo o disparo de `startSpeedTest`
    /// por essas superfícies.
    @Published public private(set) var pendingPurchasePrompt: Bool = false

    private init() {}

    public func requestStartSpeedTest() {
        pendingStartSpeedTest = true
    }

    public func consumeStartSpeedTestRequest() {
        pendingStartSpeedTest = false
    }

    public func requestPurchasePrompt() {
        pendingPurchasePrompt = true
    }

    public func consumePurchasePrompt() {
        pendingPurchasePrompt = false
    }
}

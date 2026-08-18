import AppIntents
import Foundation

public struct LinkaAppIntentsPackage: AppIntentsPackage {}

public struct StartSpeedTestIntent: AppIntent {
    public static var title: LocalizedStringResource { "Testar internet" }
    public static let description = IntentDescription("Inicia uma medição de velocidade no Linka.")
    public static var openAppWhenRun: Bool { true }
    public static var isHidden: Bool { true }

    @Dependency
    private var executor: LinkaAppIntentExecutor

    public init() {}

    public func perform() async throws -> some IntentResult {
        _ = try await executor.execute(.startSpeedTest)
        return .result()
    }
}

public struct OpenLatestMeasurementIntent: AppIntent {
    public static var title: LocalizedStringResource { "Abrir última medição" }
    public static let description = IntentDescription("Abre a medição mais recente no Linka.")
    public static var openAppWhenRun: Bool { true }
    public static var isHidden: Bool { true }

    @Dependency
    private var executor: LinkaAppIntentExecutor

    public init() {}

    public func perform() async throws -> some IntentResult {
        _ = try await executor.execute(.openLatestMeasurement)
        return .result()
    }
}

public struct OpenHistoryIntent: AppIntent {
    public static var title: LocalizedStringResource { "Abrir histórico" }
    public static let description = IntentDescription("Abre o histórico de medições do Linka.")
    public static var openAppWhenRun: Bool { true }
    public static var isHidden: Bool { true }

    @Dependency
    private var executor: LinkaAppIntentExecutor

    public init() {}

    public func perform() async throws -> some IntentResult {
        _ = try await executor.execute(.openHistory)
        return .result()
    }
}

public struct GetLatestResultIntent: AppIntent {
    public static var title: LocalizedStringResource { "Último resultado" }
    public static let description = IntentDescription("Retorna o resumo da medição mais recente do Linka.")
    public static var openAppWhenRun: Bool { false }
    public static var isHidden: Bool { true }

    @Dependency
    private var executor: LinkaAppIntentExecutor

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard UserDefaults.standard.bool(forKey: "isAppIntentsEnabled") else {
            return .result(value: "Esta funcionalidade ainda não está disponível.")
        }
        let response = try await executor.execute(.getLatestResult)
        guard let value = response.value else {
            throw LinkaAppIntentExecutionError.missingValue(action: .getLatestResult)
        }
        return .result(value: value)
    }
}

/*
public struct LinkaAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSpeedTestIntent(),
            phrases: [
                "Testar internet com \(.applicationName)",
                "Medir minha conexão com \(.applicationName)"
            ],
            shortTitle: "Testar internet",
            systemImageName: "gauge.with.dots.needle.50percent"
        )

        AppShortcut(
            intent: GetLatestResultIntent(),
            phrases: [
                "Último teste no \(.applicationName)",
                "Ver último resultado no \(.applicationName)"
            ],
            shortTitle: "Último resultado",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: MeasureNetworkSilentlyIntent(),
            phrases: [
                "Testar silenciosamente com \(.applicationName)",
                "Medir rede silenciosamente no \(.applicationName)"
            ],
            shortTitle: "Testar silenciosamente",
            systemImageName: "network"
        )
    }
}
*/

public struct MeasureNetworkSilentlyIntent: AppIntent {
    public static var title: LocalizedStringResource { "Testar silenciosamente" }
    public static let description = IntentDescription("Mede a rede silenciosamente sem abrir o app.")
    public static var openAppWhenRun: Bool { false }
    public static var isHidden: Bool { true }

    @Dependency
    private var executor: LinkaAppIntentExecutor

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard UserDefaults.standard.bool(forKey: "isAppIntentsEnabled") else {
            return .result(value: "Esta funcionalidade ainda não está disponível.")
        }
        let response = try await executor.execute(.measureNetworkSilently)
        guard let value = response.value else {
            throw LinkaAppIntentExecutionError.missingValue(action: .measureNetworkSilently)
        }
        return .result(value: value)
    }
}

import Foundation
import NetworkCore
import NetworkAssist
import LinkaModules
import LinkaEntitlements
import MeasurementHistory

/// Adapta `LinkaModules.NetworkStabilityPatternAnalyzing` (issue #125) para a
/// `AssistView`. Cálculo local e determinístico sobre o histórico do
/// aparelho — não depende do estado da chamada remota ao NDS (`AssistViewModel`),
/// por isso vive num `ObservableObject` próprio em vez de ser mais um campo
/// do `AssistViewModel.DiagnosticData`.
@MainActor
final class NetworkStabilityPatternsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        /// Frases factuais já prontas para exibição (issue #125, item 3).
        case detected([String])
        /// Histórico suficiente para todo grupo/métrica avaliado, mas nenhum
        /// concentrou piora recorrente num horário — distinto de
        /// `insufficientHistory` de propósito, para nunca soar como "ainda
        /// não sabemos" quando na verdade já sabemos que está estável.
        case noPatternDetected
        case insufficientHistory
        /// Sem entitlement, sem histórico algum ou falha ao consultar —
        /// a seção nem aparece nesse estado (ver `AssistView`), então não
        /// precisa de mensagem própria.
        case unavailable
    }

    @Published private(set) var state: State = .loading

    private let entitlements: StoreKitEntitlementProvider?
    private let historyLookbackDays: Int

    init(
        entitlements: StoreKitEntitlementProvider?,
        historyLookbackDays: Int = 90
    ) {
        self.entitlements = entitlements
        self.historyLookbackDays = historyLookbackDays
    }

    func load() async {
        guard case .loading = state else { return }

        guard let entitlements else {
            state = .unavailable
            return
        }

        let repository = LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
        let from = Calendar.current.date(byAdding: .day, value: -historyLookbackDays, to: Date())
        let query = MeasurementQuery(measuredFrom: from, sortOrder: .newestFirst)

        guard let measurements = try? await repository.measurements(matching: query),
              !measurements.isEmpty else {
            state = .unavailable
            return
        }

        let analyzer = EntitlementGatedNetworkStabilityPatternAnalyzer(
            wrapping: BasicNetworkStabilityPatternAnalyzer(),
            snapshot: entitlements.snapshot
        )

        guard let reports = try? analyzer.analyze(measurements) else {
            // `notEntitled` (Free) ou medição inválida — a `AssistView` já é
            // uma superfície Plus-only, então isso só aconteceria por uma
            // inconsistência de estado; tratar como "sem seção" é honesto e
            // não bloqueia o resto do Assist.
            state = .unavailable
            return
        }

        let narratives = reports.flatMap { $0.metricNarratives.map(\.narrative) }

        let sentences = narratives.compactMap { narrative -> String? in
            if case .factual(let text) = narrative { return text }
            return nil
        }

        guard sentences.isEmpty else {
            state = .detected(sentences)
            return
        }

        // Nenhuma frase: decide entre "sem padrão" (já avaliamos, está
        // estável) e "dado insuficiente" (ainda não dá para avaliar) olhando
        // se ao menos uma métrica de algum grupo já foi de fato avaliada.
        let hasAnyEvaluatedMetric = narratives.contains {
            if case .noPatternDetected = $0 { return true }
            return false
        }

        state = hasAnyEvaluatedMetric ? .noPatternDetected : .insufficientHistory
    }
}

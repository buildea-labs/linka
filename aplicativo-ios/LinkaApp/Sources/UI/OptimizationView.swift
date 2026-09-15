import SwiftUI
import NetworkCore
import NetworkOptimization

/// Superfície secundária: a medição continua protagonista e a Otimização só
/// traduz fatos já medidos em uma próxima ação explícita da pessoa.
struct OptimizationView: View {
    let baseline: NetworkMeasurement
    let history: [NetworkMeasurement]
    let isPlusActive: Bool
    let onRequestPurchase: () -> Void
    let onRetest: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var plan: OptimizationPlan {
        OptimizationPlanBuilder().build(baseline: baseline, history: history)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(LinkaCopy.value("optimization.intro"))
                        .foregroundStyle(.secondary)
                }

                if plan.opportunities.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text(LinkaCopy.value("optimization.none.title"))
                                .font(.body.weight(.semibold))
                            Text(LinkaCopy.value("optimization.none.message"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section(LinkaCopy.value("optimization.opportunities")) {
                        ForEach(plan.opportunities) { opportunity in
                            opportunityRow(opportunity)
                        }
                    }
                }

                Section {
                    if isPlusActive {
                        Button(LinkaCopy.value("optimization.retest")) {
                            dismiss()
                            onRetest()
                        }
                    } else {
                        Button(LinkaCopy.value("optimization.preview.cta"), action: onRequestPurchase)
                    }
                } footer: {
                    Text(isPlusActive
                         ? LinkaCopy.value("optimization.retest.hint")
                         : LinkaCopy.value("optimization.preview.hint"))
                }
            }
            .navigationTitle(LinkaCopy.value("optimization.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LinkaCopy.value("common.close")) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func opportunityRow(_ opportunity: OptimizationOpportunity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title(for: opportunity.kind), systemImage: icon(for: opportunity.kind))
                .font(.body.weight(.semibold))
            Text(detail(for: opportunity.kind))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(action(for: opportunity.action))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func title(for kind: OptimizationOpportunityKind) -> String {
        switch kind {
        case .responsivenessUnderLoad: LinkaCopy.value("optimization.load.title")
        case .unstableConnection: LinkaCopy.value("optimization.stability.title")
        case .belowUsualQuality: LinkaCopy.value("optimization.history.title")
        }
    }

    private func detail(for kind: OptimizationOpportunityKind) -> String {
        switch kind {
        case .responsivenessUnderLoad: LinkaCopy.value("optimization.load.message")
        case .unstableConnection: LinkaCopy.value("optimization.stability.message")
        case .belowUsualQuality: LinkaCopy.value("optimization.history.message")
        }
    }

    private func action(for action: OptimizationGuidedAction) -> String {
        switch action {
        case .reduceConcurrentUse: LinkaCopy.value("optimization.action.concurrent")
        case .moveCloserToRouter: LinkaCopy.value("optimization.action.proximity")
        case .restartRouter: LinkaCopy.value("optimization.action.restart")
        }
    }

    private func icon(for kind: OptimizationOpportunityKind) -> String {
        switch kind {
        case .responsivenessUnderLoad: "arrow.triangle.2.circlepath"
        case .unstableConnection: "wifi.exclamationmark"
        case .belowUsualQuality: "clock.arrow.circlepath"
        }
    }
}

struct OptimizationRetestResultView: View {
    let result: OptimizationRetestComparison
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: symbol).font(.largeTitle).foregroundStyle(.tint)
                Text(title).font(.title3.weight(.semibold))
                Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)
            }.padding(32).navigationTitle(LinkaCopy.value("optimization.title"))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(LinkaCopy.value("common.close")) { dismiss() } } }
        }
    }
    private var symbol: String { if case .improved = result { return "checkmark.circle" }; return "equal.circle" }
    private var title: String { if case .improved = result { return LinkaCopy.value("optimization.result.improved.title") }; if case .noSignificantGain = result { return LinkaCopy.value("optimization.result.stable.title") }; return LinkaCopy.value("optimization.result.incomparable.title") }
    private var message: String { if case .improved = result { return LinkaCopy.value("optimization.result.improved.message") }; if case .noSignificantGain = result { return LinkaCopy.value("optimization.result.stable.message") }; return LinkaCopy.value("optimization.result.incomparable.message") }
}

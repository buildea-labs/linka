import SwiftUI
import NetworkCore
import NetworkInsights

/// Tela de Diagnóstico de Adequação por Uso.
/// Apresenta a qualidade da rede para cada caso de uso em uma List nativa.
struct UsageDiagnosticsView: View {
    let measurement: NetworkMeasurement?
    @Environment(\.dismiss) private var dismiss

    private var report: UsageSuitabilityReport? {
        guard let measurement else { return nil }
        return UsageSuitabilityEvaluator().evaluate(measurement)
    }

    private var summarySubtitle: String {
        guard let report else { return "Faça uma medição para avaliar o uso." }
        let quality = UsageSuitabilityCopy.qualityLevel(for: report)
        switch quality {
        case .good:
            return "Sua conexão está boa para a maioria dos usos."
        case .medium:
            return "Sua conexão é suficiente para usos básicos, mas pode oscilar sob demanda."
        case .poor:
            return "Sua conexão apresenta limitações perceptíveis para usos exigentes."
        case nil:
            return "Avaliação dos principais casos de uso da sua rede."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            contextualHeader
            List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resumo")
                        .font(.captionSmallStrong)
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)

                    Text(summarySubtitle)
                        .font(.bodyRegularStrong)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            if let report {
                Section("Casos de uso") {
                    ForEach(UsageCase.allCases, id: \.self) { usageCase in
                        if let verdict = report.verdict(for: usageCase) {
                            UsageVerdictRow(usageCase: usageCase, verdict: verdict)
                        }
                    }
                }
            } else {
                Section {
                    Text("Nenhuma medição disponível.")
                        .foregroundColor(.textSecondary)
                }
            }
            }
        }
    }

    private var contextualHeader: some View {
        HStack {
            Button("Fechar") { dismiss() }
                .font(.bodySmallStrong)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .accessibilityLabel("Fechar qualidade de uso")
            Spacer()
            Text("Qualidade de uso").font(.headline)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }
}

private struct UsageVerdictRow: View {
    let usageCase: UsageCase
    let verdict: UsageCaseVerdict

    private var badgeColor: Color {
        switch verdict.level {
        case .adequate: return .statusGood
        case .limited: return .statusAttention
        case .notAssessed: return .textSecondary
        }
    }

    private var statusIcon: String {
        switch verdict.level {
        case .adequate: return "checkmark.circle.fill"
        case .limited: return "exclamationmark.triangle.fill"
        case .notAssessed: return "questionmark.circle.fill"
        }
    }

    private var badgeLabel: String {
        switch verdict.level {
        case .adequate: return "Adequada"
        case .limited: return "Limitada"
        case .notAssessed: return "Não avaliada"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(UsageSuitabilityCopy.title(for: usageCase))
                    .font(.bodyRegularStrong)
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Text(badgeLabel)
                        .font(.bodySmallStrong)
                        .foregroundColor(badgeColor)

                    Image(systemName: statusIcon)
                        .font(.captionSmallStrong)
                        .foregroundColor(badgeColor)
                }
            }

            let detail = UsageSuitabilityCopy.detail(for: verdict)
            if !detail.isEmpty {
                Text(detail)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UsageSuitabilityCopy.title(for: usageCase)): \(badgeLabel). \(UsageSuitabilityCopy.detail(for: verdict))")
    }
}

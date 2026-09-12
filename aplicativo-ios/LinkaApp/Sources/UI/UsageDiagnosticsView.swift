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
        guard let report else { return LinkaCopy.value("usage.summary.noMeasurement") }
        let quality = UsageSuitabilityCopy.qualityLevel(for: report)
        switch quality {
        case .good:
            return LinkaCopy.value("usage.summary.good")
        case .medium:
            return LinkaCopy.value("usage.summary.medium")
        case .poor:
            return LinkaCopy.value("usage.summary.poor")
        case nil:
            return LinkaCopy.value("usage.summary.default")
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("usage.summary.title")
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
                    Section("usage.cases") {
                        ForEach(UsageCase.allCases, id: \.self) { usageCase in
                            if let verdict = report.verdict(for: usageCase) {
                                UsageVerdictRow(usageCase: usageCase, verdict: verdict)
                            }
                        }
                    }
                } else {
                    Section {
                        LinkaUnavailableState(
                            title: "usage.noMeasurement.title",
                            message: "usage.noMeasurement.message",
                            systemImage: "speedometer"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .linkaSheetToolbar(title: LinkaCopy.value("usage.title")) { dismiss() }
        }
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
        case .adequate: return LinkaCopy.value("usage.status.adequate")
        case .limited: return LinkaCopy.value("usage.status.limited")
        case .notAssessed: return LinkaCopy.value("usage.status.notAssessed")
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

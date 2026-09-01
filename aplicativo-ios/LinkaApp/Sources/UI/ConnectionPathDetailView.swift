import SwiftUI
import NetworkInsights

/// Tela dedicada do Caminho da Conexão.
/// Apresenta o diagnóstico de cada uma das 5 etapas da rede em formato de lista nativa.
struct ConnectionPathDetailView: View {
    let report: ConnectionPathReport
    @Environment(\.dismiss) private var dismiss

    private var visibleStages: [ConnectionPathStage] {
        report.stages.map { $0.stage }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diagnóstico da rota")
                            .font(.captionSmallStrong)
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)

                        Text(ConnectionPathCopy.conclusion(for: report))
                            .font(.bodyRegularStrong)
                            .foregroundColor(.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }

                Section("Etapas da conexão") {
                    ForEach(visibleStages, id: \.self) { stage in
                        if let verdict = report.verdict(for: stage) {
                            stageRow(verdict: verdict, isHighlighted: report.highlightedStage == stage)
                        }
                    }
                }
            }
            .linkaSheetToolbar(title: "Caminho da conexão") { dismiss() }
        }
    }

    @ViewBuilder
    private func stageRow(verdict: ConnectionPathStageVerdict, isHighlighted: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: ConnectionPathCopy.icon(for: verdict.stage))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isHighlighted ? statusColor(verdict.status) : .textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(statusColor(verdict.status).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(ConnectionPathCopy.title(for: verdict.stage))
                        .font(.bodyRegularStrong)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Image(systemName: ConnectionPathCopy.statusSymbol(for: verdict.status))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(statusColor(verdict.status))
                }

                Text(ConnectionPathCopy.explanation(for: verdict))
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ConnectionPathCopy.title(for: verdict.stage)): \(ConnectionPathCopy.statusAccessibilityLabel(verdict.status)). \(ConnectionPathCopy.explanation(for: verdict))")
    }

    private func statusColor(_ status: ConnectionPathStageStatus) -> Color {
        switch status {
        case .normal: return .statusGood
        case .attention: return .statusAttention
        case .likelyProblem: return .statusCritical
        case .unavailable: return .textSecondary
        }
    }
}

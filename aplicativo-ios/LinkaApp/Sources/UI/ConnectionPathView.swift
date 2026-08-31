import SwiftUI
import NetworkInsights

/// Caminho da Conexão — leitura visual simplificada de "onde provavelmente
/// está o problema", entre o diagnóstico curto e as ações de navegação.
///
/// Mostra a sequência de 5 etapas com glifos discretos:
/// iPhone → Wi-Fi → Roteador → Operadora → Internet
/// Ao tocar, navega diretamente para `ConnectionPathDetailView`.
struct ConnectionPathView: View {
    let report: ConnectionPathReport

    private var visibleStages: [ConnectionPathStage] {
        report.stages.map { $0.stage }
    }

    var body: some View {
        NavigationLink(destination: ConnectionPathDetailView(report: report)) {
            HStack(spacing: 0) {
                ForEach(Array(visibleStages.enumerated()), id: \.element) { index, stage in
                    if let verdict = report.verdict(for: stage) {
                        stageGlyph(verdict, highlighted: report.highlightedStage == stage)
                        if index < visibleStages.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textSecondary.opacity(0.35))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ConnectionPathCopy.accessibilitySummary(for: report))
        .accessibilityHint("Toque para ver o caminho da conexão em detalhes")
    }

    @ViewBuilder
    private func stageGlyph(_ verdict: ConnectionPathStageVerdict, highlighted: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: ConnectionPathCopy.icon(for: verdict.stage))
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(highlighted ? statusColor(verdict.status) : .textSecondary)

            Image(systemName: ConnectionPathCopy.statusSymbol(for: verdict.status))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(statusColor(verdict.status))
                .background(Circle().fill(Color.surfacePage).frame(width: 11, height: 11))
                .offset(x: 5, y: 4)
        }
        .frame(width: 26, height: 26)
        .frame(maxWidth: .infinity)
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

/// Copy do Caminho da Conexão — vive só na UI.
enum ConnectionPathCopy {
    static let orderedStages: [ConnectionPathStage] = [.device, .wifi, .router, .carrier, .internet]

    static func title(for stage: ConnectionPathStage) -> String {
        switch stage {
        case .device: return "iPhone"
        case .wifi: return "Wi-Fi"
        case .router: return "Roteador"
        case .carrier: return "Operadora"
        case .internet: return "Internet"
        }
    }

    static func icon(for stage: ConnectionPathStage) -> String {
        switch stage {
        case .device: return "iphone"
        case .wifi: return "wifi"
        case .router: return "wifi.router"
        case .carrier: return "antenna.radiowaves.left.and.right"
        case .internet: return "globe"
        }
    }

    static func statusSymbol(for status: ConnectionPathStageStatus) -> String {
        switch status {
        case .normal: return "checkmark.circle.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .likelyProblem: return "xmark.circle.fill"
        case .unavailable: return "questionmark.circle.fill"
        }
    }

    static func statusAccessibilityLabel(_ status: ConnectionPathStageStatus) -> String {
        switch status {
        case .normal: return "normal"
        case .attention: return "atenção"
        case .likelyProblem: return "problema provável"
        case .unavailable: return "não verificado"
        }
    }

    private static let explanations: [ConnectionPathStage: [ConnectionPathStageStatus: String]] = [
        .device: [
            .normal: "Seu aparelho está conectado normalmente."
        ],
        .wifi: [
            .normal: "Sinal bom e conexão estável.",
            .attention: "O sinal do Wi-Fi está fraco neste local.",
            .likelyProblem: "O sinal do Wi-Fi está muito fraco — isso costuma explicar lentidão e travamentos.",
            .unavailable: "Não foi possível verificar esta etapa."
        ],
        .router: [
            .normal: "A resposta do roteador está normal.",
            .attention: "A resposta do roteador está um pouco mais lenta que o esperado.",
            .likelyProblem: "A resposta do roteador está bem mais lenta que o esperado.",
            .unavailable: "Não foi possível verificar esta etapa."
        ],
        .carrier: [
            .normal: "A rede da operadora respondeu normalmente.",
            .attention: "A rede da operadora está com resposta um pouco mais lenta que o esperado.",
            .likelyProblem: "A rede da operadora está com resposta bem mais lenta ou perdendo dados.",
            .unavailable: "Não foi possível verificar esta etapa."
        ],
        .internet: [
            .normal: "Os serviços externos estão acessíveis.",
            .attention: "O acesso a serviços externos está mais lento que o esperado.",
            .likelyProblem: "O acesso a serviços externos está bem mais lento que o esperado.",
            .unavailable: "Não foi possível verificar esta etapa."
        ]
    ]

    static func explanation(for verdict: ConnectionPathStageVerdict) -> String {
        explanations[verdict.stage]?[verdict.status]
            ?? explanations[verdict.stage]?[.unavailable]
            ?? "Não foi possível verificar esta etapa."
    }

    /// Diagnóstico curto para a tela principal (Apple-style)
    static func shortConclusion(for report: ConnectionPathReport) -> String {
        switch report.category {
        case .healthy:
            return "Tudo parece normal"
        case .inconclusive:
            return "Sinais de instabilidade"
        case .local:
            return "Possível problema no aparelho"
        case .wifi:
            return "Possível problema no Wi-Fi"
        case .carrier:
            return "Possível problema na operadora"
        case .external:
            return "Possível instabilidade na internet"
        }
    }

    /// Frase detalhada de conclusão (usada em telas de detalhe e acessibilidade)
    static func conclusion(for report: ConnectionPathReport) -> String {
        switch report.category {
        case .healthy:
            return "Tudo parece normal."
        case .inconclusive:
            return "Encontramos sinais de instabilidade, mas não foi possível identificar uma única causa."
        case .local:
            return "O possível problema está no seu aparelho."
        case .wifi:
            if report.highlightedStage == .router {
                return "O problema provavelmente está entre o Wi-Fi e o roteador."
            }
            return "O possível problema está no seu Wi-Fi."
        case .carrier:
            return "O problema parece acontecer depois que a conexão sai da sua casa."
        case .external:
            return "A conexão e a operadora parecem normais — o problema parece estar em um serviço externo."
        }
    }

    static func accessibilitySummary(for report: ConnectionPathReport) -> String {
        let visibleStages = report.stages.map { $0.stage }
        let stagesText = visibleStages.compactMap { stage -> String? in
            guard let verdict = report.verdict(for: stage) else { return nil }
            return "\(title(for: stage)): \(statusAccessibilityLabel(verdict.status))"
        }.joined(separator: ". ")
        return "Caminho da conexão. \(stagesText). \(conclusion(for: report))"
    }
}

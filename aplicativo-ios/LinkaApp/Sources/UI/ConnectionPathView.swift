import SwiftUI
import NetworkInsights

/// Caminho da Conexão — leitura visual simplificada de "onde provavelmente
/// está o problema", entre as métricas principais e "Ver detalhes da
/// medição" (issue Caminho da Conexão, 2026-08-29). Não é traceroute nem
/// mapa técnico: é a interpretação de `ConnectionPathReport`
/// (`NetworkInsights`, classificador puro) em cinco etapas didáticas.
///
/// Deliberadamente quase sem card: fundo da página, divisores sutis,
/// tipografia do sistema, espaço generoso — parte natural da tela de
/// resultado, não um dashboard. Disponível no Linka gratuito (issue #57 já
/// estabeleceu esse padrão para diagnóstico básico de uso).
///
/// Issue "Hero do resultado" (2026-08-29): a conclusão ("Tudo parece
/// normal.", etc.) saiu daqui — ela agora abre a tela de resultado, antes
/// do número de download. Repeti-la debaixo do caminho seria redundante;
/// este componente vira só a representação visual das etapas.
struct ConnectionPathView: View {
    let report: ConnectionPathReport
    @Binding var expanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(reduceMotion ? nil : LinkaMotion.spring) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    ForEach(Array(ConnectionPathCopy.orderedStages.enumerated()), id: \.element) { index, stage in
                        if let verdict = report.verdict(for: stage) {
                            stageGlyph(verdict, highlighted: report.highlightedStage == stage)
                            if index < ConnectionPathCopy.orderedStages.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.captionSmall)
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ConnectionPathCopy.accessibilitySummary(for: report))
            .accessibilityHint(expanded ? "Toque para recolher" : "Toque para expandir")

            if expanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(ConnectionPathCopy.orderedStages.enumerated()), id: \.element) { index, stage in
                        if let verdict = report.verdict(for: stage) {
                            stageDetailRow(verdict, highlighted: report.highlightedStage == stage)
                            if index < ConnectionPathCopy.orderedStages.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func stageGlyph(_ verdict: ConnectionPathStageVerdict, highlighted: Bool) -> some View {
        // Ícones maiores sem crescer a altura do bloco (issue "ajuste fino
        // do hero", 2026-08-29) — a `.frame(width:height:)` fixa abaixo
        // fixa a caixa do glifo em 32pt independente do tamanho de fonte
        // escolhido, então aumentar o símbolo não empurra o resto da tela.
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: ConnectionPathCopy.icon(for: verdict.stage))
                .font(.system(size: highlighted ? 24 : 21, weight: .medium))
                .foregroundColor(highlighted ? statusColor(verdict.status) : .textSecondary)
            Image(systemName: ConnectionPathCopy.statusSymbol(for: verdict.status))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(statusColor(verdict.status))
                .background(Circle().fill(Color.surfacePage).frame(width: 14, height: 14))
                .offset(x: 7, y: 5)
        }
        .frame(width: 32, height: 32)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func stageDetailRow(_ verdict: ConnectionPathStageVerdict, highlighted: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ConnectionPathCopy.icon(for: verdict.stage))
                .font(.bodyRegular)
                .foregroundColor(highlighted ? statusColor(verdict.status) : .textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(ConnectionPathCopy.title(for: verdict.stage))
                    .font(.bodySmallStrong)
                    .foregroundColor(.textPrimary)
                Text(ConnectionPathCopy.explanation(for: verdict))
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ConnectionPathCopy.title(for: verdict.stage)): \(ConnectionPathCopy.explanation(for: verdict))")
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

/// Copy do Caminho da Conexão — vive só na UI, mesmo padrão de
/// `UsageSuitabilityCopy`: o pacote de classificação (`NetworkInsights`)
/// não conhece texto nem marca. Nunca usa termos técnicos (hops, TTL,
/// traceroute, ASN, gateway latency) na camada principal — só na etapa
/// expandida, e mesmo assim em linguagem comum.
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

    /// Frase única de conclusão (mais importante que os dados técnicos) —
    /// usa níveis de confiança ("parece", "há sinais de") em vez de
    /// afirmação categórica, exceto quando a medição sustenta certeza
    /// razoável (uma única etapa problemática clara).
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
        let stagesText = orderedStages.compactMap { stage -> String? in
            guard let verdict = report.verdict(for: stage) else { return nil }
            return "\(title(for: stage)): \(statusAccessibilityLabel(verdict.status))"
        }.joined(separator: ". ")
        return "Caminho da conexão. \(stagesText). \(conclusion(for: report))"
    }
}

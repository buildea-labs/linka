import SwiftUI
import NetworkCore
import NetworkInsights

/// Diagnóstico de adequação completo — um veredito por `UsageCase`, em vez
/// da frase única de "para que serve" já mostrada em `DetailsDisclosure`
/// (issue Expert Mode). Tela própria (não espremida em "Ver detalhes") para
/// não virar painel: só existe atrás de um botão dedicado, nunca no
/// primeiro frame do resultado (AGENTS.md §6/§9).
struct UsageDiagnosticsView: View {
    @Environment(\.dismiss) var dismiss

    /// Medição atual, já com os fatos que o motor mediu. `nil` quando não
    /// há teste concluído — a tela mostra um estado vazio em vez de
    /// inventar veredictos.
    let measurement: NetworkMeasurement?

    private var report: UsageSuitabilityReport? {
        guard let measurement else { return nil }
        return UsageSuitabilityEvaluator().evaluate(measurement)
    }

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodySmallStrong)
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.textSecondary.opacity(0.14))
                            .clipShape(Circle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Fechar")
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)

                if let report {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Qualidade para o meu uso")
                                .font(.displayMedium)
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(UsageCase.allCases, id: \.self) { usageCase in
                                    if let verdict = report.verdict(for: usageCase) {
                                        UsageVerdictRow(usageCase: usageCase, verdict: verdict)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                } else {
                    Spacer()
                    Text("Faça um teste para ver o diagnóstico de uso.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            }
        }
    }
}

private struct UsageVerdictRow: View {
    let usageCase: UsageCase
    let verdict: UsageCaseVerdict

    private var badgeColor: Color {
        switch verdict.level {
        case .adequate: return .brandAccentWarm
        case .limited: return .textSecondary
        case .notAssessed: return .textSecondary.opacity(0.6)
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
                    .font(.bodySmallStrong)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(badgeLabel)
                    .font(.captionStrong)
                    .foregroundColor(badgeColor)
            }
            Text(UsageSuitabilityCopy.detail(for: verdict))
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UsageSuitabilityCopy.title(for: usageCase)): \(badgeLabel). \(UsageSuitabilityCopy.detail(for: verdict))")
    }
}

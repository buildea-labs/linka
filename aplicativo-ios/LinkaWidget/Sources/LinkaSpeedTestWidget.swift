import WidgetKit
import SwiftUI
import AppIntents
import LinkaAppIntents
import LinkaWidgetShared

/// Widget de Home Screen do Linka (issue #55) — um botão "Testar" e,
/// quando o tamanho permitir, o último resultado. Nada além disso: sem
/// histórico navegável, sem métricas extra (ver não-objetivo do
/// `plano.md` da issue #55 e AGENTS.md §1 sobre curadoria de
/// minimalismo).
///
/// `StartSpeedTestIntent` já existe em `LinkaAppIntents` e é reaproveitado
/// aqui, não duplicado — o botão só descreve a intent; quem executa é o
/// `LinkaAppIntentExecutor` real registrado por `LinkaApp` (issue #55,
/// ver `LinkaApp.swift`). Nenhuma medição roda dentro deste processo de
/// extensão.
struct LinkaSpeedTestWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LinkaWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
        .containerBackground(Color.surfacePage, for: .widget)
    }

    private var smallBody: some View {
        VStack(spacing: 12) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.textPrimary)

            testButton(label: "Testar")
        }
        .padding()
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            resultSummary
                .frame(maxWidth: .infinity, alignment: .leading)

            testButton(label: "Testar", compact: true)
        }
        .padding()
    }

    @ViewBuilder
    private func testButton(label: String, compact: Bool = false) -> some View {
        Button(intent: StartSpeedTestIntent()) {
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: compact ? nil : .infinity)
                .padding(.horizontal, compact ? 18 : 0)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.brandSurface)
    }

    @ViewBuilder
    private var resultSummary: some View {
        if let summary = entry.summary {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedMbps(summary.downloadMbps))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text("Mbps · download")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
                Text(relativeLabel(for: summary.measuredAt))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
            }
        } else {
            // Estado próprio para "sem medição anterior" (requisito de
            // aceite da issue #55) — nunca widget vazio/quebrado.
            VStack(alignment: .leading, spacing: 4) {
                Text("Sem medição ainda")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("Toque em Testar para medir")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func formattedMbps(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private func relativeLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Hoje"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

struct LinkaSpeedTestWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: LinkaWidgetShared.widgetKind,
            provider: LinkaWidgetTimelineProvider()
        ) { entry in
            LinkaSpeedTestWidgetView(entry: entry)
        }
        .configurationDisplayName("Linka SpeedTest")
        .description("Testar velocidade e ver o último resultado.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

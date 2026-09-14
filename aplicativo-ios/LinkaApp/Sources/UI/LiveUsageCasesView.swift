import SwiftUI
import NetworkCore
import NetworkInsights

/// Componente visual para exibição dos casos de uso calculados ao vivo (tempo real).
///
/// Projetado para a tela Início (Idle) do iOS e painel lateral do macOS,
/// oferecendo leitura imediata sem competir visualmente com o CTA primário de teste.
struct LiveUsageCasesView: View {
    let report: LiveUsageSuitabilityReport?
    var cases: [UsageCase] = [.videoCall, .onlineGaming]
    var isEmbedded: Bool = false
    var onSelect: ((UsageCase) -> Void)? = nil

    var body: some View {
        let content = HStack(spacing: 12) {
            ForEach(cases, id: \.self) { usageCase in
                node(for: usageCase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)

        if isEmbedded {
            content
        } else {
            content
                .linkaCard(cornerRadius: LinkaRadius.lg)
        }
    }

    @ViewBuilder
    private func node(for usageCase: UsageCase) -> some View {
        let verdict = report?.verdict(for: usageCase)
        let isActionable = verdict?.reason == .missingThroughputMeasurement && onSelect != nil
        let badge: (label: String, color: Color, icon: String) = {
            if let verdict {
                return UsageSuitabilityCopy.liveStatusBadge(for: verdict)
            } else {
                return (LinkaCopy.value("usage.live.measuring"), .textSecondary, "ellipsis")
            }
        }()

        let content = VStack(spacing: 6) {
            Image(systemName: UsageSuitabilityCopy.iconName(for: usageCase))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(width: 38, height: 38)
                .background(Color.surfacePage, in: Circle())

            Text(UsageSuitabilityCopy.title(for: usageCase))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            LinkaStatusBadge(badge.label, color: badge.color)

            if let verdict, verdict.confidence == .historicalBaselineInferred {
                Text(UsageSuitabilityCopy.liveDetail(for: verdict))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)

        if isActionable {
            Button { onSelect?(usageCase) } label: { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(UsageSuitabilityCopy.title(for: usageCase)): \(badge.label)")
                .accessibilityHint(verdict.map { UsageSuitabilityCopy.liveDetail(for: $0) } ?? "")
        } else {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(UsageSuitabilityCopy.title(for: usageCase)): \(badge.label)")
                .accessibilityHint(verdict.map { UsageSuitabilityCopy.liveDetail(for: $0) } ?? "")
        }
    }
}

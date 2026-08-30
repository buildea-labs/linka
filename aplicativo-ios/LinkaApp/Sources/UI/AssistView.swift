import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkAssist
import LinkaEntitlements
import LinkaModules

struct AssistView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: AssistViewModel
    @StateObject private var stabilityViewModel: NetworkStabilityPatternsViewModel
    @State private var showRecommendationDetails = false

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]
    let usageContext: String?
    let failureSignal: NetworkAssistFailureSignal?
    let onRetry: (() -> Void)?
    /// Ação real de "Ver detalhes da medição" (issue UI Polish v2) — antes
    /// esse botão só chamava `dismiss()`, sem navegar a lugar nenhum
    /// (visualmente parecia ir a algum lugar, na prática só voltava).
    /// Quando fornecido (hoje só por `MainView`, que tem um estado
    /// `detailsOpen` para expandir), o botão abre os detalhes de verdade
    /// antes de fechar este sheet. `nil` quando não existe um destino de
    /// detalhes no contexto do chamador (ex.: `HistoryView`, que empurra
    /// esta view numa `NavigationStack` sem resultado "vivo" para expandir)
    /// — nesse caso o botão vira "Voltar", copy honesta para o que
    /// `dismiss()` realmente faz.
    let onShowDetails: (() -> Void)?
    let entitlements: StoreKitEntitlementProvider?
    /// Macro-grupo e subcategoria coletados por `AssistProblemSelectionView`
    /// antes de abrir esta tela, quando o usuário passou pela seleção
    /// guiada. `nil`/`nil` no fluxo observacional puro (comportamento de
    /// hoje, sem mudança).
    let objective: String?
    let subcategory: String?
    /// Texto livre de "Outro problema" (ver `AssistProblemSelectionView`),
    /// quando o usuário optou por descrever em vez de escolher um
    /// `objective` fechado. Mutuamente exclusivo com `objective`/
    /// `subcategory` na prática — o fluxo guiado nunca preenche os dois.
    let reportedProblem: String?

    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        usageContext: String? = nil,
        failureSignal: NetworkAssistFailureSignal? = nil,
        objective: String? = nil,
        subcategory: String? = nil,
        reportedProblem: String? = nil,
        onRetry: (() -> Void)? = nil,
        onShowDetails: (() -> Void)? = nil,
        entitlements: StoreKitEntitlementProvider? = nil,
        assistProvider: (any NetworkAssistProviding)? = nil,
        assistIsRemote: Bool = AssistContainer.isRemoteAssistEnabled()
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.usageContext = usageContext
        self.failureSignal = failureSignal
        self.objective = objective
        self.subcategory = subcategory
        self.reportedProblem = reportedProblem
        self.onRetry = onRetry
        self.onShowDetails = onShowDetails
        self.entitlements = entitlements

        let resolvedProvider: any NetworkAssistProviding
        if let assistProvider {
            resolvedProvider = assistProvider
        } else if let entitlements {
            resolvedProvider = AssistContainer.makeAssistProvider(entitlements: entitlements)
        } else {
            resolvedProvider = NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }

        self._viewModel = StateObject(wrappedValue: AssistViewModel(assistProvider: resolvedProvider))
        self._stabilityViewModel = StateObject(
            wrappedValue: NetworkStabilityPatternsViewModel(entitlements: entitlements)
        )
    }

    var body: some View {
        ZStack {
            Color.surfacePage
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                contentView
            }
        }
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationBarBackButtonHidden(false)
        .task {
            await viewModel.load(
                currentMeasurement: currentMeasurement,
                recentMeasurements: recentMeasurements,
                usageContext: usageContext,
                failureSignal: failureSignal,
                objective: objective,
                subcategory: subcategory,
                reportedProblem: reportedProblem
            )
        }
        .task {
            await stabilityViewModel.load()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Analisando conexão...")
                .foregroundColor(.textSecondary)
                .frame(maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.statusAttention)
                Text("Não foi possível concluir")
                    .font(.displayTitle)
                Text(message)
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
        case .success(let data):
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Status e Conclusão — indicador discreto em vez de um
                    // rótulo em caixa alta (issue UI Polish v2): a Hero
                    // (data.title) já conta a história, o indicador só marca
                    // o estado sem repetir ou contradizer o título.
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(data.headerStatus.contains("TUDO CERTO") ? Color.statusGood : Color.statusAttention)
                                .frame(width: 8, height: 8)
                            Text(data.headerStatus.contains("TUDO CERTO") ? "Diagnóstico concluído" : "Precisa de atenção")
                                .font(.captionStrong)
                                .foregroundColor(.textSecondary)
                        }

                        Text(data.title)
                            .font(.displayLarge)
                            .foregroundColor(.brandSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 24)

                    // O que encontramos — checklist compacto, sem círculo
                    // decorativo por métrica (issue UI Polish v2).
                    if !data.dimensions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("O que encontramos")
                                .font(.bodyRegularStrong)
                                .foregroundColor(.textPrimary)

                            VStack(spacing: 10) {
                                ForEach(data.dimensions, id: \.name) { dim in
                                    dimensionRow(dim)
                                }
                            }
                        }
                    }

                    // O que isso significa
                    VStack(alignment: .leading, spacing: 12) {
                        Text("O que isso significa")
                            .font(.bodyRegularStrong)
                            .foregroundColor(.textPrimary)

                        Text(data.summary)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }

                    // Próximo passo
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Próximo passo")
                            .font(.bodyRegularStrong)
                            .foregroundColor(.textPrimary)

                        if let rec = data.recommendation {
                            // Uma única recomendação, sem repetir o mesmo
                            // conteúdo em título + descrição + passos
                            // (issue UI Polish v2). Descrição e passos ficam
                            // atrás de "Por que recomendamos isso?".
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.statusAttention)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(rec.title)
                                        .font(.bodyRegularStrong)
                                        .foregroundColor(.textPrimary)

                                    let detailLines = recommendationDetailLines(rec, summary: data.summary)
                                    if !detailLines.isEmpty {
                                        Button(action: { showRecommendationDetails.toggle() }) {
                                            HStack(spacing: 4) {
                                                Text("Por que recomendamos isso?")
                                                Image(systemName: showRecommendationDetails ? "chevron.up" : "chevron.right")
                                                    .font(.caption2)
                                            }
                                            .font(.bodySmallMedium)
                                            .foregroundColor(.actionPrimary)
                                        }

                                        if showRecommendationDetails {
                                            VStack(alignment: .leading, spacing: 6) {
                                                ForEach(Array(detailLines.enumerated()), id: \.offset) { index, line in
                                                    Text(detailLines.count > 1 ? "\(index + 1). \(line)" : line)
                                                        .font(.bodySmall)
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }
                                            .padding(.top, 2)
                                        }
                                    }
                                }
                            }

                        } else {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.statusGood)

                                Text("Nenhuma ação necessária.")
                                    .font(.bodyRegular)
                                .foregroundColor(.textSecondary)
                            }
                        }

                        // Reteste é uma ação do usuário, não uma consequência
                        // opcional da recomendação do NDS. Ele permanece
                        // disponível mesmo quando o NDS devolve uma resposta
                        // sem recommendation.
                        if let retry = onRetry {
                            Button(action: {
                                retry()
                                dismiss()
                            }) {
                                Text("Testar novamente")
                                    .font(.buttonLabel)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.actionPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Padrões no seu histórico (issue #125) — cálculo local
                    // sobre o histórico do usuário, independente da resposta
                    // remota do NDS acima. Título e estado próprios para não
                    // parecer parte da mesma conclusão do Assist remoto.
                    stabilityPatternsSection

                    // Botão Detalhes da Medição — issue UI Polish v2: quando
                    // há um destino real de detalhes (`onShowDetails`),
                    // navega de verdade em vez de só fechar o sheet; quando
                    // não há (ex.: aberto a partir do Histórico), o botão é
                    // honesto sobre o que faz.
                    Button(action: {
                        if let onShowDetails {
                            onShowDetails()
                        }
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: onShowDetails != nil ? "chart.xyaxis.line" : "chevron.left")
                            Text(onShowDetails != nil ? "Ver detalhes da medição" : "Voltar")
                            if onShowDetails != nil {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.bodySmallMedium)
                        .foregroundColor(.actionPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    @ViewBuilder
    private var stabilityPatternsSection: some View {
        switch stabilityViewModel.state {
        case .loading, .unavailable:
            // `.unavailable` cobre Free, sem histórico ou falha ao
            // consultar — silenciar a seção é honesto aqui porque a
            // `AssistView` já é Plus-only na entrada; não é um bloqueio
            // escondido, é a ausência de dado para essa leitura específica.
            EmptyView()
        case .insufficientHistory:
            stabilityPatternsContainer {
                Text("Ainda não há histórico suficiente para apontar um padrão de horário nesta rede.")
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
            }
        case .noPatternDetected:
            stabilityPatternsContainer {
                Text("Nenhum horário de instabilidade recorrente identificado até agora.")
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
            }
        case .detected(let sentences):
            stabilityPatternsContainer {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(sentences.enumerated()), id: \.offset) { _, sentence in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.statusAttention)
                            Text(sentence)
                                .font(.bodyRegular)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func stabilityPatternsContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Padrões no seu histórico")
                .font(.bodyRegularStrong)
                .foregroundColor(.textPrimary)
            content()
        }
    }

    /// Checklist compacto (issue UI Polish v2) — antes cada dimensão tinha
    /// um círculo de 40pt com ícone dentro; agora é uma linha simples, mais
    /// próxima de um `Form`/lista nativa: um símbolo de estado + rótulo +
    /// valor à direita.
    private func dimensionRow(_ dimension: NetworkAssistDimension) -> some View {
        let statusColor = colorForStatus(dimension.status)
        return HStack(spacing: 10) {
            Image(systemName: iconForStatus(dimension.status))
                .font(.bodyRegular)
                .foregroundColor(statusColor)
                .frame(width: 20)

            Text(labelForDimension(dimension.name))
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)

            Spacer()

            Text(labelForStatus(dimension.status, metric: dimension.name))
                .font(.bodyRegularStrong)
                .foregroundColor(statusColor)
        }
        .accessibilityElement(children: .combine)
    }

    private func iconForStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "excellent", "good": return "checkmark.circle.fill"
        case "attention": return "exclamationmark.circle.fill"
        case "critical": return "xmark.circle.fill"
        default: return "circle"
        }
    }
    
    private func labelForDimension(_ name: String) -> String {
        switch name.lowercased() {
        case "download": return "Download"
        case "upload": return "Upload"
        case "latency": return "Latência"
        case "stability", "packet_loss", "perda": return "Estabilidade"
        default: return name.capitalized
        }
    }
    
    private func labelForStatus(_ status: String, metric: String) -> String {
        let metricLower = metric.lowercased()
        switch status.lowercased() {
        case "excellent":
            if metricLower == "latency" { return "Muito boa" }
            if metricLower == "stability" || metricLower == "packet_loss" || metricLower == "perda" { return "Sem perda relevante" }
            return "Muito bom"
        case "good":
            if metricLower == "latency" { return "Boa" }
            if metricLower == "stability" || metricLower == "packet_loss" || metricLower == "perda" { return "Estável" }
            return "Bom"
        case "attention":
            return "Atenção"
        case "critical":
            return "Ruim"
        case "unknown":
            return "Não avaliado"
        default:
            return status.capitalized
        }
    }
    
    /// A resposta do NDS costuma repetir a mesma frase em
    /// `recommendation.description` e em `recommendation.steps` (e às vezes
    /// no próprio `summary` da Hero) — issue UI Polish v2. Aqui a UI escolhe
    /// uma única fonte de detalhe por recomendação: os passos quando
    /// existem (são a forma mais acionável), senão a descrição, e nunca a
    /// descrição se ela só repete o que "O que isso significa" já disse.
    private func recommendationDetailLines(_ rec: NetworkAssistRecommendation, summary: String) -> [String] {
        if !rec.steps.isEmpty {
            return rec.steps
        }
        let trimmedDescription = rec.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty, trimmedDescription != trimmedSummary else { return [] }
        return [rec.description]
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "excellent", "good": return .statusGood
        case "attention": return .statusAttention
        case "critical": return .statusCritical
        default: return .textSecondary
        }
    }
}

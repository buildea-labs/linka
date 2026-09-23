import SwiftUI

/// Informação observada pelo sistema que uma entrega posterior poderá
/// allowlistar para o Netscope. Esta UI não constrói esse valor a partir de
/// `NetworkMeasurement` e não o serializa.
struct NetscopeObservedEvidence: Equatable, Sendable {
    enum ConnectionKind: String, Equatable, Sendable {
        case wifi
        case cellular
        case ethernet
        case other
        case unknown
    }

    struct WiFiDetails: Equatable, Sendable {
        let frequencyMHz: Double?
        let band: String?
        let channel: Int?
        let linkSpeedMbps: Double?
    }

    let connectionKind: ConnectionKind?
    let wifiDetails: WiFiDetails?

    init(connectionKind: ConnectionKind?, wifiDetails: WiFiDetails?) {
        self.connectionKind = connectionKind
        // Detalhe Wi-Fi não tem significado em outra rota e não deve ganhar
        // um valor substituto. Ausência continua sendo ausência.
        self.wifiDetails = connectionKind == .wifi ? wifiDetails : nil
    }

    static let absent = NetscopeObservedEvidence(connectionKind: nil, wifiDetails: nil)
}

/// Enquadramento escolhido pela pessoa. Não é evidência de rede e nunca deve
/// ser apresentado como uma métrica observada.
struct NetscopeDeclaredContext: Equatable, Sendable {
    enum Objective: String, Equatable, Sendable {
        case videoCall
        case gaming
        case streaming
        case general
    }

    let objective: Objective?

    static let absent = NetscopeDeclaredContext(objective: nil)
}

struct NetscopeAnalysisInput: Equatable, Sendable {
    let observedEvidence: NetscopeObservedEvidence
    let declaredContext: NetscopeDeclaredContext

    static let empty = NetscopeAnalysisInput(
        observedEvidence: .absent,
        declaredContext: .absent
    )
}

struct NetscopePresentationItem: Equatable, Sendable {
    let label: String
    let value: String
}

/// Conteúdo já preparado por uma implementação futura do reader. A UI não
/// converte métricas nem cria evidência: mostra somente itens explicitamente
/// fornecidos, em grupos semânticos separados. `summary` só pode resumir
/// evidência efetivamente recebida, deve declarar limites e dados ausentes
/// relevantes e nunca afirmar saúde, causa ou qualidade sem sustentação.
/// Em erro, timeout, inconclusão, indisponibilidade, limite de taxa ou fora
/// de escopo, a implementação futura não deve construir um `completed`.
struct NetscopeAnalysisPresentation: Equatable, Sendable {
    let summary: String
    let observedEvidence: [NetscopePresentationItem]
    let limitations: [String]
    let declaredContext: [NetscopePresentationItem]

    var displayableObservedEvidence: [NetscopePresentationItem] {
        displayable(observedEvidence)
    }

    var displayableLimitations: [String] {
        limitations.filter(isPresent)
    }

    var displayableDeclaredContext: [NetscopePresentationItem] {
        displayable(declaredContext)
    }

    private func displayable(_ items: [NetscopePresentationItem]) -> [NetscopePresentationItem] {
        items.filter { isPresent($0.label) && isPresent($0.value) }
    }

    private func isPresent(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum NetscopeAnalysisReading: Equatable, Sendable {
    case completed(NetscopeAnalysisPresentation)
    case inconclusive
    case unavailable
    case rateLimited
    case outOfScope
}

/// Única porta da apresentação. L-03 recebe a dependência, mas o app entrega
/// somente a implementação desligada abaixo: sem URLSession, endpoint, DNS,
/// chave ou egress. L-02 será a camada autorizada a substituir essa porta.
protocol NetscopeAnalysisReadingProviding: Sendable {
    func read(_ input: NetscopeAnalysisInput) async -> NetscopeAnalysisReading
}

struct DisabledNetscopeAnalysisReader: NetscopeAnalysisReadingProviding {
    func read(_ input: NetscopeAnalysisInput) async -> NetscopeAnalysisReading {
        .unavailable
    }
}

@MainActor
final class NetscopeAnalysisPresentationModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case reading(NetscopeAnalysisReading)
    }

    @Published private(set) var state: State = .idle

    private let reader: any NetscopeAnalysisReadingProviding
    private let input: NetscopeAnalysisInput

    init(
        reader: any NetscopeAnalysisReadingProviding = DisabledNetscopeAnalysisReader(),
        input: NetscopeAnalysisInput = .empty
    ) {
        self.reader = reader
        self.input = input
    }

    func load() async {
        state = .loading
        state = .reading(await reader.read(input))
    }
}

/// Destino secundário do resultado. O reteste permanece fora desta tela como
/// ação principal do resultado local, e fechar nunca invalida a medição.
struct NetscopeAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: NetscopeAnalysisPresentationModel

    init(
        reader: any NetscopeAnalysisReadingProviding = DisabledNetscopeAnalysisReader(),
        input: NetscopeAnalysisInput = .empty
    ) {
        _model = StateObject(wrappedValue: NetscopeAnalysisPresentationModel(reader: reader, input: input))
    }

    var body: some View {
        NavigationStack {
            // A leitura concluída pode ter evidência, limites e contexto. A
            // rolagem evita que Dynamic Type grande esconda ações no iPhone,
            // iPad ou Mac; VoiceOver continua alcançando toda a hierarquia.
            ScrollView(showsIndicators: true) {
                VStack(spacing: 20) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(24)
            }
            .linkaStaticScreenBackground()
            .navigationTitle(LinkaCopy.value("netscope.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LinkaCopy.value("netscope.close")) { dismiss() }
                }
            }
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView(LinkaCopy.value("netscope.loading"))
                .controlSize(.large)
                .accessibilityLabel(LinkaCopy.value("netscope.loading"))
                .transition(reduceMotion ? .identity : .opacity)
        case .reading(let reading):
            readingContent(reading)
                .transition(reduceMotion ? .identity : .opacity)
        }
    }

    private func readingContent(_ reading: NetscopeAnalysisReading) -> some View {
        let copy = NetscopeReadingCopy(reading: reading)
        return VStack(spacing: 16) {
            Image(systemName: copy.symbol)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(copy.color)
                .accessibilityHidden(true)

            Text(copy.title)
                .font(.displayMedium)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(copy.message)
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if case .completed(let presentation) = reading {
                presentationDetails(presentation)
            }

            if reading == .unavailable {
                Button(LinkaCopy.value("netscope.retry")) {
                    Task { await model.load() }
                }
                .buttonStyle(.linkaSecondary)
                .accessibilityHint(LinkaCopy.value("netscope.retry.hint"))
            }

            Button(LinkaCopy.value("netscope.backToResult")) { dismiss() }
                .buttonStyle(.linkaSecondary)
                .accessibilityHint(LinkaCopy.value("netscope.backToResult.hint"))
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func presentationDetails(_ presentation: NetscopeAnalysisPresentation) -> some View {
        let evidence = presentation.displayableObservedEvidence
        let context = presentation.displayableDeclaredContext
        let limitations = presentation.displayableLimitations

        if !evidence.isEmpty {
            readingSection(title: LinkaCopy.value("netscope.evidence.title"), items: evidence)
        }

        if !limitations.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(LinkaCopy.value("netscope.limitations.title"))
                    .font(.bodySmallStrong)
                    .foregroundColor(.textPrimary)
                ForEach(limitations, id: \.self) { limitation in
                    Text(limitation)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // Contexto não preenche nem rotula evidência. Sem valor declarado,
        // a seção simplesmente não aparece.
        if !context.isEmpty {
            readingSection(title: LinkaCopy.value("netscope.context.title"), items: context)
        }
    }

    private func readingSection(title: String, items: [NetscopePresentationItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.bodySmallStrong)
                .foregroundColor(.textPrimary)
            ForEach(items, id: \.label) { item in
                LabeledContent(item.label, value: item.value)
                    .font(.captionSmall)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

struct NetscopeReadingCopy {
    let title: String
    let message: String
    let symbol: String
    let color: Color

    init(reading: NetscopeAnalysisReading) {
        switch reading {
        case .completed(let presentation):
            title = LinkaCopy.value("netscope.completed.title")
            message = presentation.summary
            // Concluída significa apenas que a leitura chegou. Não é um
            // veredito de saúde da conexão.
            symbol = "text.magnifyingglass"
            color = .textSecondary
        case .inconclusive:
            title = LinkaCopy.value("netscope.inconclusive.title")
            message = LinkaCopy.value("netscope.inconclusive.message")
            symbol = "questionmark.circle"
            color = .statusAttention
        case .unavailable:
            title = LinkaCopy.value("netscope.unavailable.title")
            message = LinkaCopy.value("netscope.unavailable.message")
            symbol = "exclamationmark.circle"
            color = .textSecondary
        case .rateLimited:
            title = LinkaCopy.value("netscope.rateLimited.title")
            message = LinkaCopy.value("netscope.rateLimited.message")
            symbol = "clock"
            color = .statusAttention
        case .outOfScope:
            title = LinkaCopy.value("netscope.outOfScope.title")
            message = LinkaCopy.value("netscope.outOfScope.message")
            symbol = "minus.circle"
            color = .textSecondary
        }
    }
}

struct NetscopeResultEntryCard: View {
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(LinkaCopy.value("netscope.cta.title"))
                        .font(.bodyRegularStrong)
                        .foregroundColor(.textPrimary)
                    Text(LinkaCopy.value("netscope.cta.message"))
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandAccentWarm)
                    .frame(width: 36, height: 36)
                    .background(Color.brandAccentWarm.opacity(0.12), in: Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: LinkaRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(LinkaCopy.value("netscope.cta.hint"))
    }
}

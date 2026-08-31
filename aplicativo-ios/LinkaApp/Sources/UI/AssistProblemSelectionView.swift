import SwiftUI
import NetworkCore
import NetworkAssist
import LinkaEntitlements

/// Macro-grupo do problema relatado (issue objective+subcategory guiado).
/// As chaves espelham as usadas pelo SignallQ Android (repo irmão) para o
/// mesmo conceito — mantém o vocabulário de `objective` consistente entre
/// os dois produtos, mesmo sem compartilhar código.
enum AssistProblemObjective: String, CaseIterable, Identifiable {
    case jogosComLag = "JOGOS_COM_LAG"
    case videosTravam = "VIDEOS_TRAVAM"
    case chamadasCongelam = "CHAMADAS_CONGELAM"
    case sitesDemoram = "SITES_DEMORAM"
    case internetCaiOscila = "INTERNET_CAI_OSCILA"
    case velocidadeNaoChega = "VELOCIDADE_NAO_CHEGA"
    case wifiVsOperadora = "WIFI_VS_OPERADORA"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .jogosComLag: return "Jogos com lag"
        case .videosTravam: return "Vídeos travando"
        case .chamadasCongelam: return "Chamadas de vídeo congelando"
        case .sitesDemoram: return "Sites demoram para carregar"
        case .internetCaiOscila: return "Internet cai ou oscila"
        case .velocidadeNaoChega: return "Velocidade não chega ao contratado"
        case .wifiVsOperadora: return "Wi-Fi vs operadora"
        }
    }

    var systemImage: String {
        switch self {
        case .jogosComLag: return "gamecontroller"
        case .videosTravam: return "play.rectangle"
        case .chamadasCongelam: return "video"
        case .sitesDemoram: return "safari"
        case .internetCaiOscila: return "wifi.exclamationmark"
        case .velocidadeNaoChega: return "speedometer"
        case .wifiVsOperadora: return "antenna.radiowaves.left.and.right"
        }
    }

    /// Subcategorias fechadas por macro-grupo — 2 a 3 por `objective`,
    /// chaves estáveis que o NDS v2 recebe em `context.subcategory`.
    var subcategories: [AssistProblemSubcategory] {
        switch self {
        case .jogosComLag:
            return [
                AssistProblemSubcategory(key: "PING_ALTO", label: "Ping alto o tempo todo"),
                AssistProblemSubcategory(key: "LAG_INTERMITENTE", label: "Trava de vez em quando"),
                AssistProblemSubcategory(key: "DESCONECTA_DA_PARTIDA", label: "Cai da partida/sala")
            ]
        case .videosTravam:
            return [
                AssistProblemSubcategory(key: "BUFFERING_FREQUENTE", label: "Fica carregando (buffering) direto"),
                AssistProblemSubcategory(key: "QUALIDADE_CAI_SOZINHA", label: "Qualidade cai sozinha"),
                AssistProblemSubcategory(key: "SO_EM_HORARIO_DE_PICO", label: "Só piora em horário de pico")
            ]
        case .chamadasCongelam:
            return [
                AssistProblemSubcategory(key: "IMAGEM_CONGELA", label: "Imagem congela, áudio continua"),
                AssistProblemSubcategory(key: "AUDIO_CORTA", label: "Áudio corta ou fica robótico"),
                AssistProblemSubcategory(key: "CHAMADA_CAI", label: "A chamada cai sozinha")
            ]
        case .sitesDemoram:
            return [
                AssistProblemSubcategory(key: "PRIMEIRO_CARREGAMENTO_LENTO", label: "Demora só para abrir a página"),
                AssistProblemSubcategory(key: "LENTO_O_TEMPO_TODO", label: "Lento o dia inteiro"),
                AssistProblemSubcategory(key: "LENTO_SO_EM_ALGUNS_SITES", label: "Só em alguns sites específicos")
            ]
        case .internetCaiOscila:
            return [
                AssistProblemSubcategory(key: "QUEDA_TOTAL_ESPORADICA", label: "Cai de vez, sem sinal nenhum"),
                AssistProblemSubcategory(key: "OSCILACAO_SEM_QUEDA_TOTAL", label: "Oscila mas nunca cai de vez"),
                AssistProblemSubcategory(key: "PIORA_EM_HORARIO_FIXO", label: "Sempre piora no mesmo horário")
            ]
        case .velocidadeNaoChega:
            return [
                AssistProblemSubcategory(key: "DOWNLOAD_ABAIXO_DO_PLANO", label: "Download abaixo do contratado"),
                AssistProblemSubcategory(key: "UPLOAD_ABAIXO_DO_PLANO", label: "Upload abaixo do contratado"),
                AssistProblemSubcategory(key: "SO_NO_WIFI_A_CABO_OK", label: "Só no Wi-Fi (a cabo é normal)")
            ]
        case .wifiVsOperadora:
            return [
                AssistProblemSubcategory(key: "WIFI_PIOR_QUE_DADOS_MOVEIS", label: "Wi-Fi pior que dados móveis"),
                AssistProblemSubcategory(key: "DADOS_MOVEIS_PIOR_QUE_WIFI", label: "Dados móveis piores que Wi-Fi"),
                AssistProblemSubcategory(key: "AMBOS_RUINS", label: "Os dois parecem ruins")
            ]
        }
    }
}

struct AssistProblemSubcategory: Identifiable, Hashable {
    let key: String
    let label: String
    var id: String { key }
}

/// Etapa opcional antes do Assist observacional (issue objective+subcategory
/// guiado): no máximo 2 telas — escolher o macro-grupo e a subcategoria —
/// antes de cair no mesmo `AssistView` de hoje. "Pular" vai direto ao fluxo
/// observacional puro, sem objective/subcategory, idêntico ao comportamento
/// anterior a esta issue.
struct AssistProblemSelectionView: View {
    /// Capturado bem no ponto em que `MainView` empurra esta tela via
    /// `.navigationDestination(isPresented: $showAssist)` — chamar este
    /// `dismiss` sempre volta para antes desse push, não importa quantas
    /// etapas (`Step`) o usuário empilhou depois na MESMA stack ambiente de
    /// `MainView`. Repassado a `AssistView` como `onCloseSheet` (correção da
    /// regressão do PR #141): sem isso, o `@Environment(\.dismiss)` local de
    /// `AssistView` só dá pop de uma etapa (de volta pra seleção), em vez de
    /// fechar o fluxo inteiro do Assist — "Testar novamente" reiniciaria o
    /// teste no meio do fluxo guiado, e "Ver detalhes da medição" abriria
    /// atrás dele.
    @Environment(\.dismiss) private var dismissSheet

    /// Limite de caracteres do campo "Outro problema", espelhando
    /// `NetworkAssistConfiguration.maximumReportedProblemLength` no lado do
    /// client — trunca no client para nunca deixar passar mais que isso
    /// (o server também valida, mas a tela não deveria depender só dele).
    private static let reportedProblemMaxLength = 200

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]
    let usageContext: String?
    let onRetry: (() -> Void)?
    let onShowDetails: (() -> Void)?
    let entitlements: StoreKitEntitlementProvider?

    @State private var reportedProblemText: String = ""

    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        usageContext: String? = nil,
        onRetry: (() -> Void)? = nil,
        onShowDetails: (() -> Void)? = nil,
        entitlements: StoreKitEntitlementProvider? = nil
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.usageContext = usageContext
        self.onRetry = onRetry
        self.onShowDetails = onShowDetails
        self.entitlements = entitlements
    }

    var body: some View {
        // Esta view é empurrada SEM `path:` próprio pelo `NavigationStack` de
        // `MainView` (via `.navigationDestination(isPresented:)`). Por isso
        // usamos `NavigationLink(destination:)` — que empurra na stack ambiente
        // — evitando o uso de `.navigationDestination(for:)`, que gera
        // duplicação e avisos do SwiftUI quando aplicado a uma view não-raiz.
        objectiveStep
    }

    // MARK: - Etapa 1 — macro-grupo

    private var objectiveStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("O que está acontecendo?")
                    .font(.displayLarge)
                    .foregroundColor(.brandSurface)
                    .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(AssistProblemObjective.allCases) { objective in
                        NavigationLink(destination: subcategoryStep(for: objective)) {
                            problemRow(icon: objective.systemImage, label: objective.label)
                        }
                    }

                    // "Outro problema": não é um macro-grupo fechado, então
                    // não tem `subcategories` — vai direto para o campo de
                    // texto livre em vez da etapa 2. `reportedProblemText` é
                    // limpo no `.onAppear` de `reportedProblemStep`, não
                    // aqui — `NavigationLink` não tem closure de ação.
                    NavigationLink(destination: reportedProblemStep) {
                        problemRow(icon: "ellipsis.bubble", label: "Outro problema")
                    }
                }

                NavigationLink(destination: assistDestination(objective: nil, subcategory: nil, reportedProblem: nil)) {
                    Text("Pular e ver o diagnóstico geral")
                        .font(.bodySmallMedium)
                        .foregroundColor(.actionPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Etapa 2 — subcategoria

    private func subcategoryStep(for objective: AssistProblemObjective) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(objective.label)
                        .font(.displayLarge)
                        .foregroundColor(.brandSurface)

                    Text("Mais especificamente, qual dessas descreve melhor o que você percebeu?")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(objective.subcategories) { subcategory in
                        NavigationLink(
                            destination: assistDestination(objective: objective.rawValue, subcategory: subcategory.key, reportedProblem: nil)
                        ) {
                            problemRow(icon: "chevron.right.circle", label: subcategory.label)
                        }
                    }
                }

                // Pular a etapa 2: mantém o `objective` já escolhido, mas
                // segue para o Assist sem subcategoria.
                NavigationLink(
                    destination: assistDestination(objective: objective.rawValue, subcategory: nil, reportedProblem: nil)
                ) {
                    Text("Pular esta pergunta")
                        .font(.bodySmallMedium)
                        .foregroundColor(.actionPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Etapa alternativa — "Outro problema" (texto livre)

    /// Campo de texto livre para quando nenhum macro-grupo catalogado
    /// descreve o problema. Limitado a `reportedProblemMaxLength`
    /// caracteres, com contador visível e truncamento no client
    /// (`.onChange`) — nunca deixa passar mais que isso para o Assist.
    /// Este texto é só contexto para a explicação da IA: NÃO influencia a
    /// priorização de regras do NDS (essa continua vindo de
    /// objective/subcategory/métricas, que aqui são `nil`).
    private var reportedProblemStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Descreva o que está acontecendo")
                        .font(.displayLarge)
                        .foregroundColor(.brandSurface)

                    Text("Conte com suas palavras — isso ajuda o Assist a explicar melhor o resultado, mas não muda o diagnóstico técnico.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 24)

                VStack(alignment: .trailing, spacing: 8) {
                    TextEditor(text: $reportedProblemText)
                        .font(.bodyRegular)
                        .foregroundColor(.textPrimary)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color.surfaceCard)
                        .cornerRadius(12)
                        .onChange(of: reportedProblemText) { newValue in
                            if newValue.count > Self.reportedProblemMaxLength {
                                reportedProblemText = String(newValue.prefix(Self.reportedProblemMaxLength))
                            }
                        }

                    Text("\(reportedProblemText.count)/\(Self.reportedProblemMaxLength)")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }

                NavigationLink(
                    destination: assistDestination(
                        objective: nil,
                        subcategory: nil,
                        reportedProblem: String(
                            reportedProblemText
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .prefix(Self.reportedProblemMaxLength)
                        )
                    )
                ) {
                    Text("Continuar")
                        .font(.bodyRegularStrong)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.actionPrimary)
                        .cornerRadius(12)
                }
                .disabled(reportedProblemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(reportedProblemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        // Limpa o rascunho anterior ao entrar nesta etapa — antes isso
        // acontecia no botão "Outro problema" da etapa 1; virou `onAppear`
        // porque esse botão agora é um `NavigationLink` sem closure de ação.
        .onAppear { reportedProblemText = "" }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Destino final — fluxo observacional existente

    private func assistDestination(objective: String?, subcategory: String?, reportedProblem: String?) -> some View {
        AssistView(
            currentMeasurement: currentMeasurement,
            recentMeasurements: recentMeasurements,
            usageContext: usageContext,
            objective: objective,
            subcategory: subcategory,
            reportedProblem: reportedProblem,
            onRetry: onRetry,
            onShowDetails: onShowDetails,
            entitlements: entitlements,
            onCloseSheet: { dismissSheet() }
        )
    }

    /// Card reaproveitando o padrão visual de `AssistView`: superfície
    /// clara, ícone + rótulo, sem decoração extra (AGENTS.md §6 — beleza
    /// sem excesso).
    private func problemRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.bodyRegularStrong)
                .foregroundColor(.actionPrimary)
                .frame(width: 24)

            Text(label)
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(12)
    }
}

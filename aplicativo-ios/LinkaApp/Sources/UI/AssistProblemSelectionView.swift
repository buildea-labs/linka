import SwiftUI
import NetworkCore
import NetworkAssist
import LinkaEntitlements

/// Macro-grupo do problema relatado.
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
        case .chamadasCongelam: return "Chamadas congelando"
        case .sitesDemoram: return "Sites demoram para carregar"
        case .internetCaiOscila: return "Internet cai ou oscila"
        case .velocidadeNaoChega: return "Velocidade abaixo do esperado"
        case .wifiVsOperadora: return "Wi-Fi ou operadora"
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
                AssistProblemSubcategory(key: "BUFFERING_FREQUENTE", label: "Fica carregando direto"),
                AssistProblemSubcategory(key: "QUALIDADE_CAI_SOZINHA", label: "Qualidade cai sozinha"),
                AssistProblemSubcategory(key: "SO_EM_HORARIO_DE_PICO", label: "Piora em horário de pico")
            ]
        case .chamadasCongelam:
            return [
                AssistProblemSubcategory(key: "IMAGEM_CONGELA", label: "Imagem congela"),
                AssistProblemSubcategory(key: "AUDIO_CORTA", label: "Áudio corta ou fica robótico"),
                AssistProblemSubcategory(key: "CHAMADA_CAI", label: "Chamada cai sozinha")
            ]
        case .sitesDemoram:
            return [
                AssistProblemSubcategory(key: "PRIMEIRO_CARREGAMENTO_LENTO", label: "Demora para abrir páginas"),
                AssistProblemSubcategory(key: "LENTO_O_TEMPO_TODO", label: "Lento o tempo todo"),
                AssistProblemSubcategory(key: "LENTO_SO_EM_ALGUNS_SITES", label: "Apenas em sites específicos")
            ]
        case .internetCaiOscila:
            return [
                AssistProblemSubcategory(key: "QUEDA_TOTAL_ESPORADICA", label: "Cai de vez, sem sinal"),
                AssistProblemSubcategory(key: "OSCILACAO_SEM_QUEDA_TOTAL", label: "Oscila sem queda total"),
                AssistProblemSubcategory(key: "PIORA_EM_HORARIO_FIXO", label: "Piora sempre no mesmo horário")
            ]
        case .velocidadeNaoChega:
            return [
                AssistProblemSubcategory(key: "DOWNLOAD_ABAIXO_DO_PLANO", label: "Download abaixo do contratado"),
                AssistProblemSubcategory(key: "UPLOAD_ABAIXO_DO_PLANO", label: "Upload abaixo do contratado"),
                AssistProblemSubcategory(key: "SO_NO_WIFI_A_CABO_OK", label: "Só no Wi-Fi")
            ]
        case .wifiVsOperadora:
            return [
                AssistProblemSubcategory(key: "WIFI_PIOR_QUE_DADOS_MOVEIS", label: "Wi-Fi pior que dados móveis"),
                AssistProblemSubcategory(key: "DADOS_MOVEIS_PIOR_QUE_WIFI", label: "Dados móveis piores que Wi-Fi"),
                AssistProblemSubcategory(key: "AMBOS_RUINS", label: "Ambos parecem ruins")
            ]
        }
    }
}

struct AssistProblemSubcategory: Identifiable, Hashable {
    let key: String
    let label: String
    var id: String { key }
}

/// Seleção guiada de problemas do Assist em formato de List nativa da Apple.
struct AssistProblemSelectionView: View {
    @Environment(\.dismiss) private var dismissSheet

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
        objectiveStep
    }

    // MARK: - Etapa 1 — macro-grupo
    private var objectiveStep: some View {
        List {
            Section("O que está acontecendo?") {
                ForEach(AssistProblemObjective.allCases) { objective in
                    NavigationLink(destination: subcategoryStep(for: objective)) {
                        Label(objective.label, systemImage: objective.systemImage)
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                    }
                }

                NavigationLink(destination: reportedProblemStep) {
                    Label("Outro problema", systemImage: "ellipsis.bubble")
                        .font(.bodyRegular)
                        .foregroundColor(.textPrimary)
                }
            }

            Section {
                NavigationLink(destination: assistDestination(objective: nil, subcategory: nil, reportedProblem: nil)) {
                    Text("Pular e ver o diagnóstico geral")
                        .font(.bodySmallMedium)
                        .foregroundColor(.brandAccentWarm)
                }
            }
        }
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Etapa 2 — subcategoria
    private func subcategoryStep(for objective: AssistProblemObjective) -> some View {
        List {
            Section(header: Text(objective.label), footer: Text("Selecione a opção que melhor descreve o que você percebeu.")) {
                ForEach(objective.subcategories) { subcategory in
                    NavigationLink(
                        destination: assistDestination(objective: objective.rawValue, subcategory: subcategory.key, reportedProblem: nil)
                    ) {
                        Text(subcategory.label)
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                    }
                }
            }

            Section {
                NavigationLink(
                    destination: assistDestination(objective: objective.rawValue, subcategory: nil, reportedProblem: nil)
                ) {
                    Text("Pular esta pergunta")
                        .font(.bodySmallMedium)
                        .foregroundColor(.brandAccentWarm)
                }
            }
        }
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Etapa alternativa — "Outro problema"
    private var reportedProblemStep: some View {
        Form {
            Section(header: Text("Descreva o que está acontecendo"), footer: Text("Isso ajuda o Assist a explicar melhor o resultado, sem alterar os dados técnicos.")) {
                TextEditor(text: $reportedProblemText)
                    .frame(minHeight: 100)
                    .onChange(of: reportedProblemText) { newValue in
                        if newValue.count > Self.reportedProblemMaxLength {
                            reportedProblemText = String(newValue.prefix(Self.reportedProblemMaxLength))
                        }
                    }

                HStack {
                    Spacer()
                    Text("\(reportedProblemText.count)/\(Self.reportedProblemMaxLength)")
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }

            Section {
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
                        .foregroundColor(.brandAccentWarm)
                }
                .disabled(reportedProblemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Assist")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { reportedProblemText = "" }
    }

    // MARK: - Destino final
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
}

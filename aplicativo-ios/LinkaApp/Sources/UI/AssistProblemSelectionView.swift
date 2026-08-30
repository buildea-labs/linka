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
    private enum Step: Hashable {
        case subcategory(AssistProblemObjective)
        case result(AssistProblemObjective, AssistProblemSubcategory)
        case observational
    }

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]
    let usageContext: String?
    let onRetry: (() -> Void)?
    let onShowDetails: (() -> Void)?
    let entitlements: StoreKitEntitlementProvider?

    @State private var path: [Step] = []

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
        NavigationStack(path: $path) {
            objectiveStep
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .subcategory(let objective):
                        subcategoryStep(for: objective)
                    case .result(let objective, let subcategory):
                        assistDestination(objective: objective.rawValue, subcategory: subcategory.key)
                    case .observational:
                        assistDestination(objective: nil, subcategory: nil)
                    }
                }
        }
    }

    // MARK: - Etapa 1 — macro-grupo

    private var objectiveStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("O que está acontecendo?")
                        .font(.displayLarge)
                        .foregroundColor(.brandSurface)

                    Text("Escolha o que mais parece com o que você está vendo — isso ajuda o Assist a olhar para os dados certos.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(AssistProblemObjective.allCases) { objective in
                        Button {
                            path.append(.subcategory(objective))
                        } label: {
                            problemRow(icon: objective.systemImage, label: objective.label)
                        }
                    }
                }

                Button {
                    path.append(.observational)
                } label: {
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
                        Button {
                            path.append(.result(objective, subcategory))
                        } label: {
                            problemRow(icon: "chevron.right.circle", label: subcategory.label)
                        }
                    }
                }
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

    // MARK: - Destino final — fluxo observacional existente

    private func assistDestination(objective: String?, subcategory: String?) -> some View {
        AssistView(
            currentMeasurement: currentMeasurement,
            recentMeasurements: recentMeasurements,
            usageContext: usageContext,
            objective: objective,
            subcategory: subcategory,
            onRetry: onRetry,
            onShowDetails: onShowDetails,
            entitlements: entitlements
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

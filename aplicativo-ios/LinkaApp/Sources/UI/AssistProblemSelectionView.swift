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
    /// Capturado na RAIZ do `NavigationStack` desta tela — é o `dismiss` que
    /// fecha o sheet inteiro apresentado por `MainView`. Repassado a
    /// `AssistView` como `onCloseSheet` (correção da regressão do PR #141):
    /// sem isso, o `@Environment(\.dismiss)` local de `AssistView`, quando
    /// ela é empurrada por `navigationDestination` dentro do
    /// `NavigationStack` desta tela, só faz pop de volta para a seleção em
    /// vez de fechar o sheet — "Testar novamente" reinicia o teste atrás do
    /// sheet ainda aberto, e "Ver detalhes da medição" abre escondido atrás
    /// dele.
    @Environment(\.dismiss) private var dismissSheet

    private enum Step: Hashable {
        case subcategory(AssistProblemObjective)
        /// Campo de texto livre para "Outro problema" — só existe quando o
        /// usuário escolhe explicitamente esta opção na etapa 1, em vez de
        /// um `objective` fechado. Não leva a uma etapa de subcategoria:
        /// não existe subcategoria fechada para um problema não catalogado.
        case reportedProblemInput
        case result(objective: String?, subcategory: String?, reportedProblem: String?)
        case observational
    }

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

    @State private var path: [Step] = []
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
        NavigationStack(path: $path) {
            objectiveStep
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .subcategory(let objective):
                        subcategoryStep(for: objective)
                    case .reportedProblemInput:
                        reportedProblemStep
                    case .result(let objective, let subcategory, let reportedProblem):
                        assistDestination(objective: objective, subcategory: subcategory, reportedProblem: reportedProblem)
                    case .observational:
                        assistDestination(objective: nil, subcategory: nil, reportedProblem: nil)
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

                    // "Outro problema": não é um macro-grupo fechado, então
                    // não tem `subcategories` — vai direto para o campo de
                    // texto livre em vez da etapa 2.
                    Button {
                        reportedProblemText = ""
                        path.append(.reportedProblemInput)
                    } label: {
                        problemRow(icon: "ellipsis.bubble", label: "Outro problema")
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
                            path.append(.result(objective: objective.rawValue, subcategory: subcategory.key, reportedProblem: nil))
                        } label: {
                            problemRow(icon: "chevron.right.circle", label: subcategory.label)
                        }
                    }
                }

                // Pular a etapa 2: mantém o `objective` já escolhido, mas
                // segue para o Assist sem subcategoria (contrato v1 —
                // `BuildeaDiagnosticAPI.usesV2` exige as duas chaves juntas).
                Button {
                    path.append(.result(objective: objective.rawValue, subcategory: nil, reportedProblem: nil))
                } label: {
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

                Button {
                    let trimmed = reportedProblemText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .prefix(Self.reportedProblemMaxLength)
                    path.append(.result(objective: nil, subcategory: nil, reportedProblem: String(trimmed)))
                } label: {
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

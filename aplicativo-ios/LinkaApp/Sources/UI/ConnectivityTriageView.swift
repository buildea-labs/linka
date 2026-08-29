import SwiftUI
import NetworkConnectivityTriage

/// Recuperação curta após uma falha de medição. Mostra fatos do aparelho no
/// instante em que a pessoa pede ajuda; não substitui a medição nem o Assist.
struct ConnectivityTriageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var report: ConnectivityTriageReport?
    @State private var isLoading = true
    let onRetry: () -> Void
    private let service: NetworkConnectivityTriageService

    init(
        onRetry: @escaping () -> Void,
        service: NetworkConnectivityTriageService = NetworkConnectivityTriageService()
    ) {
        self.onRetry = onRetry
        self.service = service
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Verificando conexão…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Verificando a conexão deste aparelho")
            } else if let report {
                VStack(alignment: .leading, spacing: 20) {
                    Text(eyebrow(for: report))
                        .font(.monoEyebrow)
                        .foregroundColor(.textSecondary)
                    Text(title(for: report))
                        .font(.displayMedium)
                        .foregroundColor(.textPrimary)
                    Text(message(for: report))
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        dismiss()
                        onRetry()
                    } label: {
                        Text("Testar novamente")
                            .font(.buttonLabel)
                            .foregroundColor(Color.surfacePage)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityHint("Inicia uma nova medição")

                    Button("Fechar", action: { dismiss() })
                        .font(.bodySmallStrong)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .accessibilityElement(children: .contain)
            } else {
                EmptyView()
            }
        }
        .background(Color.surfacePage.ignoresSafeArea())
        .navigationTitle("Verificar conexão")
        .task {
            do {
                let result = try await service.run()
                guard !Task.isCancelled else { return }
                report = result
                isLoading = false
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                report = ConnectivityTriageReport(
                    outcome: .inconclusive,
                    path: ConnectivityPathSnapshot(status: .requiresConnection)
                )
                isLoading = false
            }
        }
    }

    private func eyebrow(for report: ConnectivityTriageReport) -> String {
        switch report.outcome {
        case .noNetworkPath: return "CONEXÃO INDISPONÍVEL"
        case .internetReachable: return "CONEXÃO DISPONÍVEL AGORA"
        case .dnsResolutionUnavailable: return "ENDEREÇOS NÃO RESOLVIDOS"
        case .captivePortalSuspected: return "ACESSO PODE SER NECESSÁRIO"
        case .inconclusive: return "VERIFICAÇÃO INCONCLUSIVA"
        }
    }

    private func title(for report: ConnectivityTriageReport) -> String {
        switch report.outcome {
        case .noNetworkPath: return "Não há conexão disponível"
        case .internetReachable: return "A conexão está disponível agora"
        case .dnsResolutionUnavailable: return "Não foi possível resolver os endereços de teste"
        case .captivePortalSuspected: return "Esta rede pode exigir acesso antes de usar a internet"
        case .inconclusive: return "Ainda não foi possível concluir"
        }
    }

    private func message(for report: ConnectivityTriageReport) -> String {
        switch report.outcome {
        case .noNetworkPath:
            return "O Linka não encontrou um caminho de rede neste aparelho agora. Ative uma conexão e tente novamente."
        case .internetReachable:
            return "O Linka encontrou uma conexão agora, mas não consegue identificar por que o teste anterior foi interrompido. Tente novamente."
        case .dnsResolutionUnavailable:
            return "O aparelho tem um caminho de rede, mas não conseguiu resolver os endereços de teste. Aguarde um instante e tente novamente."
        case .captivePortalSuspected:
            return "A resposta da rede foi diferente do esperado. Se esta for uma rede pública, abra o acesso dela e tente novamente."
        case .inconclusive:
            return "O aparelho ainda está tentando estabelecer uma conexão. Aguarde um instante e tente novamente."
        }
    }
}

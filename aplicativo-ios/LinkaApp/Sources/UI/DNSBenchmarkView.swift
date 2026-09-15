import SwiftUI
import NetworkDNSBenchmark

/// Uma sessão secundária e descartável. Não recebe nem escreve Histórico,
/// perfis ou qualquer identificador da conexão.
struct DNSBenchmarkView: View {
    @StateObject private var benchmark = DNSBenchmarkCoordinator()
    @StateObject private var configuration = DNSConfigurationCoordinator()
    @State private var selectedProvider: DNSProvider?
    @State private var showConsent = false
    @Environment(\.openURL) private var openURL

    let onRetest: () -> Void

    var body: some View {
        List {
            Section {
                Text("Compara a resposta DNS nesta conexão. Isso não aumenta sua velocidade contratada, ping ou Wi-Fi.")
                    .foregroundStyle(.secondary)
            }

            Section {
                if let milliseconds = benchmark.systemHealth.milliseconds {
                    LabeledContent("Resposta", value: Self.milliseconds(milliseconds))
                        .accessibilityLabel("DNS atual do sistema, resposta \(Self.milliseconds(milliseconds))")
                } else {
                    Text("Não disponível nesta tentativa")
                        .foregroundStyle(.secondary)
                }
                Text("O sistema não expôs o IP do resolvedor nesta conexão.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("DNS atual do sistema")
            } footer: {
                Text("É uma resolução pelo sistema. Ela não entra no ranking porque pode usar cache, gateway, VPN ou perfil corporativo.")
            }

            content
            configurationSection
        }
        .navigationTitle("Resposta de DNS")
        .toolbar {
            if case .running = benchmark.state {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: benchmark.cancel) }
            }
        }
        .task { await configuration.refresh() }
        .confirmationDialog("Criar configuração de DNS?", isPresented: $showConsent, titleVisibility: .visible) {
            if let provider = selectedProvider {
                Link("Política de privacidade de \(provider.name)", destination: provider.privacyURL)
                Button("Criar configuração") { Task { await configuration.create(provider: provider) } }
            }
            Button("Cancelar", role: .cancel) { selectedProvider = nil }
        } message: {
            if let provider = selectedProvider {
                Text("O DNS de todo o dispositivo usará \(provider.name) via DNS sobre HTTPS enquanto a configuração estiver ativa. As consultas de nomes serão enviadas a esse provedor. Você pode remover a configuração no Linka depois.")
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch benchmark.state {
        case .idle:
            Section {
                Button("Iniciar comparação", action: benchmark.start)
                    .accessibilityHint("Envia consultas DNS sintéticas aos provedores comparados")
            } footer: {
                Text("A comparação usa consultas sintéticas; não usa domínios da sua navegação.")
            }
        case .running:
            Section {
                HStack(spacing: 12) { ProgressView(); Text("Comparando respostas de DNS…") }
                    .accessibilityElement(children: .combine)
            } footer: { Text("Três rodadas por provedor, com timeout de 2 segundos.") }
        case .completed(let result):
            Section {
                if let winner = result.winner {
                    Text("Menor mediana nesta comparação: \(winner.provider.name)")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("Sem vencedor matemático nesta comparação")
                        .font(.subheadline.weight(.semibold))
                }
                ForEach(result.orderedCandidates) { candidate in
                    candidateRow(candidate, winner: result.winner?.id == candidate.id)
                }
            } header: {
                Text("Comparação desta sessão")
            } footer: {
                Text("O resultado vale só para esta tentativa. Menor mediana não é promessa de uma conexão melhor em todos os usos.")
            }
        case .cancelled:
            Section { Text("Comparação cancelada").foregroundStyle(.secondary) }
        case .failed:
            Section { Text("Não foi possível concluir a comparação.").foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder private func candidateRow(_ candidate: DNSBenchmarkCandidate, winner: Bool) -> some View {
        if let median = candidate.medianMilliseconds {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(candidate.provider.name)
                    Spacer()
                    Text(Self.milliseconds(median)).monospacedDigit()
                }
                if winner { Text("Menor mediana nesta comparação").font(.caption).foregroundStyle(.secondary) }
                if configuration.status == .none {
                    Button("Escolher \(candidate.provider.name)") {
                        selectedProvider = candidate.provider
                        showConsent = true
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Escolher \(candidate.provider.name), \(Self.milliseconds(median))")
                }
                Link("Política de privacidade", destination: candidate.provider.privacyURL)
                    .font(.caption)
            }
            .accessibilityElement(children: .contain)
        } else {
            HStack { Text(candidate.provider.name); Spacer(); Text("Inconclusivo").foregroundStyle(.secondary) }
                .accessibilityLabel("\(candidate.provider.name), inconclusivo")
        }
    }

    @ViewBuilder private var configurationSection: some View {
        switch configuration.status {
        case .none:
            EmptyView()
        case .awaitingActivation(let name):
            Section {
                Text("\(name) via DNS sobre HTTPS foi criada, mas o iPhone ainda não a ativou. Abra Ajustes > Geral > VPN e Gerenciamento de Dispositivo > DNS, ative \(name) e volte aqui para confirmar.")
                Button("Já ativei — atualizar") { Task { await configuration.refresh() } }
                Button("Remover configuração de DNS", role: .destructive) { Task { await configuration.remove() } }
            } header: { Text("Configuração de DNS") }
        case .active(let name):
            Section {
                Label("Ativa: \(name) via DNS sobre HTTPS", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button("Medir de novo", action: onRetest)
                Button("Atualizar estado") { Task { await configuration.refresh() } }
                Button("Remover configuração de DNS", role: .destructive) { Task { await configuration.remove() } }
            } header: { Text("Configuração de DNS") }
        case .failed:
            Section {
                Text("Não foi possível confirmar a configuração. Nenhum outro DNS foi escolhido automaticamente.")
                    .foregroundStyle(.secondary)
                Button("Tentar novamente") { Task { await configuration.refresh() } }
                Button("Remover configuração de DNS", role: .destructive) { Task { await configuration.remove() } }
            } header: { Text("Configuração de DNS") }
        case .unavailable:
            Section {
                Text("Aplicar DNS não está disponível neste dispositivo. A comparação continua disponível.")
                    .foregroundStyle(.secondary)
            } header: { Text("Configuração de DNS") }
        }
    }

    private static func milliseconds(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) ms"
    }
}

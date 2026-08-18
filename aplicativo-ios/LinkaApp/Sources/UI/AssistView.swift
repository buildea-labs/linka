import SwiftUI
import MeasurementHistory
import NetworkCore
import NetworkAssist
import LinkaEntitlements

struct AssistView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel: AssistViewModel

    let currentMeasurement: NetworkMeasurement?
    let recentMeasurements: [NetworkMeasurement]
    let failureSignal: NetworkAssistFailureSignal?
    let onRetry: (() -> Void)?

    init(
        currentMeasurement: NetworkMeasurement?,
        recentMeasurements: [NetworkMeasurement] = [],
        failureSignal: NetworkAssistFailureSignal? = nil,
        onRetry: (() -> Void)? = nil,
        entitlements: StoreKitEntitlementProvider? = nil,
        assistProvider: (any NetworkAssistProviding)? = nil,
        assistIsRemote: Bool = AssistContainer.isRemoteAssistEnabled()
    ) {
        self.currentMeasurement = currentMeasurement
        self.recentMeasurements = recentMeasurements
        self.failureSignal = failureSignal
        self.onRetry = onRetry

        let resolvedProvider: any NetworkAssistProviding
        if let assistProvider {
            resolvedProvider = assistProvider
        } else if let entitlements {
            resolvedProvider = AssistContainer.makeAssistProvider(entitlements: entitlements)
        } else {
            resolvedProvider = NetworkAssistService(transport: UnconfiguredNetworkAssistTransport())
        }

        self._viewModel = StateObject(wrappedValue: AssistViewModel(assistProvider: resolvedProvider))
    }

    var body: some View {
        ZStack {
            Color("BackgroundTertiary")
                .ignoresSafeArea()
            
            contentView
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Sobre o seu resultado")
                    .font(.headline)
            }
        }
        .task {
            await viewModel.load(
                currentMeasurement: currentMeasurement,
                recentMeasurements: recentMeasurements,
                failureSignal: failureSignal
            )
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Analisando conexão...")
                .foregroundColor(.textSecondary)
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Não foi possível concluir")
                    .font(.headline)
                Text(message)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        case .success(let data):
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Status e Conclusão
                    VStack(alignment: .leading, spacing: 12) {
                        Text(data.headerStatus.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundColor(data.headerStatus.contains("TUDO CERTO") ? .green : .orange)
                        
                        Text(data.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    // Evidências
                    if !data.dimensions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Por que o Linka chegou nisso?")
                                .font(.headline)
                            
                            VStack(spacing: 12) {
                                ForEach(data.dimensions, id: \.name) { dim in
                                    dimensionRow(dim)
                                }
                            }
                            .padding()
                            .background(Color("BackgroundSecondary"))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Impacto (Resumo)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("O que isso significa para você")
                            .font(.headline)
                        
                        Text(data.summary)
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Ação (Próximo Passo)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Próximo passo")
                            .font(.headline)
                        
                        if let rec = data.recommendation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rec.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.textPrimary)
                                Text(rec.description)
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            if let retry = onRetry {
                                Button(action: {
                                    retry()
                                    dismiss()
                                }) {
                                    Text("Testar novamente")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        } else {
                            Text("Nenhuma ação necessária.")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
        }
    }
    
    private func dimensionRow(_ dimension: NetworkAssistDimension) -> some View {
        HStack {
            Image(systemName: iconForDimension(dimension.name))
                .foregroundColor(.textSecondary)
                .frame(width: 24)
            Text(labelForDimension(dimension.name))
                .font(.body)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(labelForStatus(dimension.status))
                .font(.body.weight(.medium))
                .foregroundColor(colorForStatus(dimension.status))
        }
    }
    
    private func iconForDimension(_ name: String) -> String {
        switch name.lowercased() {
        case "download": return "arrow.down"
        case "upload": return "arrow.up"
        case "latency": return "clock"
        case "stability", "packet_loss", "perda": return "waveform.path.ecg"
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
    
    private func labelForStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "excellent": return "Muito bom"
        case "good": return "Bom"
        case "attention": return "Atenção"
        case "critical": return "Ruim"
        case "unknown": return "Não avaliado"
        default: return status.capitalized
        }
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "excellent", "good": return .green
        case "attention": return .orange
        case "critical": return .red
        default: return .textSecondary
        }
    }
}

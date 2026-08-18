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
            Color.surfacePage
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Divider() // A subtle line under the Navigation Bar
                
                contentView
            }
        }
        .navigationTitle("Assist")
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
                .frame(maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
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
                VStack(alignment: .leading, spacing: 40) {
                    
                    // Status e Conclusão
                    VStack(alignment: .leading, spacing: 8) {
                        Text(data.headerStatus.uppercased())
                            .font(.captionStrong)
                            .foregroundColor(data.headerStatus.contains("TUDO CERTO") ? .green : .orange)
                        
                        Text(data.title)
                            .font(.displayLarge)
                            .foregroundColor(.brandSurface)
                    }
                    .padding(.top, 24)
                    
                    // Evidências
                    if !data.dimensions.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Por que o Linka chegou nisso?")
                                .font(.bodyRegularStrong)
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(data.dimensions.enumerated()), id: \.element.name) { index, dim in
                                    dimensionRow(dim)
                                    
                                    if index < data.dimensions.count - 1 {
                                        Divider()
                                            .padding(.leading, 56)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Impacto (Resumo)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("O que isso significa para você")
                            .font(.bodyRegularStrong)
                            .foregroundColor(.textPrimary)
                        
                        Text(data.summary)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Ação (Próximo Passo)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Próximo passo")
                            .font(.bodyRegularStrong)
                            .foregroundColor(.textPrimary)
                        
                        if let rec = data.recommendation {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rec.title)
                                        .font(.bodyRegularStrong)
                                        .foregroundColor(.textPrimary)
                                    Text(rec.description)
                                        .font(.bodyRegular)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            
                            if let retry = onRetry {
                                Button(action: {
                                    retry()
                                    dismiss()
                                }) {
                                    Text("Testar novamente")
                                        .font(.buttonLabel)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        } else {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("Nenhuma ação necessária.")
                                    .font(.bodyRegular)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.top, 16)
                    
                    // Botão Detalhes da Medição
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Ver detalhes da medição")
                            Image(systemName: "chevron.right")
                        }
                        .font(.bodySmallMedium)
                        .foregroundColor(.blue) // The prototype uses a system blue color for this text button
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func dimensionRow(_ dimension: NetworkAssistDimension) -> some View {
        let statusColor = colorForStatus(dimension.status)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForDimension(dimension.name))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            Text(labelForDimension(dimension.name))
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(labelForStatus(dimension.status, metric: dimension.name))
                .font(.bodyRegularStrong)
                .foregroundColor(statusColor)
        }
    }
    
    private func iconForDimension(_ name: String) -> String {
        switch name.lowercased() {
        case "download": return "arrow.down"
        case "upload": return "arrow.up"
        case "latency": return "clock"
        case "stability", "packet_loss", "perda": return "wifi"
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
    
    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "excellent", "good": return .green
        case "attention": return .orange
        case "critical": return .red
        default: return .textSecondary
        }
    }
}

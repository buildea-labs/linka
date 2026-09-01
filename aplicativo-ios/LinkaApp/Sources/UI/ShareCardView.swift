import SwiftUI
import NetworkCore

#if canImport(UIKit)
import UIKit
#endif

/// Cartão compartilhável de uma única medição (issue #54).
///
/// Renderiza uma imagem própria do Linka — nunca screenshot bruto — a
/// partir de um `NetworkMeasurement` já produzido pelo `LinkaEngine`
/// (resultado atual) ou já salvo pelo `MeasurementHistory` (item do
/// Histórico). Não recalcula nada: consome só o que já chegou no contrato
/// canônico (AGENTS.md §8 — sem duplicar lógica de medição na UI).
///
/// Fora do cartão por design (AGENTS.md §10): `networkIdentifier`
/// (provedor/SSID cru) e qualquer equivalente a IP/BSSID — não são lidos
/// aqui, nem existe toggle de opt-in nesta entrega.
struct ShareCardView: View {
    let measurement: NetworkMeasurement

    /// Tamanho fixo em pontos do cartão exportado. Proporção vertical
    /// (retrato) funciona bem tanto anexado a uma mensagem quanto como
    /// imagem de story em qualquer app de destino — o share sheet nativo
    /// decide o resto.
    static let cardSize = CGSize(width: 360, height: 480)

    var body: some View {
        VStack(spacing: 0) {
            Text("LINKA SPEEDTEST")
                .font(.monoEyebrow)
                .foregroundColor(.textSecondary)
                .padding(.top, 40)

            MetricRing(
                connecting: false,
                progress: 1.0,
                value: formattedDownload,
                unit: "Mbps",
                size: 188
            )
            .padding(.top, 24)

            Text("DOWNLOAD")
                .font(.monoEyebrow)
                .foregroundColor(.textSecondary)
                .padding(.top, 20)
                .padding(.bottom, 10)

            HStack(spacing: 6) {
                statFragment(value: formattedUpload, unit: "Mbps upload")

                if let formattedPing {
                    dot
                    statFragment(value: formattedPing, unit: "ms ping")
                }
            }

            if let connectionLine {
                Text(connectionLine)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 14)
            }

            Spacer(minLength: 24)

            HStack(alignment: .bottom) {
                // Marca oficial (issue #54) — mesmo asset `wordmark` já
                // usado em `SplashView`, importado sem redesenho
                // (AGENTS.md §7). Pequena de propósito: nunca compete com
                // o resultado (requisito de aceite #6 da issue).
                Image("wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Spacer()

                Text(formattedDate)
                    .font(.monoCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
        .background(Color.surfaceCard)
    }

    private var dot: some View {
        Text("·")
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
    }

    @ViewBuilder
    private func statFragment(value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.metricSecondary)
                .foregroundColor(.textPrimary)
            Text(unit)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
    }

    private var formattedDownload: String {
        formattedSpeed(measurement.downloadMbps)
    }

    private var formattedUpload: String {
        formattedSpeed(measurement.uploadMbps)
    }

    private func formattedSpeed(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private var formattedPing: String? {
        guard let latencyMs = measurement.latencyMs else { return nil }
        return "\(Int(latencyMs.rounded()))"
    }

    /// Linha discreta de contexto de rede — só tipo de conexão e, quando
    /// aplicável, banda Wi-Fi confirmada pelo sistema (issue #51). Nunca
    /// inclui `networkIdentifier` (provedor/SSID) nem qualquer coisa
    /// equivalente a IP/BSSID (requisito de aceite #4 da issue #54).
    private var connectionLine: String? {
        guard let kind = measurement.connectionKind else { return nil }

        let kindLabel: String
        switch kind {
        case .wifi: kindLabel = "Wi-Fi"
        case .cellular: kindLabel = "Rede móvel"
        case .ethernet: kindLabel = "Ethernet"
        case .other: kindLabel = "Outra rede"
        }

        guard kind == .wifi, let wifiBandGHz = measurement.wifiBandGHz else {
            return kindLabel
        }

        let band = wifiBandGHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", wifiBandGHz)
            : String(format: "%.1f", wifiBandGHz)
        return "\(kindLabel) · \(band)GHz"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: measurement.measuredAt)
    }
}

// MARK: - Renderização sob demanda

/// Rasteriza `ShareCardView` em `Data` PNG pronta pro share sheet nativo
/// (issue #54). Usa `ImageRenderer` (disponível a partir do iOS 16, já o
/// deployment target confirmado do app) em vez de captura de tela — o
/// cartão nunca reflete o que está desenhado na hora, só os dados da
/// medição recebida.
@MainActor
enum ShareCardRenderer {
    /// ~3x o tamanho em pontos do cartão, equivalente a uma tela @3x —
    /// nítido em qualquer app de destino sem gerar um arquivo
    /// desproporcional ao conteúdo.
    private static let exportScale: CGFloat = 3

    static func renderPNGData(for measurement: NetworkMeasurement, colorScheme: ColorScheme) -> Data? {
        #if canImport(UIKit)
        let card = ShareCardView(measurement: measurement)
            .environment(\.colorScheme, colorScheme)

        let renderer = ImageRenderer(content: card)
        renderer.scale = exportScale
        renderer.isOpaque = true

        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
        #else
        return nil
        #endif
    }
}

// MARK: - Gatilho reutilizável (resultado atual + item do Histórico)

#if canImport(UIKit)
/// Gera o cartão sob demanda e apresenta o `UIActivityViewController`
/// nativo (issue #54). Um único lugar para a sequência "renderizar →
/// apresentar", reutilizado tanto pelo resultado atual (`MainView`) quanto
/// por cada item do Histórico (`HistoryRow`) — sem duplicar a lógica em
/// cada superfície.
private struct ShareMeasurementPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let measurement: NetworkMeasurement?
    @Environment(\.colorScheme) private var colorScheme
    @State private var shareImage: UIImage?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { presenting in
                guard presenting else {
                    shareImage = nil
                    return
                }
                guard let measurement,
                      let data = ShareCardRenderer.renderPNGData(for: measurement, colorScheme: colorScheme),
                      let image = UIImage(data: data) else {
                    isPresented = false
                    return
                }
                shareImage = image
            }
            .sheet(isPresented: $isPresented) {
                if let shareImage {
                    ShareSheet(activityItems: [shareImage])
                }
            }
    }
}

extension View {
    /// Liga um `Binding<Bool>` de apresentação ao fluxo completo de
    /// compartilhamento de uma única medição (issue #54): gera o cartão e
    /// abre o share sheet nativo quando `isPresented` vira `true`.
    func shareMeasurementSheet(isPresented: Binding<Bool>, measurement: NetworkMeasurement?) -> some View {
        modifier(ShareMeasurementPresenter(isPresented: isPresented, measurement: measurement))
    }
}
#endif

#if !canImport(UIKit)
extension View {
    /// No-op fora do UIKit (ex.: macOS) — mantém os call sites de
    /// `MainView`/`HistoryRow` livres de `#if` espalhado. O
    /// `UIActivityViewController` é exclusivo de UIKit; compartilhar
    /// resultado nessas plataformas fica fora de escopo até existir um
    /// caminho nativo equivalente (AGENTS.md §2).
    func shareMeasurementSheet(isPresented: Binding<Bool>, measurement: NetworkMeasurement?) -> some View {
        self
    }
}
#endif

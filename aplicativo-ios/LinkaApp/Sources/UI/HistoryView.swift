import SwiftUI
import MapKit
import MeasurementHistory
import NetworkCore
import NetworkInsights
import LinkaEntitlements
import LinkaModules

enum HistoryDisplayMode {
    case list
    case map
}

private enum HistoryFilter: String, CaseIterable {
    case all = "Todos"
    case wifi = "Wi-Fi"
    case mobile = "Móvel"
}

private enum HistorySort: CaseIterable, Hashable {
    case recent
    case fastest
    case slowest

    var label: String {
        switch self {
        case .recent: return "Recentes"
        case .fastest: return "Mais rápido"
        case .slowest: return "Mais lento"
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider
    var onSelectMeasurement: ((NetworkMeasurement) -> Void)? = nil

    @State private var measurements: [NetworkMeasurement] = []
    @State private var isLoading = true
    @State private var hasPlus = false
    @State private var showPurchase = false
    @State private var purchaseEntryPoint: PurchaseEntryPoint = .historyInsights
    @State private var insightText: String?
    @State private var filter: HistoryFilter = .all
    @State private var sort: HistorySort = .recent

    private var repository: any MeasurementHistoryRepository {
        LinkaMeasurementHistory.makeRepository(entitlements: entitlements)
    }

    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        VStack(spacing: 12) {
                            Picker("Filtro", selection: $filter) {
                                ForEach(availableFilters, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Menu {
                                ForEach(HistorySort.allCases, id: \.self) { option in
                                    Button {
                                        sort = option
                                    } label: {
                                        HStack {
                                            Text(option.label)
                                            if sort == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label(sort.label, systemImage: "arrow.up.arrow.down")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if hasPlus {
                        if let insightText = insightText {
                            Section("Insights") {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.brandAccentWarm)
                                        .font(.bodyRegularStrong)
                                    Text(insightText)
                                        .font(.bodyRegular)
                                        .foregroundColor(.textPrimary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else if !filteredMeasurements.isEmpty {
                        Section("Insights") {
                            Button {
                                purchaseEntryPoint = .historyInsights
                                showPurchase = true
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.textSecondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Descubra padrões por rede e horário")
                                            .font(.bodyRegular)
                                            .foregroundColor(.textPrimary)
                                        LinkaPlusWordmarkView(height: 14)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmallStrong)
                                        .foregroundColor(.textSecondary.opacity(0.65))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !filteredMeasurements.isEmpty {
                        Section {
                            HistoryWaveChartView(measurements: filteredMeasurements)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                    }

                    if filteredMeasurements.isEmpty {
                        Section {
                            LinkaUnavailableState(
                                title: "Nenhuma medição",
                                message: "Faça uma medição para vê-la aqui.",
                                systemImage: "clock"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        Section("Medições (\(filteredMeasurements.count))") {
                            ForEach(filteredMeasurements, id: \.id) { measurement in
                                Button {
                                    onSelectMeasurement?(measurement)
                                } label: {
                                    AppleStyleHistoryRow(measurement: measurement)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Histórico")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showPurchase) {
            PurchaseSheet(entryPoint: purchaseEntryPoint) {
                loadData()
            }
            .environmentObject(entitlements)
        }
        .onAppear {
            loadData()
        }
    }

    private var filteredMeasurements: [NetworkMeasurement] {
        let scoped = measurements.filter { measurement in
            switch filter {
            case .all: return true
            case .wifi: return measurement.connectionKind == .wifi
            case .mobile: return measurement.connectionKind == .cellular
            }
        }
        switch sort {
        case .recent: return scoped.sorted { $0.measuredAt > $1.measuredAt }
        case .fastest: return scoped.sorted { ($0.downloadMbps ?? 0) > ($1.downloadMbps ?? 0) }
        case .slowest: return scoped.sorted { ($0.downloadMbps ?? 0) < ($1.downloadMbps ?? 0) }
        }
    }

    private var availableFilters: [HistoryFilter] {
        #if os(macOS)
        // Um Mac não mede rede celular. Não oferecemos um filtro que nunca
        // pode ter dado real, mas preservamos a mesma consulta de histórico.
        return [.all, .wifi]
        #else
        return HistoryFilter.allCases
        #endif
    }

    private func loadData() {
        Task {
            let decision = LinkaEntitlementPolicy.decision(
                for: .insights,
                snapshot: entitlements.snapshot,
                at: Date()
            )

            hasPlus = decision.isGranted

            let query = MeasurementQuery(limit: 50, sortOrder: .newestFirst)
            measurements = (try? await repository.measurements(matching: query)) ?? []
            
            if hasPlus {
                insightText = weeklyInsightText(from: measurements)
            }

            isLoading = false
        }
    }

    private func weeklyInsightText(from measurements: [NetworkMeasurement]) -> String? {
        let now = Date()
        let cutoff7d = now.addingTimeInterval(-7 * 86_400)
        let cutoff14d = now.addingTimeInterval(-14 * 86_400)

        let last7 = measurements.filter { $0.measuredAt >= cutoff7d }
        let baseline = measurements.filter { $0.measuredAt >= cutoff14d && $0.measuredAt < cutoff7d }

        guard last7.count >= 2, baseline.count >= 2 else { return nil }

        let insightsAnalyzer = EntitlementGatedNetworkInsightsAnalyzer(
            wrapping: BasicNetworkInsightsAnalyzer(),
            snapshot: entitlements.snapshot
        )

        let comparison: NetworkPeriodComparison
        do {
            comparison = try insightsAnalyzer.comparePeriods(current: last7, baseline: baseline)
        } catch {
            return nil
        }

        guard let download = comparison.comparison(for: .downloadMbps),
              let percentDelta = download.percentDelta,
              abs(percentDelta) >= 5 else {
            return nil
        }

        let deltaStr = String(format: "%.0f", abs(percentDelta))
        switch download.direction {
        case .improved:
            return "Sua velocidade de download está cerca de \(deltaStr)% melhor esta semana em comparação à semana anterior."
        case .worsened:
            return "Sua velocidade de download está cerca de \(deltaStr)% pior esta semana em comparação à semana anterior."
        case .stable, .unavailable:
            return nil
        }
    }
}

// MARK: - Gráfico em Linha Horizontal Estilo Ondas (Dois Eixos)

struct HistoryWaveChartView: View {
    let measurements: [NetworkMeasurement]
    @State private var selectedIndex: Int? = nil

    private var chronologicalMeasurements: [NetworkMeasurement] {
        measurements.sorted { $0.measuredAt < $1.measuredAt }
    }

    private var maxDownload: Double {
        let maxVal = chronologicalMeasurements.compactMap { $0.downloadMbps }.max() ?? 100
        return max(maxVal, 10)
    }

    private var maxUpload: Double {
        let maxVal = chronologicalMeasurements.compactMap { $0.uploadMbps }.max() ?? 50
        return max(maxVal, 5)
    }

    private var latestMeasurement: NetworkMeasurement? {
        chronologicalMeasurements.last
    }

    private var activeMeasurement: NetworkMeasurement? {
        if let idx = selectedIndex, idx >= 0, idx < chronologicalMeasurements.count {
            return chronologicalMeasurements[idx]
        }
        return latestMeasurement
    }

    private let downloadColor = Color(red: 0.12, green: 0.53, blue: 0.98) // Azul Royal Apple
    private let uploadColor = Color(red: 0.95, green: 0.50, blue: 0.15)   // Laranja Quente Linka

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header do Gráfico estilo Apple Cards
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendência de Velocidade")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    if let active = activeMeasurement {
                        Text(formatHeaderDate(active.measuredAt))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Legendas / Eixos de Métricas
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(downloadColor)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Download")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textSecondary)
                            Text("\(formatValue(activeMeasurement?.downloadMbps)) Mbps")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(uploadColor)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Upload")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textSecondary)
                            Text("\(formatValue(activeMeasurement?.uploadMbps)) Mbps")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }

            // Canvas da Onda com Dois Eixos Horizontais
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height

                ZStack(alignment: .topLeading) {
                    // Linhas de Grade e Eixos Horizontais de Referência
                    VStack(spacing: 0) {
                        // Eixo Horizontal Superior (Download Scale)
                        HStack {
                            Text("↓ \(Int(round(maxDownload))) Mbps")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(downloadColor.opacity(0.8))
                            Spacer()
                        }
                        .padding(.bottom, 2)

                        Rectangle()
                            .fill(Color.borderDefault.opacity(0.35))
                            .frame(height: 0.8)

                        Spacer()

                        // Eixo Horizontal Intermediário (Upload Scale)
                        HStack {
                            Text("↑ \(Int(round(maxUpload))) Mbps")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(uploadColor.opacity(0.8))
                            Spacer()
                        }
                        .padding(.bottom, 2)

                        Rectangle()
                            .fill(Color.borderDefault.opacity(0.25))
                            .frame(height: 0.8)

                        Spacer()

                        // Eixo Horizontal Base
                        Rectangle()
                            .fill(Color.borderDefault.opacity(0.35))
                            .frame(height: 0.8)
                    }

                    // Curvas e Áreas de Ondas
                    if chronologicalMeasurements.count >= 2 {
                        let count = chronologicalMeasurements.count
                        let stepX = width / CGFloat(max(count - 1, 1))
                        let topPadding: CGFloat = 16
                        let availableHeight = max(height - topPadding - 10, 10)

                        // Pontos normalizados de Download
                        let dlPoints: [CGPoint] = chronologicalMeasurements.enumerated().map { i, m in
                            let x = CGFloat(i) * stepX
                            let dl = m.downloadMbps ?? 0
                            let ratio = CGFloat(dl / maxDownload)
                            let y = height - (ratio * availableHeight) - 4
                            return CGPoint(x: x, y: y)
                        }

                        // Pontos normalizados de Upload
                        let ulPoints: [CGPoint] = chronologicalMeasurements.enumerated().map { i, m in
                            let x = CGFloat(i) * stepX
                            let ul = m.uploadMbps ?? 0
                            let ratio = CGFloat(ul / maxUpload) * 0.75 // Ajuste relativo
                            let y = height - (ratio * availableHeight) - 4
                            return CGPoint(x: x, y: y)
                        }

                        // 1. Onda de Download (Área + Linha)
                        wavePath(points: dlPoints, isClosed: true, height: height)
                            .fill(
                                LinearGradient(
                                    colors: [downloadColor.opacity(0.28), downloadColor.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        wavePath(points: dlPoints, isClosed: false, height: height)
                            .stroke(downloadColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        // 2. Onda de Upload (Área + Linha)
                        wavePath(points: ulPoints, isClosed: true, height: height)
                            .fill(
                                LinearGradient(
                                    colors: [uploadColor.opacity(0.25), uploadColor.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        wavePath(points: ulPoints, isClosed: false, height: height)
                            .stroke(uploadColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                        // Indicador Interativo de Seleção
                        if let selIdx = selectedIndex, selIdx < dlPoints.count {
                            let ptDl = dlPoints[selIdx]
                            let ptUl = ulPoints[selIdx]

                            // Linha Vertical Guia
                            Path { p in
                                p.move(to: CGPoint(x: ptDl.x, y: 0))
                                p.addLine(to: CGPoint(x: ptDl.x, y: height))
                            }
                            .stroke(Color.textSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                            // Ponto Download
                            Circle()
                                .fill(downloadColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .position(ptDl)

                            // Ponto Upload
                            Circle()
                                .fill(uploadColor)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .position(ptUl)
                        }
                    } else if let single = chronologicalMeasurements.first {
                        // Estado de medição única
                        VStack(spacing: 8) {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("Apenas 1 medição registrada (\(formatValue(single.downloadMbps)) Mbps)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let count = chronologicalMeasurements.count
                            guard count > 1 else { return }
                            let stepX = width / CGFloat(count - 1)
                            let index = Int(round(value.location.x / stepX))
                            let clamped = max(0, min(count - 1, index))
                            selectedIndex = clamped
                        }
                        .onEnded { _ in
                            // Mantém a última selecionada ou limpa após 2 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedIndex = nil
                                }
                            }
                        }
                )
            }
            .frame(height: 140)

            // Rodapé do Gráfico: Eixo Horizontal de Tempo
            if chronologicalMeasurements.count >= 2,
               let firstDate = chronologicalMeasurements.first?.measuredAt,
               let lastDate = chronologicalMeasurements.last?.measuredAt {
                HStack {
                    Text(formatAxisDate(firstDate))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("Tempo / Medições")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.textSecondary.opacity(0.6))
                    Spacer()
                    Text(formatAxisDate(lastDate))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, -4)
            }
        }
        .padding(18)
        .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: LinkaRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LinkaRadius.lg, style: .continuous)
                .stroke(Color.borderDefault.opacity(0.4), lineWidth: 0.6)
        )
    }

    // Suavizador de Curvas Catmull-Rom para Bézier Cúbica
    private func wavePath(points: [CGPoint], isClosed: Bool, height: CGFloat) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }

        if points.count == 1 {
            let pt = points[0]
            if isClosed {
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: pt.y))
                path.addLine(to: CGPoint(x: pt.x * 2, y: pt.y))
                path.addLine(to: CGPoint(x: pt.x * 2, y: height))
                path.closeSubpath()
            } else {
                path.move(to: CGPoint(x: 0, y: pt.y))
                path.addLine(to: CGPoint(x: pt.x * 2, y: pt.y))
            }
            return path
        }

        if isClosed {
            path.move(to: CGPoint(x: points[0].x, y: height))
            path.addLine(to: points[0])
        } else {
            path.move(to: points[0])
        }

        let tension: CGFloat = 0.32
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        if isClosed {
            path.addLine(to: CGPoint(x: points.last!.x, y: height))
            path.closeSubpath()
        }

        return path
    }

    private func formatValue(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return "\(Int(round(v)))"
    }

    private func formatHeaderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d 'de' MMMM, HH:mm"
        return formatter.string(from: date)
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Célula de Histórico no Estilo Nativo Apple

struct AppleStyleHistoryRow: View {
    let measurement: NetworkMeasurement

    var body: some View {
        HStack(spacing: 14) {
            // 1. Ícone do Tipo de Rede (Apple Style Rounded Tile)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 42, height: 42)

                Image(systemName: networkIconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconTintColor)
            }

            // 2. Título, Data e Origem (Mac vs iPhone)
            VStack(alignment: .leading, spacing: 4) {
                Text(networkTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)

                    if let platform = measurement.devicePlatform {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary.opacity(0.6))

                        HStack(spacing: 3) {
                            Image(systemName: platform == "macOS" ? "macbook" : "iphone")
                                .font(.system(size: 10))
                            Text(platform == "macOS" ? "Mac" : "iPhone")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer(minLength: 8)

            // 3. Bloco de Métricas (Download Hero + Upload/Ping)
            VStack(alignment: .trailing, spacing: 3) {
                // Download em Destaque
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.53, blue: 0.98))
                    Text(formatSpeed(measurement.downloadMbps))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Mbps")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                }

                // Linha Secundária: Upload e Latência
                HStack(spacing: 8) {
                    if let up = measurement.uploadMbps {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(red: 0.95, green: 0.50, blue: 0.15))
                            Text("\(Int(round(up)))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if let ping = measurement.latencyMs {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundColor(.textSecondary)
                            Text("\(Int(round(ping)))ms")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }

            // 4. Chevron Nativo Apple
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary.opacity(0.35))
                .padding(.leading, 2)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var networkTitle: String {
        switch measurement.connectionKind {
        case .wifi:
            return measurement.wifiContext?.ssid ?? "Wi-Fi"
        case .cellular:
            return measurement.networkIdentifier ?? "Rede móvel"
        case .ethernet:
            return "Ethernet"
        default:
            return "Medição"
        }
    }

    private var networkIconName: String {
        switch measurement.connectionKind {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        default: return "network"
        }
    }

    private var iconTintColor: Color {
        switch measurement.connectionKind {
        case .wifi: return Color(red: 0.12, green: 0.53, blue: 0.98)
        case .cellular: return .green
        case .ethernet: return .orange
        default: return .secondary
        }
    }

    private var iconBackgroundColor: Color {
        iconTintColor.opacity(0.12)
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        let date = measurement.measuredAt
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "pt_BR")
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: date)

        if calendar.isDateInToday(date) {
            return "Hoje, \(timeString)"
        } else if calendar.isDateInYesterday(date) {
            return "Ontem, \(timeString)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pt_BR")
            dateFormatter.dateFormat = "d 'de' MMM"
            return "\(dateFormatter.string(from: date)), \(timeString)"
        }
    }

    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "—" }
        return String(format: "%.0f", speed)
    }
}

struct MapLocationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct MapHistoryView: View {
    let measurements: [NetworkMeasurement]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.55052, longitude: -46.633308),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var locationItems: [MapLocationItem] {
        measurements.compactMap { m in
            if let loc = m.location {
                return MapLocationItem(id: m.id, coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), title: m.serverIdentifier ?? "Medição")
            }
            return nil
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locationItems) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Circle()
                    .fill(Color.brandAccentWarm)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .onAppear {
            if let first = locationItems.first {
                region.center = first.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        }
    }
}

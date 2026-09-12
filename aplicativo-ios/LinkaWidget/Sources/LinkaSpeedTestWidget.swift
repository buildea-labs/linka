import WidgetKit
import SwiftUI
import AppIntents
import LinkaAppIntents
import LinkaWidgetShared

struct LinkaSpeedTestWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LinkaWidgetEntry

    private var locale: Locale {
        LinkaWidgetShared.effectiveLocale(
            preference: LinkaWidgetShared.languagePreference()
        )
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
        .environment(\.locale, locale)
        .containerBackground(Color.surfacePage, for: .widget)
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.brandSurface)
                Text("Linka")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer(minLength: 0)
            
            if let summary = entry.summary {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedMbps(summary.downloadMbps))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Mbps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        
                    Text(relativeLabel(for: summary.measuredAt))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analise sua conexão")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer(minLength: 0)

            testButton(label: "Analisar")
        }
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.brandSurface)
                    Text("Linka")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                Spacer(minLength: 0)
                
                if let summary = entry.summary {
                    HStack(alignment: .bottom, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedMbps(summary.downloadMbps))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Text("Download")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        
                        if let upload = summary.uploadMbps {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formattedMbps(upload))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("Upload")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        if let ping = summary.latencyMs {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(Int(ping.rounded()))")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("Ping (ms)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    Text(fullDateTimeLabel(for: summary.measuredAt))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analise sua conexão")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Toque em Analisar para iniciar.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            testButton(label: "Analisar", compact: true)
        }
    }

    @ViewBuilder
    private func testButton(label: String, compact: Bool = false) -> some View {
        Button(intent: StartSpeedTestIntent()) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.brandOnSurface)
                .frame(maxWidth: compact ? nil : .infinity)
                .padding(.horizontal, compact ? 16 : 0)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.brandSurface)
    }

    private func formattedMbps(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(locale))
    }

    private func relativeLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = "HH:mm"
            return String(
                format: String(localized: "Hoje, %@", defaultValue: "Today, %@", locale: locale),
                locale: locale,
                formatter.string(from: date)
            )
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
    
    private func fullDateTimeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        if Calendar.current.isDateInToday(date) {
            return String(
                format: String(localized: "Hoje, %@", defaultValue: "Today, %@", locale: locale),
                locale: locale,
                formatter.string(from: date)
            )
        } else {
            formatter.dateFormat = "dd/MM/yyyy, HH:mm"
            return formatter.string(from: date)
        }
    }
}

struct LinkaSpeedTestWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: LinkaWidgetShared.widgetKind,
            provider: LinkaWidgetTimelineProvider()
        ) { entry in
            LinkaSpeedTestWidgetView(entry: entry)
        }
        .configurationDisplayName("Linka SpeedTest")
        .description("Testar velocidade e ver o último resultado.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

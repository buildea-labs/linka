import SwiftUI
import NetworkCore
import LinkaEntitlements

/// Tela de detalhe de uma medição histórica em formato de List nativo padrão Apple.
struct HistoricalMeasurementDetailView: View {
    let measurement: NetworkMeasurement
    let onStartNewMeasurementWithAdvancedWiFi: (() -> Void)?
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider

    init(
        measurement: NetworkMeasurement,
        onStartNewMeasurementWithAdvancedWiFi: (() -> Void)? = nil
    ) {
        self.measurement = measurement
        self.onStartNewMeasurementWithAdvancedWiFi = onStartNewMeasurementWithAdvancedWiFi
    }

    var body: some View {
        MeasurementDetailView(
            measurement: measurement,
            duration: nil,
            onStartNewMeasurementWithAdvancedWiFi: onStartNewMeasurementWithAdvancedWiFi
        )
            .environmentObject(entitlements)
    }
}

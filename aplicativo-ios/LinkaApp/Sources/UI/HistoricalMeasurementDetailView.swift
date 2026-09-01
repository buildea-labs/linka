import SwiftUI
import NetworkCore
import LinkaEntitlements

/// Tela de detalhe de uma medição histórica em formato de List nativo padrão Apple.
struct HistoricalMeasurementDetailView: View {
    let measurement: NetworkMeasurement
    @EnvironmentObject private var entitlements: StoreKitEntitlementProvider

    var body: some View {
        MeasurementDetailView(measurement: measurement, duration: nil)
            .environmentObject(entitlements)
    }
}

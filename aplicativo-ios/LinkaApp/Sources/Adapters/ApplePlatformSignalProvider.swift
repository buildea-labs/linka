import Foundation
import NetworkDiagnostics

#if canImport(CoreTelephony) && os(iOS)
import CoreTelephony
#endif

#if canImport(CoreWLAN) && os(macOS)
import CoreWLAN
#endif

/// Preenche `PlatformHints` com o que Apple público expõe sem entitlement
/// extra:
/// - iOS: portadora e tecnologia via `CoreTelephony`. **Sem** RSSI móvel
///   (não exposto). **Sem** SSID/RSSI Wi-Fi (`NEHotspotHelper` requer
///   entitlement).
/// - macOS: SSID, BSSID, RSSI e banda via `CoreWLAN`.
struct ApplePlatformSignalProvider: PlatformSignalProviding {
    func currentHints() async -> PlatformHints {
        PlatformHints(
            wifi: currentWifi(),
            mobile: currentMobile()
        )
    }

    private func currentWifi() -> PlatformHints.Wifi? {
        #if canImport(CoreWLAN) && os(macOS)
        guard let iface = CWWiFiClient.shared().interface() else { return nil }
        let ssid = iface.ssid()
        let bssid = iface.bssid()
        let rssi: Double? = {
            let v = iface.rssiValue()
            return v == 0 ? nil : Double(v)
        }()
        let linkSpeed: Double? = {
            let v = iface.transmitRate()
            return v == 0 ? nil : v
        }()
        let band: String? = {
            let channel = iface.wlanChannel()
            guard let band = channel?.channelBand else { return nil }
            return Self.bandLabel(forGHz: Self.mapCWChannelBand(band))
        }()

        let wifi = PlatformHints.Wifi(
            ssid: ssid,
            bssid: bssid,
            rssiDbm: rssi,
            band: band,
            linkSpeedMbps: linkSpeed
        )
        let anySet = wifi.ssid != nil || wifi.bssid != nil || wifi.rssiDbm != nil
            || wifi.band != nil || wifi.linkSpeedMbps != nil
        return anySet ? wifi : nil
        #else
        return nil
        #endif
    }

    private func currentMobile() -> PlatformHints.Mobile? {
        #if canImport(CoreTelephony) && os(iOS)
        let info = CTTelephonyNetworkInfo()
        let carriers = info.serviceSubscriberCellularProviders ?? [:]
        let technologies = info.serviceCurrentRadioAccessTechnology ?? [:]

        let operatorName = carriers.values.compactMap { $0.carrierName }.first
        let technology = technologies.values.first.flatMap(mapTechnology(_:))

        guard operatorName != nil || technology != nil else { return nil }
        return PlatformHints.Mobile(technology: technology, operatorName: operatorName)
        #else
        return nil
        #endif
    }

    /// Banda Wi-Fi confirmada pelo sistema, em GHz — issue #51. Reaproveita
    /// a mesma leitura de `CWChannel.channelBand` que já alimenta
    /// `PlatformHints.Wifi.band` (via `mapCWChannelBand(_:)`), mas devolve
    /// `Double` (2.4/5) em vez de `String`, para
    /// `NetworkMeasurement.wifiBandGHz`.
    ///
    /// Só macOS: no iPhone não há fonte pública de banda sem
    /// `NEHotspotHelper` (entitlement) nem sem localização — `nil` é o
    /// estado normal ali, não erro. Nunca infere banda por SSID/BSSID.
    static func currentWifiBandGHz() -> Double? {
        #if canImport(CoreWLAN) && os(macOS)
        guard let iface = CWWiFiClient.shared().interface(),
              let band = iface.wlanChannel()?.channelBand else {
            return nil
        }
        return mapCWChannelBand(band)
        #else
        return nil
        #endif
    }

    #if canImport(CoreWLAN) && os(macOS)
    /// Única tradução de `CWChannelBand` do arquivo — issue #89. Antes,
    /// `currentWifi()` (produzindo `String?`) e `currentWifiBandGHz()`
    /// (produzindo `Double?`) reimplementavam este switch de forma
    /// independente, correndo o risco de divergir silenciosamente se um
    /// novo case fosse tratado diferente nos dois lugares. Agora os dois
    /// call sites delegam pra cá; a tradução `Double -> String` em
    /// `bandLabel(forGHz:)` é conversão de formato, não uma segunda fonte
    /// de verdade sobre o significado de cada `CWChannelBand` case.
    static func mapCWChannelBand(_ band: CWChannelBand) -> Double? {
        switch band {
        case .band2GHz: return 2.4
        case .band5GHz: return 5.0
        case .bandUnknown: return nil
        @unknown default: return nil
        }
    }

    /// Rótulo textual da banda a partir do `Double?` já mapeado por
    /// `mapCWChannelBand(_:)` — não reabre o switch sobre `CWChannelBand`.
    static func bandLabel(forGHz ghz: Double?) -> String? {
        guard let ghz else { return nil }
        if ghz == 2.4 { return "2.4GHz" }
        if ghz == 5.0 { return "5GHz" }
        return nil
    }
    #endif

    #if canImport(CoreTelephony) && os(iOS)
    private func mapTechnology(_ raw: String) -> String? {
        switch raw {
        case CTRadioAccessTechnologyLTE: return "4G"
        case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR: return "5G"
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMA1x,
             CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyeHRPD:
            return "3G"
        case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
            return "2G"
        default:
            return nil
        }
    }
    #endif
}

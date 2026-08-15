import Foundation
import MeasurementHistory
import MeasurementHistoryCloudKit
import LinkaEntitlements

/// Compatibilidade temporária com a fundação inicial da branch.
/// Código novo deve importar `MeasurementHistory` diretamente.
public typealias HistoryProviding = MeasurementHistory.MeasurementHistoryRepository
public typealias InMemoryHistoryStore = MeasurementHistory.InMemoryMeasurementHistoryRepository

/// Decorator de sincronização do histórico via CloudKit (issue #71) — espelha
/// o histórico local (fonte de verdade) para a private database do iCloud
/// do usuário, em segundo plano, sem introduzir login nem backend próprio
/// do Linka. Ver `MeasurementHistoryCloudKit.SyncingMeasurementHistoryRepository`
/// para as garantias estruturais (local-first, iCloud opcional, exclusão
/// propagada, conflito determinístico).
public typealias SyncingHistoryRepository = MeasurementHistoryCloudKit.SyncingMeasurementHistoryRepository
public typealias CloudKitMeasurementRemoteStore = MeasurementHistoryCloudKit.CloudKitMeasurementRemoteStore

/// Ponto único de construção do repositório de histórico usado pelo app
/// (issue #71). Antes desta issue, `FileMeasurementHistoryRepository` era
/// instanciado separadamente em três lugares de `LinkaApp/Sources`, sempre
/// com o mesmo `fileURL` — este factory centraliza isso e, de quebra, é
/// onde a sincronização CloudKit entra sem vazar `CloudKit`/`CKContainer`
/// para os consumidores de UI (eles continuam enxergando só o protocolo
/// `MeasurementHistoryRepository`).
public enum LinkaMeasurementHistory {
    /// Mesmo caminho de arquivo usado antes desta issue — preservado para
    /// não perder histórico local existente na migração (requisito de
    /// aceite: "histórico local antigo continua legível").
    public static var defaultFileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("measurements.json")
    }

    /// Repositório usado pelo app: `FileMeasurementHistoryRepository` como
    /// fonte de verdade local (síncrona, sempre disponível) com sync
    /// CloudKit em segundo plano por cima. A sincronização respeita o
    /// mesmo gate de entitlement que já protege a superfície de Histórico
    /// (`LinkaCapability.history`) — este pacote não reimplementa checagem
    /// de plano, só consulta a decisão já existente em `LinkaEntitlements`.
    public static func makeRepository(
        fileURL: URL = defaultFileURL,
        entitlements: any LinkaEntitlementProviding
    ) -> SyncingHistoryRepository {
        SyncingHistoryRepository(
            local: FileMeasurementHistoryRepository(fileURL: fileURL),
            remote: CloudKitMeasurementRemoteStore(),
            isSyncPermitted: {
                await entitlements.hasAccess(to: .history)
            }
        )
    }
}

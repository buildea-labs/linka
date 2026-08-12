import MeasurementHistory

/// Compatibilidade temporária com a fundação inicial da branch.
/// Código novo deve importar `MeasurementHistory` diretamente.
public typealias HistoryProviding = MeasurementHistory.MeasurementHistoryRepository
public typealias InMemoryHistoryStore = MeasurementHistory.InMemoryMeasurementHistoryRepository

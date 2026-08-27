import Foundation


public struct MeasurementState {
    public var ping: Double?
    public var jitter: Double?
    public var packetLossPercent: Double?
    public var downloadSpeed: Double? // in Mbps
    public var uploadSpeed: Double? // in Mbps
    public var progress: Double // 0.0 to 1.0
    public var phase: Phase
    public var provider: String?
    public var networkType: String?
    public var duration: Double?
    /// Latência sob carga (ms), amostrada durante a fase de download
    /// (issue #52). `nil` quando a fase não produziu amostras válidas
    /// suficientes — nunca um valor inventado. Espelha o campo homônimo já
    /// existente no contrato canônico `NetworkMeasurement`.
    public var loadedLatencyMs: Double?
    /// Latência sob carga (ms) amostrada durante a fase de upload (issue
    /// #128) — paridade com `loadedLatencyMs`, mesma sondagem
    /// (`SpeedTestCore.performLoadedLatencyProbe`) e mesma agregação
    /// (`SpeedTestCore.aggregateLoadedLatency`), só que concorrente à carga
    /// de upload em vez de download. `nil` pelo mesmo motivo: amostras
    /// insuficientes ou sondagem indisponível nunca inventam um valor.
    /// Campo distinto (em vez de reaproveitar `loadedLatencyMs` para as duas
    /// fases) porque download e upload sob carga são fatos independentes —
    /// um pode existir sem o outro, e a comparação parada-vs-carga (issue
    /// #128, `NetworkInsights.LoadResponsivenessEvaluator`) precisa dos dois
    /// separadamente. Espelha o campo homônimo em `NetworkMeasurement`.
    public var loadedLatencyUploadMs: Double?
    /// Coeficiente de variação da vazão de download (desvio padrão relativo
    /// à média, janela estável) — issue #52. Propriedade motor-interna
    /// nesta primeira entrega, não faz parte do contrato canônico
    /// `NetworkMeasurement`. `nil` quando não há amostras suficientes.
    public var downloadThroughputVariation: Double?
    /// Mesma medida de `downloadThroughputVariation`, para a fase de upload.
    public var uploadThroughputVariation: Double?
    /// Motivo tipado de falha fatal (issue #66) — não-`nil` somente quando
    /// `phase == .error`. Só fato, sem copy: mensagem amigável é decisão da
    /// UI (ver `EngineFailureReason`).
    public var failureReason: EngineFailureReason?
    
    public var location: (latitude: Double, longitude: Double)?

    public init(ping: Double? = nil, jitter: Double? = nil, packetLossPercent: Double? = nil, downloadSpeed: Double? = nil, uploadSpeed: Double? = nil, progress: Double = 0.0, phase: Phase = .idle, provider: String? = nil, networkType: String? = nil, duration: Double? = nil, loadedLatencyMs: Double? = nil, loadedLatencyUploadMs: Double? = nil, downloadThroughputVariation: Double? = nil, uploadThroughputVariation: Double? = nil, failureReason: EngineFailureReason? = nil, location: (latitude: Double, longitude: Double)? = nil) {
        self.ping = ping
        self.jitter = jitter
        self.packetLossPercent = packetLossPercent
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.progress = progress
        self.phase = phase
        self.provider = provider
        self.networkType = networkType
        self.duration = duration
        self.loadedLatencyMs = loadedLatencyMs
        self.loadedLatencyUploadMs = loadedLatencyUploadMs
        self.downloadThroughputVariation = downloadThroughputVariation
        self.uploadThroughputVariation = uploadThroughputVariation
        self.failureReason = failureReason
        self.location = location
    }
}
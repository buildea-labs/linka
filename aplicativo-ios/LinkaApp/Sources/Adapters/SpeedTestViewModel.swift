import Foundation
import Combine
import Network
import LinkaEngine
import MeasurementHistory
import NetworkCore

public enum SpeedTestUIPhase {
    case idle
    case connecting
    case downloading
    case uploading
    case done
    /// Falha fatal do motor (issue #66) — motor parou e cancelou sozinho.
    /// Copy e ação de "Tentar novamente" vivem só na UI (`MainView`); aqui é
    /// só o estado.
    case error
}

@MainActor
public class SpeedTestViewModel: ObservableObject {
    @Published public var isTesting: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var downloadSpeed: Double = 0.0
    @Published public var uploadSpeed: Double = 0.0
    @Published public var ping: Int = 0
    @Published public var jitter: Double = 0.0
    @Published public var provider: String = ""
    @Published public var networkType: String = ""
    @Published public var testDuration: String = ""
    @Published public var packetLossPercent: Double? = nil
    @Published public var uiPhase: SpeedTestUIPhase = .idle
    /// Fato tipado da falha fatal (issue #66) — não-`nil` só quando
    /// `uiPhase == .error`. Mapeamento pra mensagem amigável vive só na UI.
    @Published public var failureReason: EngineFailureReason? = nil

    /// Tipo real de interface de rede usado no teste (issue #51) — Wi-Fi,
    /// rede móvel, Ethernet ou outra. Amostrado de forma independente do
    /// motor (`NWPathMonitor` próprio, fora de `SpeedTestCore`) no início e
    /// no fim do teste; se a interface mudar no meio do caminho, fica
    /// `nil` em vez de afirmar um tipo que não valeu para o teste inteiro.
    /// Fonte única para `MainView` e para o que é salvo no histórico —
    /// evita a divergência que existia entre os dois lugares que derivavam
    /// isso de `networkType` (string legada de exibição, não removida).
    @Published public var connectionKind: NetworkConnectionKind? = nil

    /// Banda Wi-Fi confirmada pelo sistema em GHz (issue #51) — só
    /// preenchida quando `connectionKind == .wifi` e a plataforma
    /// realmente informa (CoreWLAN no Mac). `nil` é estado normal no
    /// iPhone e sempre que a rede mudou durante o teste.
    @Published public var wifiBandGHz: Double? = nil

    /// Latência sob carga (issue #52). Não é `@Published` de propósito: não
    /// deve disparar re-render nenhum, para não competir com o resultado
    /// (AGENTS.md §6). Leitura pública (issue #53) para que `MainView` possa
    /// ler o valor já calculado no momento em que monta `DetailsDisclosure`
    /// (teste já concluído, `uiPhase == .done`) — escrita continua só interna
    /// a esta classe.
    public private(set) var loadedLatencyMs: Double? = nil

    /// Duração bruta do teste em segundos (issue #50), do jeito que o motor
    /// entrega em `MeasurementState.duration` — mesmo padrão de
    /// `loadedLatencyMs`: não-`@Published` para não competir com o
    /// resultado por re-render. `testDuration` (string formatada) já existe
    /// só para exibição ao vivo; este valor bruto é o que alimenta
    /// `NetworkMeasurement.durationMs` no registro salvo, convertido para
    /// milissegundos só no momento da construção final.
    private var rawTestDuration: Double? = nil

    @Published public var lastTestSpeedString: String? = nil
    
    // UI states
    @Published public var showPurchase: Bool = false
    
    private let engine = SpeedTestCore()
    private var testTask: Task<Void, Never>?
    
    public init() {
        loadLastTest()
    }
    
    public func loadLastTest() {
        Task { @MainActor in
            let repository = FileMeasurementHistoryRepository(
                fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json")
            )
            if let count = try? await repository.totalCount(), count > 0 {
                let query = MeasurementQuery(limit: 1, sortOrder: .newestFirst)
                let results = try? await repository.measurements(matching: query)
                if let last = results?.first, let dl = last.downloadMbps {
                    let formattedSpeed = String(format: "%.1f", dl).replacingOccurrences(of: ".", with: ",")
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "pt_BR")
                    if Calendar.current.isDateInToday(last.measuredAt) {
                        self.lastTestSpeedString = "\(formattedSpeed) Mbps · Hoje"
                    } else {
                        formatter.dateFormat = "dd/MM"
                        self.lastTestSpeedString = "\(formattedSpeed) Mbps · \(formatter.string(from: last.measuredAt))"
                    }
                }
            }
        }
    }
    
    public func startTest() {
        guard !isTesting else { return }
        isTesting = true
        progress = 0.0
        downloadSpeed = 0.0
        uploadSpeed = 0.0
        ping = 0
        jitter = 0.0
        provider = ""
        networkType = ""
        testDuration = ""
        loadedLatencyMs = nil
        rawTestDuration = nil
        failureReason = nil
        connectionKind = nil
        wifiBandGHz = nil
        uiPhase = .connecting

        testTask?.cancel()
        testTask = Task {
            // Amostra o tipo de interface no início do teste, em paralelo à
            // subida do motor (não soma latência) — independente do
            // `NWPathMonitor` interno de `SpeedTestCore` (issue #51).
            async let startingKindTask = Self.sampleConnectionKind()

            do {
                var lastUpdateTime = Date()

                for try await state in await engine.runTest() {
                    let now = Date()
                    // Throttle updates to ~30fps
                    if now.timeIntervalSince(lastUpdateTime) >= 0.033 || state.progress >= 1.0 || state.progress == 0.0 {
                        self.update(with: state)
                        lastUpdateTime = now
                    }
                }

                if self.uiPhase == .done {
                    // Amostra de novo ao final. Se a interface mudou no
                    // meio do teste (ex.: Wi-Fi → rede móvel), o teste não
                    // rodou inteiro numa única rede — não afirma nenhum
                    // tipo específico nesse caso (nil é o estado neutro).
                    let startingKind = await startingKindTask
                    let endingKind = await Self.sampleConnectionKind()

                    self.connectionKind = NetworkConnectionKind.resolve(start: startingKind, end: endingKind)
                    self.wifiBandGHz = self.connectionKind == .wifi
                        ? ApplePlatformSignalProvider.currentWifiBandGHz()
                        : nil

                    let m = NetworkMeasurement(
                        outcome: .complete,
                        downloadMbps: self.downloadSpeed,
                        uploadMbps: self.uploadSpeed,
                        latencyMs: Double(self.ping),
                        jitterMs: self.jitter,
                        packetLossPercent: self.packetLossPercent,
                        loadedLatencyMs: self.loadedLatencyMs,
                        durationMs: self.rawTestDuration.map { Int(($0 * 1000).rounded()) },
                        connectionKind: self.connectionKind,
                        wifiBandGHz: self.wifiBandGHz,
                        networkIdentifier: self.provider
                    )
                    let repo = FileMeasurementHistoryRepository(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("measurements.json"))
                    try? await repo.save(m)
                    self.loadLastTest()
                }
                
                self.isTesting = false
            } catch {
                self.isTesting = false
            }
        }
    }
    
    public func stopTest() {
        testTask?.cancel()
        isTesting = false
        uiPhase = .idle
    }
    
    private func update(with state: MeasurementState) {
        self.progress = state.progress
        if let p = state.ping { self.ping = Int(p) }
        if let j = state.jitter { self.jitter = j }
        if let d = state.downloadSpeed { self.downloadSpeed = d }
        if let u = state.uploadSpeed { self.uploadSpeed = u }
        if let prov = state.provider { self.provider = prov }
        if let net = state.networkType { self.networkType = net }
        if let dur = state.duration {
            self.testDuration = String(format: "%.1fs", dur).replacingOccurrences(of: ".", with: ",")
            self.rawTestDuration = dur
        }
        if let loss = state.packetLossPercent { self.packetLossPercent = loss }
        if let loadedLatency = state.loadedLatencyMs { self.loadedLatencyMs = loadedLatency }
        if let reason = state.failureReason { self.failureReason = reason }

        switch state.phase {
        case .idle: self.uiPhase = .idle
        case .ping: self.uiPhase = .connecting
        case .download: self.uiPhase = .downloading
        case .upload: self.uiPhase = .uploading
        case .result: self.uiPhase = .done
        case .error: self.uiPhase = .error
        }
    }

    /// Amostra pontual e independente do tipo de interface de rede ativa
    /// no momento da chamada, via um `NWPathMonitor` próprio deste ponto —
    /// nunca lê estado interno do `NWPathMonitor` de `SpeedTestCore`
    /// (issue #51; motor fica intocado, ver AGENTS.md §8 e issue #66 em
    /// paralelo). Chamada no início e no fim do teste para detectar troca
    /// de rede no meio do caminho.
    private static func sampleConnectionKind() async -> NetworkConnectionKind {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.linka.speedtest.viewmodel.interface-sample")
        monitor.start(queue: queue)

        // Mesma folga que `SpeedTestCore` usa para dar tempo do
        // `NWPathMonitor` buscar o caminho inicial antes da leitura.
        try? await Task.sleep(nanoseconds: 100_000_000)

        let path = monitor.currentPath
        monitor.cancel()

        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else {
            return .other
        }
    }
}

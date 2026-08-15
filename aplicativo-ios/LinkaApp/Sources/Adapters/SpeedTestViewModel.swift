import Foundation
import Combine
import Network
import LinkaEngine
import MeasurementHistory
import NetworkCore
import LinkaEntitlements
import LinkaModules

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

    /// Instância própria (não compartilhada com `MainView`/`SettingsSheet`,
    /// que recebem a delas via `@EnvironmentObject`) só para decidir se a
    /// sincronização CloudKit do histórico está liberada (capability
    /// `.history`, issue #71). `SpeedTestViewModel` não tem acesso direto
    /// ao `StoreKitEntitlementProvider` do ambiente SwiftUI — não é uma
    /// `View` — e mudar isso exigiria tocar `MainView.swift`, fora do
    /// escopo desta issue. O snapshot de entitlement é derivado da mesma
    /// fonte (StoreKit/`UserDefaults`) então converge para o mesmo estado;
    /// o custo é uma segunda instância de observador de transações em
    /// memória, não uma decisão de acesso divergente.
    private let historySyncEntitlements = StoreKitEntitlementProvider()

    /// Geração monotônica da task de teste atual (issue #47, rodada 3 —
    /// achado de Marcelo). `Task<Void, Never>` não é `Equatable`, então não
    /// dá pra comparar identidade de task diretamente; um contador simples
    /// resolve o mesmo problema. Incrementado sincronamente no início de
    /// `startTest()`, antes da nova `Task` ser criada — cada execução
    /// captura o valor da geração que lhe pertence (`myGeneration`) e só
    /// aplica seu próprio cleanup (`isTesting = false`, etc.) se a geração
    /// ainda for a corrente quando ela terminar. Cobre a corrida: T1 é
    /// cancelada por `skipOrCancel()`, que (sem snapshot pra restaurar)
    /// chama `startTest()` de novo sincronamente — isso já criou T2 e
    /// avançado a geração antes de T1 perceber o cancelamento no próprio
    /// loop. Sem esta guarda, o `catch` de T1 fazia `self.isTesting = false`
    /// incondicionalmente, sobrescrevendo o `true` que T2 acabou de setar;
    /// se o usuário navegasse Histórico→voltar nesse instante, `.onAppear`
    /// via `isTesting == false` e chamava `startTest()` de novo, criando T3
    /// e cancelando T2 sem pedido do usuário.
    private var testGeneration: Int = 0

    /// Snapshot do último resultado `.done` alcançado nesta sessão do view
    /// model (issue #47) — capturado em `startTest()` no instante em que um
    /// teste chega a `.done`, antes que um `startTest()` seguinte zere os
    /// campos `@Published` no próprio início. É a fonte usada por
    /// `skipOrCancel()` pra restaurar a tela de resultado integralmente
    /// (todos os campos, não só a velocidade de download) sem round-trip ao
    /// histórico em disco.
    private struct ResultSnapshot {
        let downloadSpeed: Double
        let uploadSpeed: Double
        let ping: Int
        let jitter: Double
        let provider: String
        let networkType: String
        let testDuration: String
        let packetLossPercent: Double?
        let connectionKind: NetworkConnectionKind?
        let wifiBandGHz: Double?
    }

    private var lastValidResultSnapshot: ResultSnapshot?

    /// Verdadeiro quando existe, nesta sessão, um resultado válido pra
    /// restaurar (issue #47). A UI usa isto só pra escolher o texto do
    /// botão de saída ("Pular" quando ainda não há resultado vs. "Cancelar"
    /// quando há um reteste em andamento) — a ação por trás dos dois é
    /// sempre `skipOrCancel()`, nunca dois mecanismos distintos.
    public var hasValidResult: Bool {
        lastValidResultSnapshot != nil
    }

    public init() {
        loadLastTest()
    }

    public func loadLastTest() {
        Task { @MainActor in
            let repository = LinkaMeasurementHistory.makeRepository(entitlements: historySyncEntitlements)
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
        testGeneration += 1
        let myGeneration = testGeneration
        testTask = Task {
            // Amostra o tipo de interface no início do teste, em paralelo à
            // subida do motor (não soma latência) — independente do
            // `NWPathMonitor` interno de `SpeedTestCore` (issue #51).
            async let startingKindTask = Self.sampleConnectionKind()

            do {
                var lastUpdateTime = Date()

                for try await state in await engine.runTest() {
                    // Checa cancelamento a cada yield (issue #47, rodada 2):
                    // sem isto, uma `skipOrCancel()` que chegue entre dois
                    // yields do motor só é percebida no próximo `state`, em
                    // vez de interromper o consumo imediatamente — agora que
                    // `SpeedTestCore.runTest()` cancela o próprio Task
                    // interno via `continuation.onTermination`, este loop
                    // também precisa parar de consumir assim que percebe.
                    try Task.checkCancellation()

                    let now = Date()
                    // Throttle updates to ~30fps
                    if now.timeIntervalSince(lastUpdateTime) >= 0.033 || state.progress >= 1.0 || state.progress == 0.0 {
                        self.update(with: state)
                        lastUpdateTime = now
                    }
                }

                // Guarda por geração (issue #47, rodada 3): se outra
                // `startTest()` já avançou `testGeneration` — via
                // `skipOrCancel()` reiniciando o loop sem snapshot pra
                // restaurar —, esta execução (T1) não é mais a corrente e
                // não deve tocar nenhum `@Published` nem salvar no
                // histórico por baixo de T2.
                guard self.testGeneration == myGeneration else { return }

                // `!Task.isCancelled` além do `uiPhase == .done` (issue #47):
                // `skipOrCancel()` chama `testTask?.cancel()` antes de
                // qualquer outra coisa, então essa checagem cobre até a
                // corrida rara em que o resultado final chegou bem no
                // instante do cancelamento — um teste interrompido nunca
                // vira snapshot válido nem entra no histórico.
                if self.uiPhase == .done && !Task.isCancelled {
                    // Amostra de novo ao final. Se a interface mudou no
                    // meio do teste (ex.: Wi-Fi → rede móvel), o teste não
                    // rodou inteiro numa única rede — não afirma nenhum
                    // tipo específico nesse caso (nil é o estado neutro).
                    let startingKind = await startingKindTask
                    let endingKind = await Self.sampleConnectionKind()

                    // Re-checa a geração depois dos dois `await` acima
                    // (issue #47, rodada 3): a amostragem final leva ~100ms,
                    // tempo suficiente pra um `skipOrCancel()` cancelar T1 e
                    // iniciar T2 no meio do caminho. Sem isto, T1 ainda
                    // gravaria snapshot/histórico por baixo do teste que já
                    // está em andamento.
                    guard self.testGeneration == myGeneration else { return }

                    self.connectionKind = NetworkConnectionKind.resolve(start: startingKind, end: endingKind)
                    self.wifiBandGHz = self.connectionKind == .wifi
                        ? ApplePlatformSignalProvider.currentWifiBandGHz()
                        : nil

                    self.lastValidResultSnapshot = ResultSnapshot(
                        downloadSpeed: self.downloadSpeed,
                        uploadSpeed: self.uploadSpeed,
                        ping: self.ping,
                        jitter: self.jitter,
                        provider: self.provider,
                        networkType: self.networkType,
                        testDuration: self.testDuration,
                        packetLossPercent: self.packetLossPercent,
                        connectionKind: self.connectionKind,
                        wifiBandGHz: self.wifiBandGHz
                    )

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
                    let repo = LinkaMeasurementHistory.makeRepository(entitlements: historySyncEntitlements)
                    try? await repo.save(m)
                    self.loadLastTest()
                }
                
                self.isTesting = false
            } catch {
                // Mesma guarda por geração do caminho de sucesso acima: uma
                // T1 cancelada que só percebe isso aqui (via
                // `Task.checkCancellation()` dentro do loop) não pode
                // sobrescrever `isTesting`/`uiPhase` de uma T2 que já está
                // rodando (issue #47, rodada 3 — achado de Marcelo).
                guard self.testGeneration == myGeneration else { return }
                self.isTesting = false
            }
        }
    }
    
    /// Único mecanismo técnico pra interromper um teste em andamento
    /// (issue #47) — "Pular" na primeira medição automática e "Cancelar"
    /// num reteste chamam sempre este mesmo método, nunca dois handlers
    /// separados. Cancela a task/stream do motor e nunca deixa o teste
    /// interrompido entrar no histórico (ver guarda `!Task.isCancelled` em
    /// `startTest()`). Restaura integralmente o último resultado válido
    /// desta sessão quando existir ("Cancelar"); senão reinicia um teste
    /// novo automaticamente ("Pular" — bug reportado por Marcelo na rodada
    /// 2 do PR #91: sem um snapshot pra restaurar, `uiPhase = .idle` sozinho
    /// é beco sem saída, porque nenhum botão em `MainView` no branch
    /// `.idle` chama `startTest()`; "Pular" sem resultado precisa, ele
    /// mesmo, reiniciar o loop natural do produto).
    public func skipOrCancel() {
        testTask?.cancel()
        testTask = nil

        failureReason = nil
        isTesting = false

        if let snapshot = lastValidResultSnapshot {
            downloadSpeed = snapshot.downloadSpeed
            uploadSpeed = snapshot.uploadSpeed
            ping = snapshot.ping
            jitter = snapshot.jitter
            provider = snapshot.provider
            networkType = snapshot.networkType
            testDuration = snapshot.testDuration
            packetLossPercent = snapshot.packetLossPercent
            connectionKind = snapshot.connectionKind
            wifiBandGHz = snapshot.wifiBandGHz
            progress = 1.0
            uiPhase = .done
        } else {
            startTest()
        }
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

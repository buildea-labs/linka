// Justificativa de Arquitetura (validarModularidade):
// Este arquivo gerencia o ciclo de vida e a coordenação entre o motor (LinkaEngine) e a UI de medição.
// Fica coeso manter as conversões de publish em um só lugar para garantir transições atômicas de UI.
import Foundation
import Combine
import Network
import SwiftUI
import WidgetKit
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
    /// Acesso `internal` (não `private`) de propósito (issue #65): permite
    /// que `@testable import LinkaApp` semeie um snapshot em teste sem
    /// depender de uma medição de rede real completa — não é API pública do
    /// módulo, só visível dentro do target do app e de quem importa com
    /// `@testable`.
    struct ResultSnapshot {
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

    /// Mesmo racional de acesso `internal` de `ResultSnapshot` acima
    /// (issue #65) — testável via `@testable import` sem expor API pública.
    var lastValidResultSnapshot: ResultSnapshot?

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

                    // Hidrata snapshot em memória a partir da última medição
                    // persistida — Pular passa a restaurar o último resultado
                    // (mesmo de sessão anterior), não só quando o usuário mede
                    // dentro desta sessão. Sem isto, o usuário perde a
                    // referência do último teste entre relançamentos do app.
                    if self.lastValidResultSnapshot == nil && self.uiPhase == .idle {
                        self.loadHistoricalResult(last)
                    }
                }
            } else {
                if self.uiPhase == .idle {
                    self.startTest()
                }
            }
        }
    }

    public func loadHistoricalResult(_ measurement: NetworkMeasurement) {
        self.downloadSpeed = measurement.downloadMbps ?? 0.0
        self.uploadSpeed = measurement.uploadMbps ?? 0.0
        self.ping = Int((measurement.latencyMs ?? 0).rounded())
        self.jitter = measurement.jitterMs ?? 0.0
        self.provider = measurement.networkIdentifier ?? ""
        self.networkType = measurement.connectionKind?.rawValue ?? ""
        if let dur = measurement.durationMs {
            self.rawTestDuration = Double(dur) / 1000.0
            self.testDuration = String(format: "%.1fs", self.rawTestDuration!).replacingOccurrences(of: ".", with: ",")
        } else {
            self.rawTestDuration = nil
            self.testDuration = ""
        }
        self.packetLossPercent = measurement.packetLossPercent
        self.loadedLatencyMs = measurement.loadedLatencyMs
        self.connectionKind = measurement.connectionKind
        self.wifiBandGHz = measurement.wifiBandGHz
        
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
        
        self.progress = 1.0
        self.uiPhase = .done
        self.isTesting = false
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
                        if state.phase == .result {
                            // Fase terminal (sempre o último valor yield do
                            // motor, sempre com progress = 1.0, então nunca
                            // é pulado pelo throttle acima — ver
                            // SpeedTestCore.swift linhas ~308-313). Resolve
                            // connectionKind/wifiBandGHz finais ANTES de
                            // publicar `uiPhase = .done` (issue #88): antes,
                            // essa amostragem só acontecia DEPOIS que o loop
                            // terminava, ou seja, depois de `.done` já ter
                            // sido publicado num frame anterior — abrindo uma
                            // janela de ~100-200ms em que a UI via `.done`
                            // com os campos ainda `nil`. Se a interface mudou
                            // no meio do teste (ex.: Wi-Fi → rede móvel), o
                            // teste não rodou inteiro numa única rede — não
                            // afirma nenhum tipo específico nesse caso (nil
                            // continua sendo o estado neutro).
                            let startingKind = await startingKindTask
                            let endingKind = await Self.sampleConnectionKind()
                            self.processResultState(
                                state,
                                startingKind: startingKind,
                                endingKind: endingKind,
                                generation: myGeneration
                            )
                        } else {
                            self.update(with: state)
                        }
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
                    do {
                        try await repo.save(m)
                    } catch {
                        // Falha ao salvar no histórico não derruba o fluxo de medição.
                    }
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
            // Reteste cancelado: restaura o último resultado válido — usuário
            // volta a ver exatamente o que estava vendo antes de tocar em
            // "Testar novamente".
            restoreLastValidSnapshot(snapshot)
        } else {
            // Primeira medição pulada: sem snapshot para restaurar, volta ao
            // estado pronto-para-medir. Não fabrica valores zerados (issue #47
            // aceite: "sem resultado anterior, a interface não fabrica valores").
            // A saída do beco sem saída fica na UI: MainView mostra um botão
            // "Testar" quando uiPhase == .idle e não há resultado — o
            // auto-restart do R3 confundia o usuário ("botão Pular não faz
            // nada porque o teste reinicia imediatamente").
            progress = 0.0
            uiPhase = .idle
        }
    }

    /// Reage à mudança de `ScenePhase` da cena (issue #65) — único ponto de
    /// decisão de ciclo de vida do teste; `MainView` só repassa o valor via
    /// `.onChange(of: scenePhase)`, sem lógica própria aqui.
    ///
    /// Reage só à transição para `.background`, nunca a `.inactive`:
    /// `.inactive` também dispara em blips transitórios que não devem
    /// cancelar nada (sheet de compartilhamento, prompt de permissão,
    /// interstitial de anúncio, Control Center) — reagir a `.inactive`
    /// cancelaria testes por engano nesses casos.
    ///
    /// Decisão de produto (issue #65): PAUSAR não é opção real aqui.
    /// `SpeedTestCore.runTest()` usa `URLSessionConfiguration.ephemeral`,
    /// sem `URLSessionConfiguration.background`, `BGTaskScheduler` ou
    /// `UIBackgroundModes` (Info.plist protegido, ver AGENTS.md) —
    /// iOS/iPadOS suspendem essas conexões assim que o processo entra em
    /// background, então não há como retomar de forma confiável um
    /// download/upload em andamento. A única reação correta é cancelar de
    /// forma limpa, nunca prometer conclusão silenciosa em segundo plano.
    ///
    /// No Mac, `ScenePhase.background` pode nunca disparar em uso normal de
    /// janela (perder foco, ocultar com Cmd+H, minimizar não necessariamente
    /// suspendem o processo como no iOS) — comportamento observado
    /// documentado no PR desta issue, não afirmado como testado ao vivo.
    public func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Só age em cima de uma medição em andamento — `.done`/`.error`
            // já são estados terminais e não têm nada pra cancelar; agir
            // ali arriscaria sobrescrever um resultado que já passou por
            // `phase == .result` no motor (requisito de aceite #2).
            guard uiPhase == .connecting || uiPhase == .downloading || uiPhase == .uploading else {
                return
            }

            // Mecanismo de cancelamento já existe e já funciona
            // (`SpeedTestCore.runTest()` propaga cancelamento via
            // `continuation.onTermination`, libera `session
            // .invalidateAndCancel()` e cancela `workersTask`/
            // `latencySamplingTask`) — este handler só aciona o gatilho que
            // faltava, não reimplementa nada do motor (AGENTS.md §8).
            testTask?.cancel()
            testTask = nil
            failureReason = nil
            isTesting = false

            // Não incrementa `testGeneration` nem chama `startTest()` aqui
            // (issue #47, rodada 3 — reintroduziria a mesma classe de
            // corrida que aquela issue já resolveu). Disparar rede
            // enquanto o app está indo para background não tem sentido
            // (seria cancelado de novo no instante seguinte) e contradiz
            // "nenhuma promessa de conclusão em segundo plano". O reinício,
            // quando fizer sentido, só acontece na volta a `.active`.
            if let snapshot = lastValidResultSnapshot {
                restoreLastValidSnapshot(snapshot)
            } else {
                progress = 0.0
                uiPhase = .idle
            }

        case .active:
            // Só reinicia quando `uiPhase` ficou `.idle` pelo branch acima:
            // depois do primeiro `startTest()` em `MainView.onAppear`, o
            // app nunca mais fica `.idle` sozinho por nenhum outro caminho,
            // então este sinal é inequívoco. Resume "ABRIR → MEDIR"
            // automático (AGENTS.md §6) sem nenhum banner/copy extra de
            // "medição interrompida" — o próprio reinício já comunica o
            // estado sem fricção adicional.
            if uiPhase == .idle {
                startTest()
            }

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    /// Restaura os campos de exibição a partir do último resultado válido
    /// desta sessão (issue #47, extraído em #65 para ser compartilhado
    /// entre `skipOrCancel()` e `handleScenePhaseChange()` sem duplicar os
    /// mesmos ~10 campos nos dois lugares). Não mexe em `isTesting`,
    /// `failureReason` ou `testTask` — quem chama é responsável por esses
    /// campos antes/depois, já que os dois fluxos que usam isto (cancelamento
    /// explícito do usuário vs. backgrounding) tratam esses três campos de
    /// forma ligeiramente diferente.
    private func restoreLastValidSnapshot(_ snapshot: ResultSnapshot) {
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
    }

    /// Processa o state terminal do motor (`phase == .result`, issue #88):
    /// resolve `connectionKind`/`wifiBandGHz` finais (só quando `generation`
    /// ainda é a geração corrente — mesma guarda de sempre contra um
    /// `skipOrCancel()`/novo `startTest()` que avance `testGeneration`
    /// durante os ~100ms de amostragem final) e SÓ DEPOIS publica o state
    /// via `update(with:)` — é essa chamada que marca `uiPhase = .done`.
    /// Extraído num método próprio, com acesso `internal` (mesmo padrão de
    /// `ResultSnapshot`/`lastValidResultSnapshot` acima), pra ser testável
    /// via `@testable import` sem depender de uma medição de rede real
    /// completa (`engine` não é injetável).
    ///
    /// `NetworkConnectionKind.resolve(start:end:)` continua a única fonte
    /// que decide `connectionKind` — nenhuma lógica duplicada aqui.
    func processResultState(
        _ state: MeasurementState,
        startingKind: NetworkConnectionKind,
        endingKind: NetworkConnectionKind,
        generation: Int
    ) {
        if self.testGeneration == generation {
            self.connectionKind = NetworkConnectionKind.resolve(start: startingKind, end: endingKind)
            self.wifiBandGHz = self.connectionKind == .wifi
                ? ApplePlatformSignalProvider.currentWifiBandGHz()
                : nil
        }
        self.update(with: state)
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

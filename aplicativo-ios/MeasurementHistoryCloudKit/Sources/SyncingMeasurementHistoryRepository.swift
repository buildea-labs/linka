import Foundation
import CloudKit
import NetworkCore
import MeasurementHistory

/// Decorator de `MeasurementHistoryRepository` que espelha o histórico
/// local para a private database do CloudKit do usuário, em segundo plano
/// (issue #71).
///
/// Regras estruturais que este tipo preserva:
/// - **Local-first sempre.** Todo método de leitura/escrita delega
///   primeiro (e só) ao repositório local injetado — `save`/`delete`
///   retornam assim que a gravação local termina; o push remoto acontece
///   numa `Task` separada, nunca aguardada pelo chamador. O SpeedTest nunca
///   fica mais lento nem depende de rede/iCloud por causa do sync.
/// - **iCloud é sempre opcional.** Qualquer falha de rede, conta não
///   logada, container não provisionado ou erro do CloudKit é engolido
///   (best-effort) — nunca propaga como erro para quem chama `save`,
///   `delete` ou as leituras, e nunca impede o uso do histórico local já
///   disponível.
/// - **Idempotência.** `id: UUID` vira `CKRecord.recordID.recordName`
///   (`MeasurementRecordMapper`), então reenviar a mesma medição faz upsert
///   pelo mesmo recordID — nunca duplica.
/// - **Exclusão é propagada nas duas direções.** Apagar localmente
///   enfileira a exclusão do `CKRecord` correspondente; um `CKRecord`
///   reportado como apagado por outro dispositivo (via
///   `fetchChanges`/`deletions`) apaga a medição local correspondente.
/// - **Conflito é resolvido de forma determinística** por
///   `MeasurementConflictResolver`, nunca descartando dados silenciosamente.
/// - **Não reimplementa checagem de plano.** `isSyncPermitted` é injetado
///   de fora (tipicamente amarrado a `LinkaEntitlementPolicy`/capability
///   `.history`, já responsável por gatear a superfície de Histórico) — este
///   tipo não conhece `LinkaEntitlements` para não acoplar o pacote de
///   CloudKit ao pacote de entitlement.
public actor SyncingMeasurementHistoryRepository: MeasurementHistoryRepository {
    private let local: any MeasurementHistoryRepository
    private let remote: any MeasurementRemoteStore
    private let tokenStore: any MeasurementSyncChangeTokenStore
    private let isSyncPermitted: @Sendable () async -> Bool

    private var zoneEnsured = false
    /// Melhor esforço de "quando esta medição foi tocada localmente pela
    /// última vez", usado só como critério de desempate determinístico em
    /// `MeasurementConflictResolver` quando outcome e contagem de campos
    /// não-nil empatam. Efêmero (não persistido): não é um requisito do
    /// aceite, só evita favorecer sempre o remoto nesse empate raro.
    private var localTouchDates: [UUID: Date] = [:]

    /// Hook de teste: guarda a `Task` da sync em segundo plano mais recente
    /// (disparada por `init`, `save`, `delete` ou `deleteAll`) para que
    /// `waitForBackgroundSync()` possa esperar por ela de forma
    /// determinística. Produção nunca lê isto — `save`/`delete`/`deleteAll`
    /// continuam retornando antes de qualquer chamada de rede.
    private var backgroundSyncTask: Task<Void, Never>?

    public init(
        local: any MeasurementHistoryRepository,
        remote: any MeasurementRemoteStore,
        tokenStore: any MeasurementSyncChangeTokenStore = UserDefaultsChangeTokenStore(),
        isSyncPermitted: @escaping @Sendable () async -> Bool = { true }
    ) {
        self.local = local
        self.remote = remote
        self.tokenStore = tokenStore
        self.isSyncPermitted = isSyncPermitted

        // Atribuição direta (não via `kickOffBackgroundSync`) de propósito:
        // criar a `Task` é síncrono, então `backgroundSyncTask` já está
        // preenchido antes do `init` retornar — sem essa garantia,
        // `waitForBackgroundSync()` chamado logo após a construção teria
        // uma corrida real contra este `init` para ver quem escreve a
        // propriedade primeiro.
        //
        // Gera warning "nonisolated initializer" em modo Swift 6 estrito
        // (não usado hoje em nenhum pacote deste repo — todos em
        // swift-tools-version 5.9 sem `swiftLanguageMode`): formar a
        // `Task` acima faz `self` "escapar" do init antes desta escrita.
        // Inofensivo no modo de linguagem atual do projeto; revisar se o
        // repo adotar Swift 6 estrito no futuro.
        backgroundSyncTask = Task {
            await self.syncNow()
        }
    }

    // MARK: - MeasurementHistoryRepository

    public func save(_ measurement: NetworkMeasurement) async throws {
        try await local.save(measurement)
        localTouchDates[measurement.id] = Date()

        kickOffBackgroundSync { await $0.pushRemote(measurement) }
    }

    public func measurement(id: UUID) async throws -> NetworkMeasurement? {
        try await local.measurement(id: id)
    }

    public func measurements(matching query: MeasurementQuery) async throws -> [NetworkMeasurement] {
        try await local.measurements(matching: query)
    }

    public func totalCount() async throws -> Int {
        try await local.totalCount()
    }

    public func delete(id: UUID) async throws {
        try await local.delete(id: id)
        localTouchDates[id] = nil

        kickOffBackgroundSync { await $0.pushRemoteDelete(ids: [id]) }
    }

    public func deleteAll() async throws {
        // Precisamos saber quais IDs existiam antes de apagar localmente
        // para propagar a exclusão de cada um deles — apagar sem propagar
        // deixaria o histórico "ressuscitar" no próximo pull de outro
        // dispositivo (issue #71, exclusão precisa de comportamento
        // definido entre dispositivos).
        let existingIDs = ((try? await local.measurements(matching: .all)) ?? []).map(\.id)
        try await local.deleteAll()
        localTouchDates.removeAll()

        kickOffBackgroundSync { await $0.pushRemoteDelete(ids: existingIDs) }
    }

    // MARK: - Sync em segundo plano

    /// Ponto de entrada público de sync: pensado para ser chamado quando o
    /// app volta a ficar ativo (ex.: `scenePhase == .active`), além de ser
    /// disparado automaticamente (fire-and-forget) no `init`. Faz, nesta
    /// ordem:
    ///
    /// 1. **Pull** — busca mudanças remotas desde o último `changeToken`
    ///    (novas medições de outros dispositivos, exclusões remotas,
    ///    conflitos resolvidos por `MeasurementConflictResolver`).
    /// 2. **Push de reconciliação** — reenvia todas as medições locais
    ///    atuais para o CloudKit. Isso é o que garante que uma medição
    ///    salva enquanto offline (ou com o push imediato de `save`
    ///    falhando por qualquer motivo) acabe sincronizada assim que o
    ///    iCloud voltar a ficar disponível — sem depender de manter uma
    ///    fila de pendências separada. O upload é idempotente por
    ///    `recordID` (issue #71): reenviar o que já está sincronizado não
    ///    duplica nada no servidor, só reconfirma o estado.
    ///
    /// Nunca lança: falha de rede, conta iCloud indisponível ou container
    /// não provisionado deixam o histórico local intocado e saem em
    /// silêncio — `save`/leitura continuam funcionando 100% local.
    public func syncNow() async {
        guard await isSyncPermitted() else { return }
        guard await remote.accountStatus() == .available else { return }

        do {
            try await ensureZone()
            try await pullChanges()
            try await pushAllLocalMeasurements()
        } catch {
            // Best-effort — ver documentação do tipo.
        }
    }

    private func pullChanges() async throws {
        let previousToken = await tokenStore.loadToken()
        let changeSet = try await remote.fetchChanges(since: previousToken)

        for record in changeSet.changedRecords {
            guard let remoteMeasurement = MeasurementRecordMapper.measurement(from: record) else { continue }
            await applyRemote(remoteMeasurement, modifiedAt: record.modificationDate)
        }

        for recordID in changeSet.deletedRecordIDs {
            guard let id = UUID(uuidString: recordID.recordName) else { continue }
            try? await local.delete(id: id)
            localTouchDates[id] = nil
        }

        await tokenStore.saveToken(changeSet.newChangeToken)
    }

    private func pushAllLocalMeasurements() async throws {
        let current = try await local.measurements(matching: .all)
        guard !current.isEmpty else { return }
        try await remote.upload(current.map { MeasurementRecordMapper.record(from: $0) })
    }

    private func applyRemote(_ remoteMeasurement: NetworkMeasurement, modifiedAt: Date?) async {
        guard let existingLocal = try? await local.measurement(id: remoteMeasurement.id) else {
            // Primeiro sync desta medição neste dispositivo: grava direto,
            // sem reenfileirar push (já veio do servidor).
            try? await local.save(remoteMeasurement)
            return
        }

        guard existingLocal != remoteMeasurement else { return }

        let resolved = MeasurementConflictResolver.resolve(
            local: existingLocal,
            localModifiedAt: localTouchDates[remoteMeasurement.id],
            remote: remoteMeasurement,
            remoteModifiedAt: modifiedAt
        )

        guard resolved != existingLocal else { return }
        try? await local.save(resolved)
    }

    private func pushRemote(_ measurement: NetworkMeasurement) async {
        guard await isSyncPermitted() else { return }
        guard await remote.accountStatus() == .available else { return }

        do {
            try await ensureZone()
            try await remote.upload([MeasurementRecordMapper.record(from: measurement)])
        } catch {
            // Best-effort — fica para o próximo save ou pull cobrir.
        }
    }

    private func pushRemoteDelete(ids: [UUID]) async {
        guard !ids.isEmpty else { return }
        guard await isSyncPermitted() else { return }
        guard await remote.accountStatus() == .available else { return }

        do {
            try await ensureZone()
            let recordIDs = ids.map { MeasurementRecordMapper.recordID(for: $0) }
            try await remote.deleteRemote(recordIDs: recordIDs)
        } catch {
            // Best-effort — mesma justificativa de pushRemote.
        }
    }

    private func ensureZone() async throws {
        guard !zoneEnsured else { return }
        try await remote.ensureZoneExists()
        zoneEnsured = true
    }

    // MARK: - Agendamento em segundo plano

    @discardableResult
    private func kickOffBackgroundSync(
        _ operation: @escaping @Sendable (SyncingMeasurementHistoryRepository) async -> Void
    ) -> Task<Void, Never> {
        let task = Task { [weak self] in
            guard let self else { return }
            await operation(self)
        }
        backgroundSyncTask = task
        return task
    }

    /// Hook de teste: aguarda a `Task` de sync em segundo plano mais
    /// recentemente enfileirada (por `init`, `save`, `delete` ou
    /// `deleteAll`). Produção nunca precisa chamar isto — só torna o
    /// comportamento assíncrono determinístico nos testes deste pacote.
    public func waitForBackgroundSync() async {
        await backgroundSyncTask?.value
    }
}

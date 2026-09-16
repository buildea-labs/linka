# Architecture Plan — Ambientes de medição Linka+

## Problema e resultado

`NetworkProfile` hoje é unívoco por fingerprint de SSID: dois pontos da mesma
rede disputam o mesmo perfil. Trocar a capacidade visível de **Perfis de
Rede** para **Ambientes**: pontos nomeados manualmente (`Sala`, `Quarto`,
`Escritório`) e suas medições explicitamente escolhidas. A medição e o
resultado continuam sem qualquer pergunta prévia.

Após um resultado Wi-Fi com SSID disponível e Linka+ ativo, Otimização mostra
discretamente “Onde você mediu?”. A pessoa escolhe um ambiente existente ou
cria um; isso associa somente aquela `measurementId`. Ignorar não altera nada,
e a próxima medição pede novamente. Não há dedução de cômodo, seleção do
último ambiente, retroatribuição de histórico ou uso de BSSID/MAC/localização.
Settings só lista, renomeia e exclui Ambientes.

## Decisão técnica e fluxo

Manter o target SwiftPM `NetworkProfiles` nesta entrega para não criar churn de
projeto; seus tipos e UI passam a usar `NetworkEnvironment`/`Environment…`.
Remover da jornada e da persistência novas `NetworkProfileIdentity`, HMAC de
SSID e `profileForCurrentNetwork`. SSID é somente uma pré-condição efêmera no
coordinator para liberar a ação; não atravessa para o repositório.

```text
resultado completo Wi-Fi + SSID + Plus
  -> OptimizationEnvironmentCoordinator.refresh(resultado, histórico)
  -> escolher/criar Ambiente
  -> EnvironmentAssignment(measurementID, environmentID, assignedAt)
  -> baseline/comparação calculada só pelas assignments daquele environmentID
```

- `NetworkEnvironment`: `id: UUID`, `name`, `createdAt`, `updatedAt`; nomes
  não vazios após trim, nomes repetidos permitidos (IDs continuam distintos).
- `EnvironmentMeasurementAssignment`: uma única associação por `measurementID`
  (upsert explícito permite corrigir a escolha enquanto aquele resultado está
  aberto), `environmentID` existente e `assignedAt`. Expor no repositório:
  ambientes ordenados, criar/renomear/remover por `id`, assignment por
  measurement e assignments por ambiente, além de `createAndAssign` para
  criar o ambiente e vincular a leitura num único commit; ao remover ambiente,
  apagar suas assignments no mesmo commit atômico. Nunca alterar
  `NetworkMeasurement` nem `MeasurementHistoryRepository`/CloudKit.
- `NetworkBaselineBuilder` e `NetworkBaselineComparator` em
  `NetworkOptimization` recebem uma identidade opaca agora derivada de
  `environmentID.uuidString`, não do SSID. Elegíveis: completas, Wi-Fi,
  recentes (30 dias) e explicitamente associadas àquele ambiente. Excluir a
  medição atual da baseline; comparação só aparece para a medição atualmente
  associada. Mantém mínimo 3, mediana e métricas ausentes como `nil`.
- `OptimizationProfileCoordinator` vira coordinator de ambientes: carrega
  store + histórico, valida a pré-condição Wi-Fi/SSID e o resultado completo,
  cria/associa atomicamente, recalcula contagens/baselines por UUID e reporta
  erro recuperável de store. A seleção é sempre iniciada pela tela; não guardar
  “ambiente atual” e não chamar associação por refresh.

## Persistência e migração

Evoluir o documento local existente
`Application Support/Linka/network-profiles-v1.json` de schema 1 para schema
2 (o nome interno pode permanecer nesta versão):

```json
{ "schemaVersion": 2, "environments": [...], "assignments": [...] }
```

Ao abrir schema 1, decodificar os `profiles` legados, converter cada um para
ambiente preservando `id`, nome e datas, descartando `identity`,
`referenceStartedAt` e `lastAnalyzedAt`; criar `assignments: []` e gravar o
schema 2 atomicamente. Assim o nome do usuário é preservado, mas nenhuma
referência antiga sobre SSID é apresentada como referência de cômodo. Falha de
decodificação, versão desconhecida ou persistência da migração falha fechada e
preserva o arquivo; a UI oferece tentar de novo. Validar IDs únicos e nenhuma
assignment órfã/duplicada. Não criar segundo arquivo nem migrar o Histórico.

Os ambientes e assignments permanecem locais: não entram no payload de
`NetworkMeasurement`, `MeasurementHistoryCloudKit`, NDS, Assist, telemetria ou
widgets. Exclusão remove somente o ambiente/associações; medições do Histórico
permanecem intactas.

## Superfícies e arquivos

- `NetworkProfiles/Sources/*` e testes: modelos/repositório/store schema 2 e
  migração. Remover dependência de `CryptoKit` e identidade de SSID se ficar
  sem consumidor.
- `LinkaApp/Sources/Adapters/OptimizationProfileCoordinator.swift`: contrato
  acima e estado de elegibilidade/associação atual.
- `LinkaApp/Sources/UI/OptimizationView.swift` e
  `NetworkProfilesSection.swift`: renomear copy e componentes para Ambientes;
  após resultado, seletor com lista + “Novo ambiente”, editor e estado de
  associado. Settings/Mac exibem apenas gestão, sem criação solta.
- `MacMainView.swift` e `SettingsSheet.swift`: preservar as entradas atuais,
  agora rotuladas Ambientes; Mac e iPhone/iPad usam o mesmo fluxo pós-resultado.
- `Resources/{pt-BR,en,es-419}.lproj/Localizable.strings`: todas as novas
  chaves/cópias e acessibilidade. Não deixar `profiles.*` visível ao usuário.
- `NetworkOptimization/Sources/NetworkOptimization.swift` e testes: filtrar
  por association explícita/UUID; não mudar `OptimizationPlanBuilder` que ainda
  trata oportunidades gerais por rede.
- `project.yml`: só regenerar Xcode se a mudança de package/target exigir;
  conferir `xcodebuild -list` após XcodeGen.

## Falhas, privacidade e compatibilidade

Sem Plus, celular, resultado parcial, identificação Wi-Fi desativada ou SSID
ausente: explicar indisponibilidade/prévia e não criar nem associar. Store
corrompido/versão futura: falhar fechado e não sobrescrever. Ambiente apagado
ou assignment que aponta a ambiente inexistente não pode render comparação.
Uma medição podada do Histórico simplesmente deixa de contar. Nenhum SSID,
BSSID/MAC, localização, métricas duplicadas ou segredo vai para o novo schema.

## Testes e aceite

- `NetworkProfiles`: schema 2 round-trip, CRUD por UUID com nomes repetidos,
  associação única/reassign, remoção em cascata, órfã/duplicada, arquivo
  corrompido/futuro, migração schema 1 preservando nomes/IDs e sem assignments;
  inspecionar JSON sem SSID/fingerprint/BSSID/MAC.
- `NetworkOptimization`: três associações do mesmo ambiente formam referência;
  mesma rede sem assignment e outro ambiente não contam; atual é excluída;
  janela/mediana/nil continuam corretos.
- App: iOS/iPad/Mac, Plus vs prévia, criação e escolha após resultado apenas,
  ignorar e próxima leitura sem seleção automática, troca explícita, gestão
  sem criar, exclusão, identificação desligada/SSID ausente/resultado parcial,
  migração e VoiceOver. Validar pt-BR/en/es-419.
- Rodar `swift test` em `NetworkProfiles` e `NetworkOptimization`, testes/build
  do app iOS e build macOS proporcional ao diff. Não declarar dispositivo,
  CI ou publicação sem evidência separada.

## Riscos e não-objetivos

O principal risco é reusar sem perceber a associação antiga baseada em SSID;
os testes de migração e de baseline devem impedir isso. Outra armadilha é
persistir associação junto de `NetworkMeasurement`, o que mudaria CloudKit e
o contrato do motor sem necessidade. Não entram sincronização entre devices,
inferência de localização/cômodo, classificação por AP, histórico retroativo,
monitoramento, DNS/roteador ou mudança do fluxo principal.

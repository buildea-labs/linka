# Histórico de medições — inventário e plano

Status: Fases 0 e 1 implementadas na branch `feat/linka-plus-modules`.

## Decisão

O Histórico não cria um segundo motor de medição. `LinkaEngine` mede; um adapter futuro transforma uma execução aproveitável no contrato canônico `NetworkMeasurement`; o repositório de Histórico apenas persiste e consulta esse contrato.

```text
LinkaEngine -> adapter -> NetworkMeasurement -> HistoryProviding -> storage
```

O contrato contém fatos medidos e proveniência técnica mínima. Diagnóstico, opinião, plano/assinatura, UI, texto de IA, problema relatado e velocidade contratada ficam fora dele.

## Fase 0 — inventário de reuso no Linka

| Código existente | Decisão | Motivo |
| --- | --- | --- |
| `LinkaEngine/Core/MeasurementState.swift` | Adaptar depois | Já expõe ping, jitter, download e upload durante a execução. É estado vivo, não registro persistível. |
| `LinkaEngine/Core/SpeedTestCore.swift` | Reusar como fonte de medição, não alterar nesta fase | O fluxo assíncrono já produz as métricas principais. O jitter atual é simulado (`ping * 0.1`), portanto não deve ser tratado como métrica confiável de histórico até o motor medi-lo de verdade. |
| `LinkaEngine/Core/LinkaEngine.swift` | Não usar para Histórico | É placeholder: usa timer e resultado fixo. Não representa medição real. |
| `LinkaModules/MeasurementSnapshot` | Evoluir | Era o melhor embrião de contrato, mas não tinha versionamento, outcome, jitter, perda, latência sob carga nem duração. Foi substituído por `NetworkMeasurement`, mantendo alias temporário. |
| `HistoryProviding` + `InMemoryHistoryStore` | Reusar na Fase 2 | A abstração e ordenação já servem como base. O store em memória é teste/fundação, não persistência de produto. |
| `BasicInsightProvider` | Reusar depois do Histórico | A comparação determinística consome medições sem diagnosticar causa. Não faz parte da persistência. |
| Linka Web | Adapter futuro | Deve mapear o resultado Web para o mesmo contrato, sem compartilhar implementação de storage com Apple. |

Referências externas podem informar decisões arquiteturais, mas esta implementação não cria dependência de código, build ou runtime com outro produto.

## Dívidas identificadas

1. Existem hoje dois caminhos nominalmente de engine no iOS. `SpeedTestCore` executa requests reais; `LinkaEngine.swift` ainda é placeholder com números fixos. Um adapter de Histórico jamais deve aceitar o placeholder como fonte.
2. `SpeedTestCore` simula jitter. O campo `jitterMs` do contrato é opcional até existir medição real.
3. O contrato já comporta perda de pacotes e latência sob carga, mas esses campos são opcionais: sua presença no schema não significa que o iOS os mede hoje.
4. `InMemoryHistoryStore` não sobrevive ao encerramento do app. Persistência real pertence à Fase 2.

## Fase 1 — contrato canônico

A fonte de verdade no Swift é `NetworkMeasurement`. O schema interoperável está em `documentacao/arquitetura/contratos/network-measurement.schema.json`.

### Regras v1

- `schemaVersion` é `1`.
- `id` identifica a medição; salvar novamente o mesmo id deve ser idempotente no repositório futuro.
- `measuredAt` representa o instante da medição.
- `complete` exige download, upload e latência.
- `partial` exige ao menos uma métrica aproveitável.
- métricas não podem ser negativas ou não finitas.
- perda de pacotes fica entre 0 e 100 quando presente.
- jitter, perda, latência sob carga, duração, tipo de conexão e proveniência são opcionais.
- ausência de um campo opcional significa "não medido/não disponível"; não deve ser convertida em zero.

### O que não pertence ao contrato

- diagnóstico ou causa provável;
- recomendação;
- pergunta/resposta de Assist;
- tier Free/Plus ou entitlement;
- preço/paywall;
- estado de UI, animação ou progresso;
- problema declarado pelo usuário;
- velocidade contratada.

## Fixtures canônicas

- `fixtures/network-measurement-complete-v1.json`: medição completa.
- `fixtures/network-measurement-partial-v1.json`: medição interrompida, mas com latência aproveitável.

Elas documentam o formato que adapters futuros de Web e Apple devem produzir.

## Próximas fases — ainda não implementadas

### Fase 2 — repositório e persistência Apple

- definir queries e política de retenção;
- tornar `HistoryProviding` explicitamente um repository de domínio;
- implementar storage persistente Apple;
- migração/versionamento;
- deduplicação por id;
- testes de reinício, exclusão e corrupção;
- adapter `SpeedTestCore -> NetworkMeasurement` somente após remover/contornar dados simulados.

### Fase 3 — adapter Web

Mapear o resultado real do Linka Web para `NetworkMeasurement` sem alterar seu motor e sem obrigar Apple e Web a usar o mesmo mecanismo de persistência.

### Fase 4 — comparação/Insights

Consolidar regras puras de comparação sobre medições persistidas. Comparação relata diferença observada; não atribui causa.

### Fase 5 — UI

Só depois da persistência e dos contratos passarem pelos gates. Histórico não deve contaminar o fluxo principal `ABRIR -> MEDIR -> RESULTADO -> REPETIR`.

## Gate para avançar

Antes da Fase 2:

1. `swift test` em `aplicativo-ios/LinkaModules` verde;
2. contrato v1 aprovado sem campos de diagnóstico/produto/UI;
3. fixtures decodificáveis de forma determinística;
4. nenhuma alteração de comportamento do SpeedTest;
5. nenhuma dependência nova de outro produto.

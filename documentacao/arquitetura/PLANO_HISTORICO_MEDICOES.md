# Histórico de medições — plano e implementação

Status (atualizado em 2026-09-11): o módulo saiu do isolamento descrito abaixo e está integrado ao app. `LinkaMeasurementHistory.makeRepository()` é consumido por `SpeedTestViewModel`, `HistoryView`, `MainView`, `LinkaApp` e `NetworkStabilityPatternsViewModel`. `FileMeasurementHistoryRepository` persiste em disco com escrita atômica e falha fechada em corrupção — não é mais apenas a fundação isolada da Fase 0-2 registrada a seguir.

A narrativa de "Fase 0/1/2" abaixo descreve a construção original do módulo e permanece útil como contexto histórico de arquitetura, mas a seção "O que continua fora do módulo" não reflete mais o estado atual do produto.

## Arquitetura adotada

A fundação foi separada em pacotes neutros para permitir reuso futuro sem carregar identidade de produto:

```text
NetworkCore
    └── NetworkMeasurement

MeasurementHistory
    ├── MeasurementHistoryRepository
    ├── InMemoryMeasurementHistoryRepository
    ├── FileMeasurementHistoryRepository
    ├── MeasurementQuery
    └── HistoryRetentionPolicy

LinkaModules
    └── compatibilidade temporária com a fundação anterior
```

`MeasurementHistory` depende somente de `NetworkCore` e `Foundation`.

Não existe nesta fase:

```text
SpeedTest -> History
SwiftUI -> History
Web -> History
```

A integração será uma decisão posterior e deverá acontecer por adapter.

## Fase 0 — inventário

O Linka já tinha um embrião de histórico em `LinkaModules`: `MeasurementSnapshot`, `HistoryProviding` e `InMemoryHistoryStore`. Essa base foi aproveitada conceitualmente, sem criar uma segunda implementação concorrente.

Também foram registradas duas dívidas do engine iOS, sem alterá-las na época:

- `SpeedTestCore` ainda simulava jitter;
- `LinkaEngine.swift` ainda continha um caminho placeholder com resultado fixo.

Ambas já foram corrigidas: `SpeedTestCore` calcula jitter real a partir da diferença entre pings consecutivos, e o caminho placeholder foi removido. Registro mantido aqui apenas como contexto histórico da Fase 0.

## Fase 1 — contrato canônico

`NetworkMeasurement` foi movido para o pacote neutro `NetworkCore` e continua seguindo o schema interoperável v1 em `documentacao/arquitetura/contratos/network-measurement.schema.json`.

Regras principais:

- `schemaVersion = 1`;
- `complete` exige download, upload e latência;
- `partial` exige ao menos uma métrica;
- valores medidos não podem ser negativos ou não finitos;
- perda de pacotes, quando presente, fica entre 0 e 100;
- campos opcionais ausentes significam não medido/não disponível, nunca zero;
- diagnóstico, opinião, assinatura, UI e contexto do usuário não fazem parte da medição.

## Fase 2 — MeasurementHistory implementado

### Contrato do repositório

O módulo expõe:

- `save` com upsert idempotente por `id`;
- busca por `id`;
- consultas por `MeasurementQuery`;
- contagem total;
- exclusão individual;
- exclusão total.

### Consultas

`MeasurementQuery` suporta:

- data inicial e final;
- tipo de conexão;
- outcome completo/parcial;
- ordenação crescente/decrescente por data;
- offset;
- limit.

### Retenção

`HistoryRetentionPolicy` é configurável por:

- quantidade máxima de registros;
- idade máxima dos registros;
- sem limite quando ambos são omitidos.

A política pertence ao repositório, não à UI nem ao plano Free/Plus.

### Implementações

`InMemoryMeasurementHistoryRepository` serve para testes, desenvolvimento e consumidores que não precisam de persistência.

`FileMeasurementHistoryRepository` persiste um documento JSON próprio, com:

- versão do store;
- medições canônicas;
- escrita atômica;
- criação automática do diretório;
- falha fechada em arquivo corrompido;
- falha fechada em versão de store desconhecida;
- nenhuma exclusão/migração destrutiva automática.

### Testes adicionados

- idempotência por id;
- ordenação, filtros e paginação;
- retenção;
- rejeição de medição inválida;
- persistência entre instâncias;
- persistência de exclusão;
- arquivo corrompido;
- versão de store não suportada;
- contrato canônico e serialização JSON.

## O que ficou fora do módulo original (histórico da Fase 0-2)

Na fundação isolada, ainda não existiam:

- adapter do motor de SpeedTest;
- qualquer ViewModel;
- SwiftUI;
- React/Web;
- StoreKit e Free/Plus;
- CloudKit/Firebase/Supabase;
- Assist/IA;
- diagnóstico e recomendação.

O gate abaixo já foi cumprido: o adapter iOS existe, o módulo está ligado ao motor e às telas via `SpeedTestViewModel`/`HistoryView`, e a sincronização CloudKit tem um módulo próprio (`MeasurementHistoryCloudKit`, código pronto, aguardando apenas o provisionamento do container iCloud no Developer Portal para operar em produção — ver `LINKA_PLUS.md`). React/Web e diagnóstico/recomendação continuam fora, por decisão de produto (ver `AGENTS.md` e `VISAO.md`), não por limitação técnica.

## Gate original (cumprido)

1. executar `swift test` em `aplicativo-ios/NetworkCore`;
2. executar `swift test` em `aplicativo-ios/MeasurementHistory`;
3. executar `swift test` em `aplicativo-ios/LinkaModules` para validar compatibilidade;
4. revisar API pública e política de retenção;
5. somente depois decidir se haverá adapter iOS, Web ou ambos.

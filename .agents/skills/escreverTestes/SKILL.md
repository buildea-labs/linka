---
name: escrever-testes
description: Procedimento do Tiago para escrever testes junto com a implementação do Linka — motor, conversões de rede, política de retenção e estados do adapter. Ferramenta padrão é swift test (XCTest) nos pacotes Swift.
---

# Skill: escreverTestes

Procedimento do **Tiago** para escrever teste **junto** com a implementação — não depois, não "na próxima".

Quem audita a suíte no fim é o Igor ([`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)). Esta skill é sobre escrever.

Ferramentas por camada:

| Camada | Onde | Ferramenta |
|---|---|---|
| Pacotes Swift (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine`, `LinkaModules`) | `aplicativo-ios/<Pacote>/Tests/` | `swift test` (XCTest) |
| App SwiftUI (`LinkaApp`) | Xcode target de testes | XCTest / Xcode Test Plans |
| Adapters entre pacote e UI | `aplicativo-ios/LinkaApp/Tests/` | XCTest |
| Site institucional (`aplicacao-web/`) | — | não tem suíte hoje; se voltar, `vitest` |

CI: [`.github/workflows/swift-modules-ci.yml`](../../../.github/workflows/swift-modules-ci.yml).

---

## 0. Teste verde não é prova de que funciona

Isso vale antes de tudo. Teste cobre regra lógica e cálculo (ex.: bytes → Mbps, contrato canônico, política de retenção). Ele **não** cobre:

- iPhone real em 5G no metrô;
- iPad em Wi-Fi congestionado com 20 dispositivos concorrentes;
- Mac que troca de Wi-Fi para Ethernet no meio do teste;
- safe area do iPhone com Dynamic Island.

Isso é [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md), e não tem substituto.

## 1. O que sempre tem teste no Linka

- **Regras matemáticas e conversões.** `LinkaEngine` e `NetworkCore` não podem errar aritmética. Bytes, Kbps, Mbps — precisão cirúrgica.
- **Contrato canônico `NetworkMeasurement`.** Os testes de `NetworkCore` já validam schema v1 (campos obrigatórios em `complete`, ao menos uma métrica em `partial`, valores não-negativos e finitos). Ver [`documentacao/arquitetura/contratos/network-measurement.schema.json`](../../../documentacao/arquitetura/contratos/network-measurement.schema.json).
- **Transições do motor.** Fluxo `PREPARANDO → LATÊNCIA → DOWNLOAD → UPLOAD → RESULTADO` incluindo caminho `→ PARCIAL` e `→ ERRO`.
- **Cancelamento.** Cancelar no meio libera recurso, não deixa Task órfã, não conta como sucesso.
- **Falha de rede.** Perder conexão durante upload produz `partial` ou erro tratado — nunca zero silencioso.
- **Persistência (`MeasurementHistory`).** Idempotência por ID, ordenação, filtros, paginação, retenção, arquivo corrompido, versão de store desconhecida — os testes existentes cobrem isso; ao estender o pacote, mantenha o padrão.
- **Estatística (`NetworkInsights`).** Comparação pontual, série descritiva, tendência via regressão linear no tempo real (não index do array), períodos.
- **Guardrails de `NetworkAssist`.** Resposta `answered` sem evidência é rejeitada; evidência apontando para medição ausente é rejeitada; política de "não inferir causa" é enviada ao transport.

## 2. O que não vale a pena testar

- Valor exato de token visual (cor, radius em pt);
- Mock testando mock (`URLProtocol` que devolve `100 Mbps` fake não prova o motor — prova o mock);
- Copy palavra por palavra (isso é revisado por [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md));
- Layout de SwiftUI (isso é `garantirIphoneReal`).

## 3. Como escrever

- **Nome em PT-BR descrevendo comportamento.**

  ```swift
  // ❌ func test_returnsErrorWhenSessionInvalidated()
  // ✅ func test_medicao_cancela_e_devolve_parcial_quando_conexao_cai_no_meio_do_upload()
  ```

- **Um comportamento por teste.**
- **Arrange, Act, Assert.** Sem esperteza no meio.
- **Sem I/O real.** Injete `URLProtocol` de teste, `FileManager` de tempdir, `Clock` fake — não bata em rede/disco de verdade num teste de unidade.

## 4. O motor fica separado da UI

Se para testar cálculo de jitter você precisa montar uma `View`, o cálculo está grudado. Extraia a função pura para `NetworkCore` ou `LinkaEngine`, teste isolada com dados sintéticos de tempo, e a `View` fica livre.

Esta é a razão pela qual `NetworkCore`/`MeasurementHistory`/`NetworkInsights`/`NetworkAssist` não importam SwiftUI: teste em milissegundos, sem ambiente iOS.

## 5. Testes de integração no `LinkaApp`

Onde couber: adapter recebendo `Publisher` do pacote, `ObservableObject` produzindo estado correto, App Intents disparando medição, Widget lendo do App Group. Esses testes vivem no target de testes do app.

Mantenha-os separados dos testes de unidade dos pacotes — CI roda os pacotes em `swift test`, integração roda em Xcode.

## Relacionados

- **Contrato canônico:** [`documentacao/arquitetura/contratos/network-measurement.schema.json`](../../../documentacao/arquitetura/contratos/network-measurement.schema.json)
- **Auditoria final:** [`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)
- **iPhone real:** [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md)
- **Adapter:** [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)

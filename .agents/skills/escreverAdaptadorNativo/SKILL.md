---
name: escrever-adaptador-nativo
description: Procedimento do Tiago para adaptar SwiftUI a capacidades do LinkaEngine e dos pacotes Swift sem acoplar a View ao motor nem quebrar a fronteira Engine/Adapter/UI.
---

# Skill: escreverAdaptadorNativo

Procedimento do **Tiago** para quando uma capacidade do sistema Apple (histórico persistente, App Intents, background task, App Group, Widget, notificação) precisa ser ligada ao produto **sem** contaminar `LinkaEngine` ou as `View`s do `LinkaApp`.

A regra que decide tudo:

> **A UI não conhece o motor diretamente. O motor não conhece a UI. Entre os dois vive um adaptador.**

Autoridade: [`AGENTS.md`](../../../AGENTS.md) §4, §8; padrão Engine-Adapter-UI confirmado em [`documentacao/funcional/HISTORIA.md`](../../../documentacao/funcional/HISTORIA.md).

---

## 1. Antes de escrever, responda uma pergunta

**Existe um pacote (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine`, `LinkaModules`) cujo contrato já expõe o que a UI precisa?**

- **Existe** → é adaptador. Segue esta skill.
- **Não existe** → **pare.** Capacidade nova de motor não se resolve escrevendo `URLSession` dentro de uma `View`. Volta para o Giammattey para decidir se estende um pacote existente ou se abre outro.

Criar shim ad-hoc dentro da `View` para "só desta vez" é como o app vira mistura.

## 2. Onde o código mora

```text
aplicativo-ios/
├── NetworkCore/           contrato canônico da medição (não conhece UI)
├── MeasurementHistory/    persistência (não conhece UI)
├── NetworkInsights/       estatísticas puras (não conhece UI)
├── NetworkAssist/         camada de contexto para IA (não conhece UI)
├── LinkaEngine/           motor de medição (não conhece UI)
├── LinkaModules/          compatibilidade
├── LinkaAppIntents/       App Intents (Siri, Shortcuts)
├── LinkaEntitlements/     capacidades da App Store
└── LinkaApp/              SwiftUI — a UI. Consome os pacotes acima via adapter.
```

O adapter tipicamente vive em `LinkaApp/Sources/Adapters/` (ou análogo), traduz o dado do pacote em `ObservableObject` / `Observable` para a `View` consumir, e é o único ponto que sabe do async/URLSession/File I/O.

## 3. A fronteira é testada, não prometida

- `NetworkCore` **não** pode importar `SwiftUI`, `UIKit`, `AppKit`.
- `MeasurementHistory`, `NetworkInsights`, `NetworkAssist` **não** podem importar UI framework.
- `LinkaEngine` idem: sem UI framework.
- CI: [`.github/workflows/swift-modules-ci.yml`](../../../.github/workflows/swift-modules-ci.yml) roda `swift test` em cada pacote isoladamente — se um pacote não compila sem UI, ele já não vai passar (SPM não linka `SwiftUI` sem declaração explícita).

Se você precisou importar SwiftUI num pacote fora de `LinkaApp`, o desenho está errado — não o build.

## 4. Comportamento igual dos dois lados do adapter

O contrato do pacote não muda de significado só porque a `View` quer:

- **mesmo tipo de retorno, mesmos casos de erro.** Se o pacote devolve `.partial(reason: .cancelled)`, o adapter não vira isso em "sucesso silencioso" para a UI ficar bonita. O contrato canônico `NetworkMeasurement` (v1) define os estados possíveis — respeite.
- **nada de capacidade nova entrando de carona.** Adapter que expõe medição não deve, no meio do caminho, começar a inferir "sua conexão está boa" — interpretação é bem-vinda no Linka, mas vive em módulo separado (ex.: `LinkaModules`) e no `plano.md` da entrega, não escondida dentro de um adapter de medição ([`AGENTS.md`](../../../AGENTS.md) §1 e §9).
- **falha continua sendo falha.** Task cancelada não é sucesso. Timeout não é sucesso vazio. Se o pacote retorna `Result.failure`, a `View` recebe estado de erro — não uma medida zerada.

## 5. Recurso sensível tem dono e tem parada

`URLSession`, `Task`, `DispatchTimer`, `AVAudioSession` (se algum dia entrar), `NWPathMonitor`:

- ciclo de vida explícito no adapter, não espalhado pelas Views;
- todo caminho de saída solta o recurso — inclusive `.onDisappear`, task cancellation, app entering background;
- iOS pode mandar o app pro fundo sem avisar; a `View` desmontar não garante limpeza do que rodava em background;
- **quem inicia é quem cancela.** Sem exceção.

## 6. App Intents, Widgets, App Groups

- `LinkaAppIntents` é o único caminho para Siri/Shortcuts pedir uma medição. Ele consome `LinkaEngine`, não duplica o motor.
- Widgets (se existirem) leem do `MeasurementHistory` via App Group; não medem por conta própria.
- App Group para compartilhar dados: definido em `LinkaEntitlements`. O adapter é quem escreve/lê; a `View` recebe pronto.

## 7. Antes de abrir o PR

- [ ] o adapter está em `LinkaApp/`, não dentro de um pacote de motor;
- [ ] nenhum pacote fora de `LinkaApp` importa framework de UI;
- [ ] o contrato canônico da medição não foi violado (schema v1);
- [ ] falha do pacote chega na UI como estado de erro, não como sucesso vazio;
- [ ] recurso sensível tem parada em todo caminho de saída (inclusive background/cancelamento);
- [ ] `swift test` verde em todos os pacotes tocados;
- [ ] rodou no aparelho ([`rodarNoIphone`](../rodarNoIphone/SKILL.md)); o que não foi rodado está escrito como não rodado.

## Relacionados

- **Contrato canônico:** [`documentacao/arquitetura/contratos/network-measurement.schema.json`](../../../documentacao/arquitetura/contratos/network-measurement.schema.json)
- **Pacotes:** [`documentacao/arquitetura/PLANO_HISTORICO_MEDICOES.md`](../../../documentacao/arquitetura/PLANO_HISTORICO_MEDICOES.md), [`PLANO_NETWORK_INSIGHTS.md`](../../../documentacao/arquitetura/PLANO_NETWORK_INSIGHTS.md), [`PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md)
- **Arquitetura de módulo:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)
- **Testes:** [`escreverTestes`](../escreverTestes/SKILL.md)
- **Coesão e acoplamento:** [`validarModularidade`](../validarModularidade/SKILL.md)
- **Rodar no iPhone:** [`rodarNoIphone`](../rodarNoIphone/SKILL.md)

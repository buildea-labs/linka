---
name: escrever-adaptador-nativo
description: Procedimento do Camillo para ligar capacidades Apple e pacotes do Linka à UI sem quebrar a fronteira Engine/Adapter/UI.
---

# Skill: escrever-adaptador-nativo

Procedimento de **Camillo**.

Regra central:

> **A UI não implementa o motor. O motor não conhece a UI. O adapter traduz estado, ciclo de vida e intenção entre os dois.**

## Antes de escrever

Pergunte se um contrato existente (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine` ou outro pacote atual) já expõe o necessário.

- Se sim, adapte.
- Se não, pare e trate como decisão arquitetural com `arquitetar-modulo`/`aconselhar-arquitetura`.

Não resolva capacidade ausente escondendo `URLSession`, persistência ou regra de medição dentro de uma `View`.

## Fronteiras

- pacotes de domínio/motor não importam `SwiftUI`, `UIKit` ou `AppKit` sem necessidade arquitetural explícita;
- `LinkaApp` consome pacotes; o inverso não ocorre;
- erro/partial/cancelamento mantêm significado através do adapter;
- interpretação e recomendação não entram de carona num adapter de medição;
- ausência de dado não vira zero/default para simplificar binding.

## Ciclo de vida

`Task`, `URLSession`, timers, monitors e recursos semelhantes têm dono explícito. Quem inicia precisa garantir cancelamento/cleanup em sucesso, erro, cancelamento, background e desmontagem da superfície quando aplicável.

## Integrações Apple

App Intents, Widgets, App Groups, Shortcuts e outras superfícies devem consumir o mesmo domínio/motor, não duplicar metodologia.

## Antes de devolver

- fronteira UI/motor preservada;
- contrato não mudou silenciosamente;
- falha continua falha;
- cleanup existe em todos os caminhos relevantes;
- testes dos pacotes tocados executados;
- validação em aparelho real quando necessária;
- o que não foi testado está declarado.

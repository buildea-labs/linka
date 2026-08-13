# LinkaAppIntents

Módulo isolado de integração do Linka com o framework App Intents.

## O que existe no v1

- `StartSpeedTestIntent`
- `OpenLatestMeasurementIntent`
- `OpenHistoryIntent`
- `GetLatestResultIntent`
- `LinkaAppShortcuts` com dois atalhos pré-configurados
- `LinkaAppIntentExecutor` como porta de execução injetável
- `LinkaAppIntentsPackage` para permitir inclusão futura pelo app/extension

## O que não existe ainda

Este pacote não está conectado ao `LinkaApp`, ao `SpeedTestCore`, ao `MeasurementHistory` nem à navegação SwiftUI.

Não há execução simulada. Sem um executor real registrado pelo app, a integração não deve ser considerada operacional.

Na futura integração, o app registra um `LinkaAppIntentExecutor` no `AppDependencyManager` e mapeia cada `LinkaSystemAction` para capacidades reais do produto.

## Limite de arquitetura

App Intents é uma integração Apple dedicada. Widgets e sincronização iCloud devem viver em módulos/adapters próprios em vez de crescerem dentro deste pacote.

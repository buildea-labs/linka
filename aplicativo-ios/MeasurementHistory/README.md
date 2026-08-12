# MeasurementHistory

Módulo independente para armazenar e consultar medições de rede.

## Dependência

Depende somente de `NetworkCore` e `Foundation`. Não conhece LinkaApp, SwiftUI, UIKit, StoreKit, React, Firebase, CloudKit ou qualquer motor de SpeedTest.

## API pública

- `MeasurementHistoryRepository`
- `MeasurementQuery`
- `HistoryRetentionPolicy`
- `InMemoryMeasurementHistoryRepository`
- `FileMeasurementHistoryRepository`

## Comportamento

- `save` faz upsert por `NetworkMeasurement.id`;
- medições inválidas são rejeitadas antes da persistência;
- consultas suportam intervalo de data, tipo de conexão, outcome, ordenação, offset e limit;
- retenção é configurável por quantidade máxima e/ou idade;
- o store em arquivo usa documento JSON versionado e escrita atômica;
- arquivo corrompido ou versão desconhecida falha fechado, sem apagar dados automaticamente.

## Não objetivos desta fase

- conectar ao SpeedTest;
- conectar a Web ou SwiftUI;
- escolher tela ou jornada de Histórico;
- sincronizar nuvem;
- diagnosticar resultados;
- controlar Free/Plus.

A integração com produtos deve acontecer por adapter em uma fase posterior.

# NetworkInsights

Módulo independente de análise estatística de medições de rede.

## Dependência

Depende somente de `NetworkCore` e `Foundation`. Não conhece Histórico, LinkaApp, SwiftUI, React, StoreKit, IA ou qualquer motor de SpeedTest.

## Faz

- compara duas medições;
- respeita a semântica da métrica (`maior é melhor` ou `menor é melhor`);
- calcula mínimo, máximo, média, mediana, desvio padrão e variação relativa;
- calcula tendência temporal por regressão linear;
- compara médias entre dois períodos;
- rejeita medições inválidas.

## Não faz

- diagnosticar causa;
- recomendar reparo;
- buscar dados no Histórico;
- persistir dados;
- decidir Free/Plus;
- gerar copy de produto;
- chamar IA;
- conectar UI.

O consumidor entrega `[NetworkMeasurement]` e recebe fatos calculados. A integração com um repositório de Histórico deve acontecer fora deste pacote.

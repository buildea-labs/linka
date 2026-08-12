# NetworkInsights — plano e implementação

Status: módulo backend isolado implementado na branch `feat/network-insights`.

## Objetivo

Transformar uma ou mais `NetworkMeasurement` em fatos estatísticos reutilizáveis, sem UI, persistência, IA, diagnóstico ou conhecimento de produto.

```text
[NetworkMeasurement]
        ↓
 NetworkInsights
        ↓
comparação | estatística | tendência | períodos
```

Não existe conexão direta com `MeasurementHistory`. Um consumidor futuro poderá consultar o Histórico e entregar os registros ao Insights por adapter/orquestração externa.

## Dependências

- `NetworkCore`
- `Foundation`

Não depende de:

- `MeasurementHistory`;
- `LinkaModules`;
- LinkaApp/SwiftUI;
- Web/React;
- StoreKit;
- IA;
- motor de SpeedTest.

## API v1

### Comparação pontual

Compara duas medições métrica a métrica e retorna:

- valor atual;
- valor base;
- delta absoluto;
- delta percentual quando matematicamente definido;
- direção semântica.

Download/upload usam `higherIsBetter`. Latência, jitter, perda e latência sob carga usam `lowerIsBetter`.

### Estatística descritiva

Para cada métrica disponível:

- quantidade de amostras;
- mínimo;
- máximo;
- média;
- mediana;
- desvio padrão populacional;
- variação relativa percentual.

Campos ausentes não viram zero.

### Tendência

A tendência usa regressão linear sobre tempo real das medições, não a ordem do array. Expõe:

- quantidade de amostras;
- direção (`rising`, `falling`, `stable`, `insufficientData`);
- inclinação por dia;
- mudança percentual estimada entre o início e o fim da janela.

Um limiar configurável evita classificar pequenas oscilações como tendência.

### Comparação de períodos

Compara as médias métricas de duas coleções e aplica a mesma semântica da comparação pontual.

## Limites

O módulo pode afirmar:

- "download médio caiu 18%";
- "latência média melhorou";
- "há tendência de alta na latência".

O módulo não pode afirmar:

- "seu roteador está ruim";
- "o Wi‑Fi está congestionado";
- "troque de canal";
- qualquer causa, diagnóstico ou recomendação.

## Gate

1. `swift test` em `NetworkCore`;
2. `swift test` em `MeasurementHistory` para garantir que a base anterior segue íntegra;
3. `swift test` em `NetworkInsights`;
4. `swift test` em `LinkaModules` para compatibilidade da fundação;
5. nenhuma integração com interface ou engine.

# NetworkAssist

Módulo independente para interpretar medições de rede com um provider injetável.

## Dependência

Depende somente de `NetworkCore` e `Foundation`. Não conhece LinkaApp, SwiftUI, React, StoreKit, Histórico, Firebase, CloudKit ou qualquer fornecedor de IA.

## Responsabilidade

O consumidor entrega uma pergunta, uma medição atual e contexto opcional. O módulo valida o contexto, aplica uma política fixa de escopo e delega a geração da resposta a um `NetworkAssistTransport`.

A saída é estruturada em quatro disposições:

- `answered`: resposta baseada nas evidências fornecidas;
- `insufficientEvidence`: não há dados suficientes;
- `requiresDiagnosis`: a pergunta exige investigação de causa/diagnóstico;
- `unsupported`: fora do escopo de interpretação de medições.

## Guardrails

- não infere causa raiz;
- não recomenda reparo;
- exige grounding em dados fornecidos;
- rejeita medições inválidas antes do transport;
- limita tamanho da pergunta e do contexto;
- valida referências de evidência devolvidas pelo provider;
- não contém chave, endpoint ou SDK de IA.

## Não objetivos

- conectar UI;
- buscar Histórico;
- calcular Insights;
- decidir Free/Plus;
- escolher fornecedor de IA;
- diagnosticar rede;
- redirecionar diretamente para um produto específico.

Adapters futuros podem transformar resultados de `NetworkInsights` em `NetworkAssistEvidence` e podem mapear `requiresDiagnosis` para a experiência de produto apropriada.

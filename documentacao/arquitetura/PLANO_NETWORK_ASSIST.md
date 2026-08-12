# NetworkAssist — plano e implementação

Status: backend isolado implementado na branch `feat/network-assist`. Nenhuma UI ou conexão real com fornecedor de IA foi criada.

## Objetivo

Transformar medições e fatos previamente calculados em contexto seguro para uma camada de linguagem, sem permitir que o módulo se torne um motor de diagnóstico.

```text
NetworkMeasurement + evidências estruturadas + pergunta
                         ↓
                   NetworkAssist
                         ↓
        resposta estruturada / handoff
```

O módulo não busca Histórico e não calcula Insights. Essas integrações devem acontecer por adapters fora dele.

## Fronteira funcional

Pode:

- explicar o significado dos números fornecidos;
- relacionar métricas a uma pergunta do usuário;
- resumir mudanças já demonstradas pelas evidências;
- declarar insuficiência de dados;
- declarar que uma pergunta exige diagnóstico.

Não pode:

- inventar causa raiz;
- afirmar defeito de roteador, operadora, Wi-Fi ou dispositivo sem motor diagnóstico;
- recomendar reparo como se tivesse diagnosticado o problema;
- coletar dados sozinho;
- escolher plano Free/Plus;
- conhecer Linka ou SignallQ como identidade de produto.

## Arquitetura

`NetworkAssist` depende somente de `NetworkCore` e `Foundation`.

`NetworkAssistService` valida o contexto e cria uma requisição com `NetworkAssistPolicy.measurementUnderstanding`. O `NetworkAssistTransport` é a única porta para implementação externa futura.

Não existe endpoint, SDK ou segredo nesta fase.

## Contratos principais

- `NetworkAssistContext`: entrada do consumidor;
- `NetworkAssistEvidence`: fato estruturado opcional produzido por adapters;
- `NetworkAssistRequest`: payload validado enviado ao transport;
- `NetworkAssistResponse`: texto + disposição + referências de evidência;
- `NetworkAssistProviding`: serviço consumível;
- `NetworkAssistTransport`: porta para provider local/remoto.

## Disposições

- `answered`: resposta observacional e grounded;
- `insufficientEvidence`: dados insuficientes;
- `requiresDiagnosis`: exige investigação causal;
- `unsupported`: fora do escopo.

Uma resposta `answered` precisa citar pelo menos uma evidência conhecida. O módulo disponibiliza IDs estáveis para a medição atual e para medições recentes, além dos IDs de `NetworkAssistEvidence` fornecidos pelo consumidor.

## Guardrails v1

- pergunta não vazia e com limite configurável;
- medição atual válida;
- medições recentes válidas e limitadas;
- evidências limitadas e com IDs únicos;
- evidência não pode apontar para medição ausente do contexto;
- números de evidência precisam ser finitos;
- resposta vazia é rejeitada;
- referência de evidência desconhecida é rejeitada;
- `answered` sem evidência é rejeitado;
- política enviada ao transport proíbe inferir causa raiz e recomendar reparo.

## Integração futura

Um adapter de `NetworkInsights` poderá converter comparações, estatísticas e tendências em `NetworkAssistEvidence`.

Um adapter de produto poderá mapear `requiresDiagnosis` para uma experiência específica. Essa decisão não pertence ao módulo.

Um transport remoto deverá viver fora do pacote e manter credenciais no servidor. Nunca deve haver chave de fornecedor de IA embutida no cliente.

## Gate

Antes de congelar o módulo:

1. `NetworkCore` verde;
2. `MeasurementHistory` verde;
3. `NetworkInsights` verde;
4. `NetworkAssist` verde;
5. `LinkaModules` compatibility verde.

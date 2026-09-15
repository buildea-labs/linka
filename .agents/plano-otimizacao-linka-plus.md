# Plano — Otimização Linka+ (MVP)

## Objetivo

Depois de uma medição concluída, o Linka+ apresenta até três oportunidades
determinísticas para melhorar aquela conexão, conduz uma ação assistida e pede
um reteste. O resultado só declara melhoria quando os testes forem comparáveis.

## Decisões de produto consolidadas

- Otimização é exclusiva do Linka+, com prévia gratuita limitada.
- A entrada principal fica no resultado concluído e no detalhe do histórico;
  ela nunca atrasa ou altera `ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR`.
- O MVP pode orientar uso concorrente, proximidade do roteador e reinício,
  sempre como sugestão, não diagnóstico causal ou garantia.
- Perfis de rede nomeados ficam para a fase 2. Quando existirem, poderão usar
  a identidade local já disponível somente se a pessoa tiver habilitado a
  identificação Wi-Fi.
- O MVP não altera DNS, troca banda Wi-Fi, muda roteador, roda em background
  ou afirma compatibilidade de roteador.

## Arquitetura e escopo do MVP

Criar `NetworkOptimization`, um pacote puro dependente apenas de
`NetworkCore` e `NetworkInsights`.

`OptimizationPlanBuilder` recebe a medição final e o histórico local, e devolve
um `OptimizationPlan` com no máximo três `OptimizationOpportunity`.
Cada oportunidade contém ID e versão de regra determinísticos, fatos que a
sustentam, confiança, impacto, ação `.guided` e critério de reteste.

Entram somente oportunidades sustentadas por dados reais:

1. estabilidade e resposta sob carga (jitter, perda ou latência sob carga);
2. banda Wi-Fi somente com banda, sinal e histórico comparável confirmados;
3. resultado degradado em comparação com histórico da mesma rede confirmada.

O `LinkaEngine` não recebe regras, copy nem estado de Otimização.
`NetworkMeasurement` não muda de schema neste MVP. A camada do app orquestra a
sessão efêmera: consulta histórico, constrói o plano, abre a interface e pede
o reteste através do fluxo de medição existente.

## Antes e depois

Uma comparação exige duas medições válidas, métricas presentes, mesmo tipo de
conexão, mesma identidade Wi-Fi confirmada quando aplicável, rota estável e
variação acima do limiar prático de `NetworkInsights`.

- Comparável com ganho relevante: apresenta a mudança observada, sem atribuir
  causalidade à orientação.
- Comparável sem ganho relevante: `Não houve ganho significativo.`
- Não comparável: `Não foi possível comparar esta tentativa.`

## Privacidade e falhas

- Tudo é local no MVP; não há endpoint, IA, telemetria nova ou background.
- Dados Wi-Fi ausentes eliminam oportunidades dependentes de rede/banda.
- Histórico indisponível ou corrompido mantém apenas a leitura atual, sem
  perfil nem comparação.
- Reteste cancelado, offline ou com erro preserva a medição original e permite
  retomada explícita.
- DNS comparativo, DoH/DoT e controle de roteador são fases separadas.

## Superfícies

- iPhone/iPad: ação secundária pós-resultado, folha de análise e lista nativa
  de oportunidades; a prévia mostra valor sem aplicar uma ação Plus.
- Mac: destino contextual `Otimização` na sidebar atual, sem dashboard paralelo.
- Acessibilidade: cada oportunidade expõe fato, recomendação, ação e condição
  de reteste em texto; cor nunca é a única indicação.

## Aceite e validação

- `NetworkOptimization`: determinismo, ordenação, corte em três, ausência de
  evidência, Wi-Fi não confirmado e regras de banda.
- Coordinator: baseline/reteste comparável, rede trocada, cancelamento, erro e
  ausência de ganho.
- App: gate Linka+, prévia gratuita, iPhone sem banda/RSSI, Mac com dado
  confirmado e acessibilidade das ações.
- Regressão: `NetworkCore`, `NetworkInsights`, `MeasurementHistory`,
  `LinkaModules`, testes do app iOS e build macOS.

## Fases posteriores

1. Perfis locais nomeados e baseline por rede identificada.
2. Benchmark DNS determinístico, após definir método, custo e privacidade.
3. DoH/DoT com consentimento, estado verificável e reversão.
4. Adaptadores para roteadores explicitamente compatíveis.

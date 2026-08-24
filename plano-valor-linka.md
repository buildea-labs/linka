# Plano — valor recorrente do Linka

## Objetivo

Fazer o Linka sustentar uma assinatura anual de R$ 34,90 por meio de quatro capacidades reais e úteis no ecossistema Apple: medição confiável, histórico permanente, comparação baseada em dados e Assist fundamentado nas próprias medições.

O teste principal continuará completo e útil sem assinatura. O Plus comprará entendimento e acompanhamento ao longo do tempo, não acesso artificial à medição.

## Estado inicial verificado em 23/08/2026

- `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine` e `LinkaModules` passaram em `swift test`.
- O target `LinkaAppTests` passou no simulador iPhone 17 Pro com 17 testes.
- O fluxo ativo do app usa `SpeedTestCore`, com medições reais e testes de cancelamento, falha e resultado parcial.
- O caminho placeholder concorrente de `LinkaEngine/Core/LinkaEngine.swift` foi removido; o pacote mantém `SpeedTestCore` como único motor de medição.
- Quando já existe histórico, `SpeedTestViewModel.loadLastTest()` restaura o último resultado e não inicia uma nova medição. Esse comportamento é intencional: a abertura preserva o último resultado para consulta, e uma nova medição fica disponível por ação explícita do usuário.
- O simulador emitiu avisos de `commcenter.coretelephony.xpc`, mas não houve falha nos testes; isso não substitui validação em iPhone real.

## Mudança arquitetural

Entregar em fatias independentes, mantendo a separação entre medição, dados, interpretação e interface:

1. **Medição e resultado** — auditar e corrigir estados reais do fluxo sem alterar a metodologia do `LinkaEngine` sem evidência.
2. **Histórico** — integrar o `MeasurementHistory` persistente ao app por adapter, preservando o contrato `NetworkMeasurement` v1 e uma política explícita de retenção, corrupção e exclusão.
3. **Comparação e tendências** — conectar `MeasurementHistory` a `NetworkInsights` fora dos pacotes de domínio; expor fatos estatísticos, não causas ou diagnósticos.
4. **Assist** — fornecer a medição atual, histórico limitado e fatos do `NetworkInsights` ao `NetworkAssist`; o transporte remoto permanece fora dos pacotes e nenhum segredo entra no app.

O `LinkaEngine` não conhecerá histórico, assinatura, Assist ou UI. A tela exibirá interpretação somente em superfície secundária e sob divulgação progressiva.

## Política de produto proposta

- **Free:** medição completa, resultado, detalhes básicos, reteste e histórico básico persistido.
- **Plus:** comparação, tendências, interpretação contextual e Assist sobre os dados do usuário.
- Não limitar a quantidade de testes para forçar assinatura.
- Não criar dashboard, métrica decorativa, diagnóstico causal ou resposta de IA sem evidência.
- Widgets, Siri/App Intents e sincronização ficam fora desta entrega por dependerem do item 5 e de decisão/infraestrutura própria.

## Requisitos de aceite

- O fluxo abrir → medir → resultado → repetir continua sem login, onboarding ou seleção manual.
- Download, upload e latência usam medições reais; cancelamento, erro, offline e resultado parcial são representados honestamente.
- Uma medição válida sobrevive ao encerramento e reabertura do app, sem quebrar o schema v1.
- O usuário pode consultar, comparar e excluir seu histórico; arquivo corrompido ou versão desconhecida falha fechado e de forma acionável.
- Comparações e tendências citam apenas métricas presentes e classificam dados insuficientes sem inventar zero ou conclusão.
- O Assist só responde quando houver evidência referenciada; ausência de dados, falha do transporte e perguntas causais produzem estados explícitos.
- Nenhum segredo, token permanente ou endpoint privado é embutido no app ou no site.
- O primeiro frame do resultado permanece dominado pela medição; histórico, insights e Assist não competem com ela.
- Testes passam em `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaModules` e nos adapters afetados; o app deve compilar para iOS e macOS quando a fatia tocar a aplicação.

## Ordem de implementação

1. Inventário e testes dos estados atuais da medição/resultados.
2. Adapter de persistência e integração do histórico.
3. Adapter de comparação/tendência e superfícies secundárias.
4. Contexto/evidências do Assist e estados remotos explícitos.
5. Validação de acessibilidade, iPhone real e regressões multiplataforma.

## Não-objetivos

- Não implementar Widget, Siri, App Intents ou sincronização Apple nesta entrega.
- Não implementar compra real, paywall final ou publicação sem decisão operacional específica.
- Não alterar o motor para simular capacidades ausentes.
- Não criar versão Web/Android do produto.
- Não transformar o Linka em central de diagnóstico ou painel de telecom.
- Não sobrescrever nem incorporar o escopo pré-existente de `plano.md`, que trata da compatibilidade NDS/Assist.

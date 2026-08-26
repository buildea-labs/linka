---
name: arquitetar-modulo
description: Guia do Giam para desenhar mudanças modulares no Linka sem ampliar o escopo por acidente, respeitando a separação Engine/Adapter/UI e a curadoria de minimalismo.
---

# Skill: arquitetarModulo

Procedimento do **Giam** para desenhar uma mudança antes do Guinho implementar.

A saída desta skill é a **parte técnica** do `plano.md` exigido pela Full‑flow em [`.agents/WORKFLOW.md`](../../WORKFLOW.md) (Passo 1 — Architect): arquitetura decidida, recorte da implementação, prioridade e requisitos de aceite. Sem ele, o Luiz não aprova a arquitetura e nenhuma branch é aberta.

A parte de produto e desenho sai de [`desenharExperiencia`](../desenharExperiencia/SKILL.md), [`desenharInterface`](../desenharInterface/SKILL.md), [`pensarComoMedicao`](../pensarComoMedicao/SKILL.md) e [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md).

**A decisão técnica é do Giam, tomada sozinho, avaliando o produto.** O que não decide sozinho é dúvida de produto — aí pergunta ao Luiz, do jeito da [`conversarComOLuiz`](../conversarComOLuiz/SKILL.md), e espera resposta em vez de preencher.

## 0. Escopo antes da arquitetura

Leia [`AGENTS.md`](../../../AGENTS.md) §1-2 e [`documentacao/funcional/VISAO.md`](../../../documentacao/funcional/VISAO.md).

Pergunte:

> Esta mudança melhora medir, entender ou acompanhar a conexão no Apple sem competir com o resultado, e é viável nas capacidades que a Apple expõe?

Se a resposta for "não" (por curadoria de minimalismo ou por viabilidade Apple), **não desenhe pacote, contrato, estado ou abstração para ela nesta tarefa**. Abra issue no backlog. Se a resposta for "sim mas fica pesado", proponha entrega faseada.

Depois leia, conforme o caso:

- [`documentacao/arquitetura/PLANO_HISTORICO_MEDICOES.md`](../../../documentacao/arquitetura/PLANO_HISTORICO_MEDICOES.md) — `NetworkCore` + `MeasurementHistory`
- [`documentacao/arquitetura/PLANO_NETWORK_INSIGHTS.md`](../../../documentacao/arquitetura/PLANO_NETWORK_INSIGHTS.md) — `NetworkInsights`
- [`documentacao/arquitetura/PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md) — `NetworkAssist`
- [`documentacao/arquitetura/contratos/network-measurement.schema.json`](../../../documentacao/arquitetura/contratos/network-measurement.schema.json) — schema canônico v1

## Duas regras que o produto impõe à arquitetura

1. **Motor separado da tela.** `LinkaEngine`, `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist` são pacotes Swift isolados — não conhecem `LinkaApp` (SwiftUI). É o que mantém o motor evoluindo independente da UI e permite que múltiplas superfícies (SwiftUI, App Intents, Assist, Widgets) consumam o mesmo dado.
2. **Interpretação vive fora do motor.** Diagnóstico, interpretação, Assist, histórico e recomendação são bem-vindos quando viáveis no Apple, mas moram em módulos separados (ex.: `LinkaModules`) — nunca dentro do motor de medição. Ver [`AGENTS.md`](../../../AGENTS.md) §1, §9 e [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md).

## 1. Comece pelo comportamento

Antes de criar camada, escreva o fluxo em uma linha.

Exemplo:

```text
usuário abre app → medição inicia automaticamente → download → upload → resultado mostrado
```

Liste:

- entrada;
- saída;
- estado persistido (histórico? preferências?);
- falhas importantes (perda de rede, cancelamento, timeout);
- recurso que precisa de ciclo de vida explícito (URLSession, timer, task Swift).

## 2. Onde a mudança mora

Divisão típica dos pacotes no `aplicativo-ios/`:

- **`NetworkCore`** — contrato canônico `NetworkMeasurement`, sem dependências de produto;
- **`LinkaEngine`** — motor de medição real (download, upload, latência);
- **`MeasurementHistory`** — persistência (in-memory ou file-based), políticas de retenção;
- **`NetworkInsights`** — estatísticas puras (comparação, tendência), sem diagnóstico;
- **`NetworkAssist`** — camada de contexto para IA responder sobre medição/histórico, sem inferir causa;
- **`LinkaModules`** — compatibilidade temporária com a fundação anterior;
- **`LinkaAppIntents`** — SiriKit / App Intents;
- **`LinkaEntitlements`** — capacidades da App Store;
- **`LinkaApp`** — SwiftUI, UI apenas.

**Modularidade não é quantidade de arquivo. É responsabilidade clara.** Não crie pacote novo para uma função de dez linhas.

## 3. Persistência só quando o domínio exige

Antes de persistir dado novo:

1. confirme que persistência é necessária (o dado sobrevive a fechar o app?);
2. confirme que a feature pertence ao escopo do Linka;
3. procure entidade existente em `MeasurementHistory` que já represente o conceito;
4. defina política de retenção junto do design;
5. planeje o path do arquivo (documento, cache, App Group) e o que acontece se corromper.

`FileMeasurementHistoryRepository` já falha fechado em arquivo corrompido ou versão desconhecida — respeite esse padrão.

## 4. Contrato canônico

`NetworkMeasurement` segue o schema v1. Regras:

- `schemaVersion = 1`;
- `complete` exige download, upload e latência;
- `partial` exige ao menos uma métrica;
- valores medidos não podem ser negativos ou não finitos;
- campos opcionais ausentes = não medido/não disponível, nunca zero;
- diagnóstico, opinião, assinatura, UI e contexto do usuário não fazem parte da medição.

Mudança incompatível = `schemaVersion` novo + migração dos consumidores.

## 5. Segurança e privacidade

- Sem login obrigatório ([`AGENTS.md`](../../../AGENTS.md) §6, §10);
- coletar e reter apenas o necessário;
- afirmação em `Como medimos` precisa ser verificável no código;
- **nenhuma chave de API no bundle iOS ou Web**. Segredo vive no servidor, nunca no cliente ([`AGENTS.md`](../../../AGENTS.md) §9).
- informação sensível (IP, BSSID, operadora) não aparece em share por padrão.

## 6. Anti-monolítico sem numerologia

Não existe número mágico de linhas que transforme arquivo em monólito.

Sinais reais de problema:

- UI + medição + persistência no mesmo tipo Swift;
- cleanup de `URLSession`/`Task` espalhado sem dono;
- função com razões independentes para mudar;
- duplicação de fórmula (ex.: bytes→Mbps em dois lugares);
- `View` impossível de testar sem montar o app inteiro.

Arquivo grande com uma responsabilidade coesa pode ser justificado. Arquivo de 80 linhas com quatro responsabilidades não fica bom porque é pequeno.

## 7. Entrega do planejamento

Antes de implementar, deixe claro:

- pacotes/camadas afetados;
- contrato de dados (se novo ou modificado, com nota sobre `schemaVersion`);
- segurança e privacidade;
- erros e cancelamento;
- testes (`swift test` em qual pacote);
- **o que NÃO será feito nesta fatia.**

A última linha é obrigatória. É ela que impede uma feature de medição virar central de diagnóstico no meio do PR.

## Relacionados

- **Proteção do motor:** [`aconselharArquitetura`](../aconselharArquitetura/SKILL.md)
- **Adaptador entre Engine e UI:** [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)
- **Testes:** [`escreverTestes`](../escreverTestes/SKILL.md)
- **Modularidade:** [`validarModularidade`](../validarModularidade/SKILL.md)

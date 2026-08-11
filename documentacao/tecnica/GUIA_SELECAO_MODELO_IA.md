# Guia de Selecao de Modelo IA — Ecossistema Linka

> Quando usar qual modelo de IA e qual agente. Minimizar custo de tokens sem sacrificar qualidade.
> Fonte: `E:\Projetos\Linka\CLAUDE.md` + `linkaSpeedtestPwa/CLAUDE.md`.

---

## 1. Principio geral

**Use a menor ferramenta/modelo suficiente para a tarefa.**

Haiku e rapido e barato — use para buscas, leituras e tarefas mecanicas.
Sonnet e o padrao para desenvolvimento e documentacao complexa.
Opus e para decisoes de arquitetura e analise de complexidade alta.

---

## 2. Guia por cenario

### Por tipo de tarefa

| Cenario | Modelo sugerido | Agente |
|---|---|---|
| Bug simples isolado (<50 linhas, <=5 arquivos) | Haiku | Marcelo (busca) → Camilo/Renan (fix) |
| Feature normal ou testes | Sonnet | Fluxo padrao (Claudio → Camilo/Renan) |
| Busca de simbolo ou arquivo em codigo | Haiku | Marcelo |
| Documentacao leve (changelog, checklist) | Haiku | Nina |
| Documentacao pesada (funcional, tecnica, fluxos) | Sonnet | Taisa |
| Revisao de UX/UI | Sonnet | Lia |
| Validacao de hardware/permissoes Android | Sonnet | Otavio |
| Arquitetura ou integracao complexa | Opus | Claudio |
| Refactor amplo ou decisao critica | Opus | Claudio |
| Analise de muitas screenshots | Gemini 2.5 | Qualquer agente visual |
| Revisao final de qualidade | Sonnet | Gema |

### Por tamanho de task

| Tamanho | Criterio | Abordagem |
|---|---|---|
| **Pequeno** | <=5 arquivos, sem mudanca de contrato, <2h | Haiku para busca + Sonnet para implementacao |
| **Medio** | 5-15 arquivos, 1 modulo principal | Sonnet para planejamento e implementacao |
| **Grande** | >15 arquivos, >1 modulo, >1 dia | Opus para planejamento (Claudio) + Sonnet para implementacao |

---

## 3. Agentes e seus modelos

| Agente | Modelo | Quando acionar |
|---|---|---|
| Claudete | sonnet | Objetivo macro ou vago — define direcao antes de qualquer implementacao |
| Claudio | sonnet | Planejamento, breakdown, arquitetura. Nao para bugfixes simples |
| Lia | sonnet | Qualquer mudanca visual: tela, estado, texto visivel, navegacao |
| Otavio | sonnet | Antes de Camilo em tasks com permissoes, Wi-Fi, DNS, hardware Android |
| Camilo | sonnet | Implementacao Android — recebe tasks pequenas e claras |
| Renan | sonnet | Implementacao PWA — recebe tasks pequenas e claras |
| Gema | sonnet | Revisao final em paralelo com Lia |
| Nina | **haiku** | Changelog, versionamento, checklist, scout de docs |
| Taisa | sonnet | Documentacao especializada e pesada |
| Marcelo | **haiku** | Busca de codigo, grep, listagem de arquivos — delegar ANTES de consumir Sonnet |

---

## 4. Regras de economia de tokens

### Antes de ler qualquer arquivo

1. Use `Grep` para encontrar o simbolo, classe ou funcao especifica
2. So entao use `Read` no arquivo encontrado, apontando so para as linhas relevantes
3. Se for busca mecanica (existencia de arquivo, path de um componente), **delegar ao Marcelo (Haiku)**

### Antes de consumir contexto Sonnet

- Buscas em codigo → Marcelo
- Buscas em documentacao → Nina
- Leitura de arquivo simples para triagem → Marcelo ou Nina
- So voltar para Sonnet quando precisar de julgamento ou escrita

### Formato de delegacao para Marcelo

```
Tarefa para Marcelo:
[Descricao da busca]

Retornar: [o que preciso — paths, trechos, existencia]
Contexto minimo: [projeto, pasta, nome do componente ou funcao]
```

### Nao acumular contexto desnecessario

- Ler `CLAUDE.md` uma vez por sessao, nao a cada subtask
- Nao repetir contexto que o agente anterior ja entregou — usar handoff delta
- Tasks simples (bugfix <=5 arquivos): maximo 3 secoes na resposta

---

## 5. Quando escalar o modelo

**Escalar para Opus (via Claudio) quando:**
- Task afeta >5 modulos
- Estimativa >1 dia de trabalho
- Decisao de arquitetura sem precedente no codebase
- Refactor que muda contrato de API existente
- Conflito entre abordagens tecnicas sem resposta clara no codigo

**Nao escalar para Opus quando:**
- Bugfix simples
- Feature dentro de um unico modulo ja documentado
- Duvida que pode ser respondida lendo o codigo existente

---

## 6. Ferramentas por situacao

| Situacao | Ferramenta |
|---|---|
| Encontrar classe/funcao no codigo | `Grep` (simbolo especifico) |
| Listar arquivos de um modulo | `Glob` (padrao de path) |
| Ler trecho especifico de arquivo | `Read` com `offset` e `limit` |
| Verificar existencia de componente | `Grep` ou `Glob` via Marcelo |
| Buscar em documentacao existente | `Glob` em `docs/` via Nina |
| Alterar arquivo existente | `Edit` (preferir sobre `Write`) |
| Criar arquivo novo | `Write` |

---

## 7. Anti-padroes a evitar

| Anti-padrao | Consequencia |
|---|---|
| Usar Sonnet para busca mecanica de arquivo | Desperdicio de contexto — usar Marcelo |
| Abrir modulo inteiro para achar uma funcao | Desperdicio de tokens — Grep primeiro |
| Repetir contexto completo no handoff | Acumula contexto inutilmente |
| Acionar Claudio para bugfix simples | Overhead de planejamento desnecessario |
| Acionar Opus para task de tamanho medio | Custo desnecessario |
| Acionar /map-impact para bugfix pontual | Overhead de mapeamento desnecessario |

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa

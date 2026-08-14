# Guia de Convivencia com IA — Ecossistema Linka

> Como o time usa IA neste workspace. Regras de comportamento para agentes Claude. O que cada agente faz e quando acionar.
> Fonte de verdade para comportamento de agentes: `E:\Projetos\Linka\CLAUDE.md`.

---

## 1. O sistema multiagente

O Linka usa Claude Code com um sistema de sub-agentes especializados. Cada agente tem um papel restrito — nao implementa fora da sua area, nao aprova o que nao e sua responsabilidade.

Nenhum agente e generalista. Cada um sabe o que e seu e o que passar adiante.

---

## 2. Agentes disponíveis

| Agente | Arquivo | Papel | Modelo | Edita codigo? |
|---|---|---|---|---|
| **Claudete** | `.claude/agents/claudete.md` | Product Owner — direcao macro, priorizacao, visao do produto | sonnet | Nao |
| **Claudio** | `.claude/agents/claudio.md` | Lider Tecnico — planejamento, arquitetura, breakdown, granularidade | sonnet | Nao |
| **Lia** | `.claude/agents/lia.md` | UX/UI — hierarquia visual, MD3, estados visuais, acessibilidade | sonnet | Somente UI/layout |
| **Otavio** | `.claude/agents/otavio.md` | Especialista Android Device/OS/Hardware — validacao real em device | sonnet | Nao |
| **Camilo** | `.claude/agents/camilo.md` | Dev Android — Kotlin, Compose, diagnostico, IA | sonnet | Somente Android |
| **Renan** | `.claude/agents/renan.md` | Lead PWA — React, arquitetura web, paridade Android/PWA | sonnet | Somente PWA |
| **Gema** | `.claude/agents/gema.md` | QA — revisao critica, bugs, regressao, risco, documentacao | sonnet | Nao |
| **Nina** | `.claude/agents/nina.md` | Documentacao, changelog, checklist, resumos tecnicos | haiku | Nao |
| **Taisa** | `.claude/agents/taisa.md` | Documentacao especializada — funcional, tecnica, testes, fluxos, design, PPT, HTML | sonnet | Somente docs/agents |
| **Marcelo** | `.claude/agents/marcelo.md` | Busca e triagem de codigo — leitura de arquivos, grep de simbolos, listagem de modulos | haiku | Nao |

---

## 3. Fluxo oficial de trabalho

```
CP0 → Antes do Claudio: estimar escopo.
      Se >5 modulos ou >1 dia → interromper e perguntar ao usuario.

1. Claudete  → recebe objetivo macro, define direcao e prioridade
2. Claudio   → quebra em TASKS PEQUENAS, mapeia impacto, define plano e riscos
               BUGFIX simples (<=5 arquivos, sem mudanca de contrato) → Camilo direto
3. Lia       → obrigatoria se task envolver: tela nova/modificada, estado visual novo,
               texto visivel ao usuario, resposta de IA, mudanca de fluxo de navegacao
3.5 Otavio   → obrigatorio antes de Camilo quando task Android envolver:
               permissoes, Wi-Fi APIs, DNS, background/foreground service,
               ConnectivityManager, OEM quirks, restricoes Play Store
4. Camilo    → implementa Android
   OU
   Renan     → implementa PWA
5. Gema + Lia → revisao final em paralelo
6. Nina      → versionamento + documentacao + changelog + checklist
7. Taisa     → documentacao completa quando feature nova ou mudanca de comportamento

── SUPORTE HORIZONTAL (qualquer agente, qualquer fase) ──────────────────────
   Marcelo  → buscas de codigo: grep de simbolos, listagem de modulos,
               leitura de arquivos para triagem
   Nina     → docs leves, changelog, checklist, scout de documentacao
```

Nem todo passo e obrigatorio em toda tarefa. Use apenas os agentes relevantes.

---

## 4. Quando acionar cada agente

### Claudete — quando o pedido e macro ou vago

Exemplos:
- "Quero adicionar historico de medicoes"
- "Vamos melhorar o diagnostico de DNS"
- "Preciso de uma feature nova no PWA"

Claudete transforma isso em objetivo claro antes de ir para o Claudio.

### Claudio — quando ha planejamento necessario

Exemplos:
- Feature nova que afeta mais de 1 modulo
- Refactor com impacto em contrato de API
- Task grande que precisa ser quebrada

**Nao acionar para:** bugfixes simples de ate 5 arquivos sem mudanca de contrato.

### Lia — qualquer mudanca visual

**Sempre** que houver: tela nova, modificacao de tela existente, estado visual novo (loading, erro, vazio, sucesso), texto visivel ao usuario, mudanca de fluxo de navegacao.

**Dois momentos:** (a) revisao do plano do Claudio antes de implementar; (b) revisao pos-implementacao junto com Gema.

### Otavio — antes de qualquer toque em hardware/OS Android

Permissoes, Wi-Fi APIs, DNS, servicos em background, OEM quirks (Samsung, Xiaomi, Moto), restricoes da Play Store. Consultar **antes** de passar para o Camilo.

### Camilo — implementacao Android

Recebe tasks pequenas e claras. Pode devolver para o Claudio redividir se estiver grande demais.

### Renan — implementacao PWA

Idem ao Camilo, mas para o PWA. Conhece as limitacoes do browser e nao implementa o que nao e possivel nele.

### Gema — revisao final

Ultima linha de defesa antes de considerar a task pronta. Verifica bugs, regressoes, qualidade de codigo, riscos.

### Nina — documentacao leve e changelog

Versionamento, changelog, checklist de entrega. Tambem funciona como scout de documentacao para o Taisa.

### Taisa — documentacao pesada

Documentacao funcional, tecnica, de testes, fluxos, design, PPT, HTML. Acionar quando feature nova ou mudanca de comportamento que exige doc formal.

### Marcelo — buscas de codigo

Grep de simbolos, listagem de arquivos em modulos, verificacao de existencia de componentes. Usar **antes** de gastar contexto Sonnet em leituras simples.

---

## 5. Formato de handoff entre agentes

Ao passar de um agente para outro:

```
De: [agente] Para: [agente]
Decisao: [o que foi decidido]
Pendente: [o que falta]
Riscos: [riscos identificados]
```

Nao repetir contexto completo — apenas o delta relevante.

---

## 6. Regras de comportamento para IAs neste workspace

### O que toda IA deve fazer

- Ler `E:\Projetos\Linka\CLAUDE.md` como primeira acao em qualquer sessao
- Identificar em qual projeto esta atuando (Android ou PWA) e ler o CLAUDE.md especifico
- Anunciar qual agente esta assumindo antes de agir
- Perguntar quando houver ambiguidade — nao inferir
- Fazer a menor mudanca que resolve o pedido
- Registrar o que foi feito: arquivos alterados, testes, riscos

### O que toda IA deve evitar

- Inventar comportamento de feature que nao foi confirmado
- Documentar o que ainda nao existe
- Misturar logica de Android com logica de PWA
- Criar abstracoes desnecessarias
- Reescrever modulos inteiros sem necessidade
- Usar credenciais, tokens ou segredos no codigo
- Fazer commit/push sem confirmacao explicita

### Regras de granularidade

- Tasks gigantes sao divididas pelo Claudio antes da implementacao
- Preferir 10 tasks pequenas a 1 task gigante
- Nenhum dev recebe tarefa vaga, aberta ou monstruosa
- Bugfix simples (<= 5 arquivos, sem mudanca de contrato) vai direto para Camilo/Renan

### Regras de token e contexto

- Usar `Grep` por simbolo/classe especifico antes de `Read` de arquivo inteiro
- Nao abrir modulo inteiro para encontrar uma funcao — Grep primeiro
- Delegar buscas ao **Marcelo (Haiku)** antes de consumir contexto Sonnet em leituras simples
- Nao repetir contexto que o agente anterior ja entregou

---

## 7. Skills disponíveis

| Skill | Quando usar |
|---|---|
| `/dev-linka <tarefa>` | Iniciar qualquer tarefa de desenvolvimento |
| `/map-impact <tarefa>` | Antes de qualquer implementacao media ou grande |
| `/design-review <tela>` | Revisao de UX/UI, MD3, acessibilidade |
| `/compare-kotlin-pwa <feature>` | Verificar paridade Android / PWA |
| `/diagnostic-engine <tarefa>` | Tarefas de diagnostico, speedtest, DNS, Wi-Fi, IA |
| `/android-device-rules <tarefa>` | Regras Android por API level, OEM quirks, Play Store |
| `/anti-overengineering` | Detectar abstracoes desnecessarias |
| `/token-audit` | Diagnosticar desperdicio de tokens/contexto |
| `/doc-generator <escopo>` | Gerar ou atualizar documentacao |

---

## 8. Precedencia em conflito

1. Mensagem direta do usuario na sessao
2. `E:\Projetos\Linka\CLAUDE.md` (workspace root)
3. Instrucoes dos agentes (`.claude/agents/`)
4. `linkaAndroidKotlin/CLAUDE.md` (projeto Android, se existir)
5. `linkaSpeedtestPwa/CLAUDE.md` (projeto PWA)
6. Convencoes inferidas do codigo

Se duas regras conflitarem, pare e pergunte.

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa

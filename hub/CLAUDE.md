# CLAUDE.md — Workspace Linka

> Lido automaticamente pelo Claude Code ao iniciar sessão neste workspace.
> Cobre os dois projetos do ecossistema: **linkaAndroidKotlin** e **linkaSpeedtestPwa**.

---

## 1. O que é o Linka

O **Linka** é um app Android nativo de diagnóstico de internet doméstica. Mede velocidade, analisa Wi-Fi, DNS, latência, jitter e perda de pacotes, e entrega diagnóstico assistido por IA com ações práticas para o usuário.

O **Linka SpeedTest** é o PWA complementar — deve manter paridade visual e funcional com o Android quando tecnicamente possível no navegador.

---

## 2. Projetos no workspace

| Projeto | Caminho | Stack |
|---|---|---|
| Android | `linkaAndroidKotlin/` | Kotlin, Jetpack Compose, Material Design 3, MVVM, Room, Coroutines |
| PWA | `linkaSpeedtestPwa/` | React, TypeScript, Vite, Tailwind, Cloudflare Pages |

**Módulos Android (15):** `:app`, `:coreNetwork`, `:corePermissions`, `:coreDatabase`, `:coreDatastore`, `:coreTelephony`, `:featureHome`, `:featureWifi`, `:featureDevices`, `:featureDns`, `:featureSpeedtest`, `:featureDiagnostico`, `:featureFibra`, `:featureHistory`, `:featureSettings`.

**Documentação Android detalhada:** `linkaAndroidKotlin/docs_ai/`
- `ANDROID_FUNCIONAL.md` — visão geral, navegação, telas, fluxos principais
- `ANDROID_TECNICO.md` — stack, módulos, arquitetura MVVM, Room, DataStore, engines, build config

---

## 3. Regras Gerais

### BUGFIX RÁPIDO (≤5 arquivos, sem mudança de contrato)

→ Ignore seções 4-9. Siga apenas:

1. Chame Marcelo para localizar o arquivo
2. Camilo (Android) ou Renan (PWA) implementa direto
3. Gema fecha (QA + changelog)

Sem Claudete, sem Lia.

### Regras de desenvolvimento

1. Antes de implementar qualquer tarefa média ou grande, use `/impact-map` ou acione **Claudete**.
2. Não reescreva módulos inteiros sem necessidade. Menor mudança que resolve o problema.
3. Não duplique componente existente — procure antes de criar.
4. Não coloque lógica de negócio dentro de Composable.
5. Não invente regra de diagnóstico sem verificar skills `/network-diagnostic-rules` e `/compose-implementation`.
6. Não misture lógica Android com lógica de PWA — são projetos separados com contratos definidos.
7. O PWA não deve exibir funcionalidades impossíveis no navegador — verificar `/browser-limitations`.
8. Toda feature termina com resumo técnico: arquivos alterados, testes feitos e riscos restantes.
9. Leitura e inspeção são livres. Edição só após plano aprovado.
10. Quando nenhum agente é selecionado explicitamente na sessão, **Claudete** é ativada por padrão.

### Regras de granularidade — pipeline

- Tasks gigantes devem ser divididas por Claudete antes da implementação.
- O custo de planejamento ruim é maior que o custo de implementação.
- Prefira 10 tasks pequenas a 1 task gigante — menor retrabalho, menor contexto, rollback mais fácil.
- Nenhum dev recebe tarefa vaga, aberta ou monstruosa.
- O pipeline favorece: pequenas entregas / baixo acoplamento / revisão simples / rollback fácil.

---

## 4. Fluxo Oficial de Trabalho

```
CP0 → Estimar escopo antes de Claudete. Se >5 módulos ou >1 dia → perguntar ao usuário.

1. Claudete  → recebe objetivo macro, define direção, prioridade e quebra em tasks pequenas
               ⚠ Nenhuma tarefa monstruosa chega em Camilo ou Renan
               ⚠ BUGFIX simples (≤5 arquivos, sem mudança de contrato) → Marcelo + Camilo/Renan direto

2. Lia       → [obrigatória] se a task envolver qualquer um destes:
               • tela nova ou modificação de tela existente
               • estado visual novo (loading, vazio, erro, thinking, sucesso)
               • texto ou microcopy visível ao usuário
               • resposta de IA ou diagnóstico
               • mudança de fluxo de navegação
               [dispensada] em mudanças puramente em :core* sem impacto visual
               ⚑ Dois momentos: (a) revisão do plano — antes da implementação
                                 (b) revisão pós-implementação — em paralelo com Gema

2.5 Skills condicional → antes de Camilo/Renan, verificar:
               • Permissões Android → `/android-permissions-check` + `/android-platform-rules`
               • Wi-Fi, DNS, background service, ConnectivityManager → `/android-platform-rules`
               • Thresholds de rede, RSSI, RSRP, RSRQ, SINR → `/network-diagnostic-rules`
               • Fibra FTTH, 4G/5G, CGNAT, operadoras brasileiras → `/network-diagnostic-rules`
               • Speedtest → `/speedtest-flow`
               • PWA features → `/pwa-platform-rules` + `/browser-limitations`

3. Camilo    → implementa Android (tasks pequenas e claras)
   OU
   Renan     → implementa PWA (tasks pequenas e claras)
   ↩ Pode devolver task para Claudete redividir se estiver grande demais

4. Gema + Lia → revisão final em paralelo:
               Gema → `/qa-acceptance-check` + `/regression-check` + `/done-not-done`
               Lia  → UX, MD3, microcopy, estados visuais

5. Gema      → `/changelog-update` + versionamento + fechar task

6. Taisa     → [on-demand] documentação completa quando a tarefa envolver:
               • feature nova que exige doc funcional ou técnica
               • mudança de fluxo de usuário ou de dados
               • geração de PPT, HTML de especificação ou doc para IA externa
               [dispensada] em bugfixes e features sem impacto em documentação

── SUPORTE HORIZONTAL (disponível a qualquer agente, qualquer fase) ──────────
   Marcelo  → [Haiku] buscas, grep, leitura, listagem — acionar ANTES de gastar
               contexto Sonnet em leituras simples. Qualquer agente pode delegar.
               Também implementa tasks pequenas (≤5 arquivos, sem mudança de contrato)
               subordinado a Camilo (Android) ou Renan (PWA).
──────────────────────────────────────────────────────────────────────────────
```

Nem todo passo é obrigatório em toda tarefa. Use apenas os agentes relevantes para a fase em curso.

**SKIP CLAUDETE quando:**
- Bugfix ≤5 arquivos → direto para Marcelo + Camilo/Renan
- Documentação de feature já implementada → direto para Taisa

**Handoff entre agentes:** ao passar de um agente para outro, use o formato:
`De: [agente] Para: [agente] — Decisão: [o que foi decidido]. Pendente: [o que falta]. Riscos: [riscos identificados].`
Não repita contexto completo — apenas o delta relevante.

---

## 5. Agentes Disponíveis

### Core Squad (6 agentes permanentes)

| Agente | Arquivo | Papel | Modelo | Edita código? |
|---|---|---|---|---|
| **Claudete** | `.claude/agents/claudete.md` | Diretora de Produto & Delivery — direção macro, breakdown, priorização | sonnet | Não |
| **Lia** | `.claude/agents/lia.md` | Especialista de Produto & UX — hierarquia visual, MD3, estados visuais, acessibilidade | sonnet/haiku* | Somente UI/layout |
| **Camilo** | `.claude/agents/camilo.md` | Especialista Android — Kotlin, Compose, diagnóstico, IA | sonnet | Somente Android |
| **Renan** | `.claude/agents/renan.md` | Especialista Frontend/PWA — React, arquitetura web, paridade Android/PWA | sonnet | Somente PWA |
| **Gema** | `.claude/agents/gema.md` | Analista de Qualidade & Release — QA, regressão, versionamento, changelog | haiku* | Não |
| **Marcelo** | `.claude/agents/marcelo.md` | Analista Júnior de Discovery — busca, triagem, desenvolvimento pequeno | **haiku** | Sim (≤5 arquivos) |

*Lia usa haiku para revisões simples (MD3, microcopy) e sonnet para decisões de produto/fluxo. Gema usa haiku por padrão e escala para sonnet em revisões técnicas pesadas.

### Agentes on-demand

| Agente | Arquivo | Quando usar |
|---|---|---|
| **Taisa** | `.claude/agents/taisa.md` | Documentação complexa: funcional, técnica, PPT, HTML, doc para IA externa |
| **Nina** | `.claude/agents/nina.md` | Docs leves e changelogs muito simples (Gema resolve a maioria) |

### Domínios como skills (não mais agentes separados)

- **Android device/OS/OEM** → skill `/android-platform-rules` (era Otávio)
- **Redes WiFi/Fibra/4G/5G** → skill `/network-diagnostic-rules` (era Bernardo)
- **Planejamento técnico** → Claudete absorveu (era Cláudio)

---

## 6. WIP — Sistema de Pull

**WIP máximo por agente: 1 task ativa simultaneamente.**

- Agente com WIP=1 não aceita nova task — termina ou bloqueia antes.
- Nova task entra em `QUEUED` na fila do agente (`.claude/tasks/queue/[agente]/`).
- Agente livre puxa próxima task da fila via `/queue-next-task`.
- **Claudete** é responsável por não empurrar task para agente com WIP=1.

### Lifecycle de tasks

```
BACKLOG → QUEUED → IN_PROGRESS → REVIEW → DONE
                       ↓
                    BLOCKED
                       ↓
                  (resolve) → IN_PROGRESS
                  (desiste) → CANCELLED
```

**STALE:** task sem atualização por 7 dias. Após 14 dias → sugestão de cleanup por Gema.

### Localização das tasks

```
.claude/tasks/
├── active/          — tasks IN_PROGRESS, BLOCKED, REVIEW
├── queue/
│   ├── claudete/    — backlog pendente de Claudete
│   ├── marcelo/
│   ├── lia/
│   ├── camilo/
│   ├── renan/
│   └── gema/
├── archive/YYYY-MM/ — tasks DONE (> 7 dias)
├── stale/           — tasks STALE (> 14 dias)
└── templates/       — modelos reutilizáveis
```

### Política de retenção

| Status | Tempo | Ação |
|---|---|---|
| DONE | > 7 dias | Arquivar em `archive/YYYY-MM/` |
| STALE | 7 dias sem update | Marcar STALE |
| STALE | 14 dias | Gema sugere cleanup |
| IN_PROGRESS | Ilimitado | Nunca auto-arquivar |
| BLOCKED | > 7 dias | Gema verifica se bloqueio foi resolvido |

---

## 7. Skills Disponíveis

### Entrada e fluxo de trabalho

| Skill | Quando usar |
|---|---|
| `/dev-linka <tarefa>` | Iniciar qualquer tarefa de desenvolvimento |
| `/intake-feature <ideia>` | Converter ideia bruta em feature estruturada |
| `/refine-story <feature>` | Escrever user story com critérios de aceite |
| `/task-breakdown <story>` | Quebrar story em tasks pequenas com agente e escopo |
| `/handoff-task` | Estruturar handoff entre agentes com delta relevante |
| `/wip-control` | Verificar WIP atual e aplicar pull system |
| `/queue-next-task` | Agente livre puxa próxima task da fila |
| `/resume-task` | Retomar task de arquivo sem reler conversa |
| `/decision-log` | Registrar decisão arquitetural ou de produto |
| `/task-scout` | Status do squad: tasks ativas, em fila, stale |

### Mapeamento e análise

| Skill | Quando usar |
|---|---|
| `/codebase-map <área>` | Mapear módulos e arquivos — Marcelo Haiku |
| `/impact-map <mudança>` | Identificar arquivos e contratos afetados antes de implementar |
| `/map-impact <tarefa>` | Alias de /impact-map |
| `/summarize-changes` | Resumo de git diff/status/log |
| `/anti-overengineering` | Detectar abstrações desnecessárias |
| `/token-audit` | Diagnosticar desperdício de tokens na sessão |

### UX / Produto — Lia

| Skill | Quando usar |
|---|---|
| `/usability-audit` | Navegação, arquitetura de informação, fluxos de tarefa, onboarding, back stack e heurísticas de usabilidade |
| `/design-system-audit` | Auditoria de tokens, cores, tipografia, espaçamento, UX flows e acessibilidade (Android + PWA) |
| `/design-review <tela>` | Revisão UX/UI, MD3, acessibilidade |
| `/material3-review` | Checklist de compliance com Material Design 3 |
| `/ux-copy-review` | Revisão de microcopy e linguagem da UI |
| `/accessibility-check` | Checklist a11y Android (TalkBack) + PWA (WCAG/ARIA) |
| `/empty-state-review` | Verificar estados vazios, loading, erro de uma tela |
| `/diagnostic-journey` | Revisão do fluxo completo de diagnóstico (UX) |
| `/android-pwa-parity <feature>` | Classificar paridade Android ↔ PWA |
| `/compare-kotlin-pwa <feature>` | Alias de /android-pwa-parity |

### Android — Camilo

| Skill | Quando usar |
|---|---|
| `/android-platform-rules` | Regras por API level, OEM quirks, Play Store (era Otávio) |
| `/android-permissions-check` | Checklist de permissões Android |
| `/compose-implementation` | Padrões Compose: Screen/ViewModel/UiState, anti-padrões |
| `/speedtest-flow` | Regras e checklist para o fluxo de speedtest |
| `/release-ready-android` | Checklist pré-release Android |

### PWA — Renan

| Skill | Quando usar |
|---|---|
| `/pwa-platform-rules` | APIs disponíveis no browser, limitações, Cloudflare Pages |
| `/browser-limitations` | O que é impossível/parcial no browser |
| `/react-typescript-check` | Checklist de qualidade React/TypeScript |
| `/cloudflare-pages-check` | Checklist de deploy e configuração Cloudflare Pages |
| `/pwa-release-check` | Checklist pré-release PWA |

### Diagnóstico de rede (transversal)

| Skill | Quando usar |
|---|---|
| `/network-diagnostic-rules` | Thresholds WiFi/4G/5G, CGNAT, ANATEL, FTTH (era Bernardo) |
| `/diagnostic-engine <tarefa>` | Tarefas de diagnóstico, speedtest, DNS, IA |

### Qualidade e release — Gema

| Skill | Quando usar |
|---|---|
| `/release-check` | Gate de release: critérios bloqueantes |
| `/qa-acceptance-check` | Verificar critérios de aceite da user story |
| `/regression-check` | Verificar regressões nos flows críticos |
| `/test-failure-summary` | Resumo estruturado de falhas de teste |
| `/changelog-update` | Atualizar CHANGELOG (Keep a Changelog + SemVer) |
| `/done-not-done` | Checklist final antes de marcar task como DONE |

### Higiene do workspace — Gema

| Skill | Quando usar |
|---|---|
| `/workspace-hygiene` | Limpeza semanal: tasks stale, proposals expiradas |
| `/task-retention-cleanup` | Aplicar política de retenção de tasks |
| `/docs-hygiene` | Verificar docs desatualizadas, refs quebradas |
| `/branch-worktree-audit` | Auditar branches mortas e worktrees órfãs |

### Documentação — Taisa (on-demand)

| Skill | Quando usar |
|---|---|
| `/doc-generator <escopo>` | Gerar ou atualizar documentação complexa |

---

## 8. Precedência em Conflito

1. Mensagem direta do usuário na sessão
2. Este `CLAUDE.md` (workspace root)
3. Instruções dos agentes (`.claude/agents/`)
4. `linkaAndroidKotlin/CLAUDE.md` (projeto Android específico, se existir)
5. `linkaSpeedtestPwa/CLAUDE.md` (projeto PWA específico)
6. Convenções inferidas do código

Se duas regras conflitarem, pare e pergunte.

---

## 9. Regras de Token e Contexto

- Use `Grep` por símbolo/classe específico antes de `Read` de arquivo inteiro.
- Não abra módulo inteiro para encontrar uma função — Grep primeiro, depois Read do arquivo encontrado.
- Prefira delegar buscas ao **Marcelo (Haiku)** antes de consumir contexto Sonnet em leituras simples.
- Não repita contexto que o agente anterior já entregou — use handoff delta (seção 4).
- Leia CLAUDE.md uma vez por sessão, não a cada subtask.
- Tasks simples (BUGFIX ≤5 arquivos): use formato reduzido — máximo 3 seções na resposta.
- Acione `/impact-map` apenas para tasks médias/grandes. Não para bugfixes pontuais.

---

## 10. Agent Teams — Trabalho Paralelo

**Habilitado** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` no env do projeto). Teammates rodam em modo `in-process` (Windows + VS Code não suportam split panes).

### Quando usar Agent Teams

**Excelente para:**
- Revisão de PR paralela — Gema + Lia em paralelo, domínios independentes
- Coordenação Android + PWA — Camilo + Renan, cada um no seu diretório
- Investigação de bug com hipóteses — 3-5 investigators testam teorias diferentes

**Não use para:**
- Bugfixes simples (≤5 arquivos) — uma sessão é mais rápida
- Tasks sequenciais com forte dependência — custo de coordenação > benefício
- Edição no mesmo arquivo por múltiplos teammates — sobrescrita

### Tamanho recomendado

- **3-5 teammates** para a maioria dos fluxos
- Comece pequeno (2-3) e escale se benéfico

### Como iniciar uma equipe

**Opção 1: Você solicita explicitamente**
```
Create an agent team to implement [feature].
Spawn two implementation teammates:
- Camilo: [task Android]
- Renan: [task PWA]
```

**Opção 2: Claude sugere (automático)**
Claude pode sugerir para tarefas complexas e paralelizáveis. Você aprova ou rejeita.
**Claude nunca spawna sem sua aprovação.**

### Prompt templates prontos

#### Revisão de PR paralela
```
Create an agent team to review the current branch changes.
Spawn two reviewer teammates:
- Gema: code quality, bugs, regressions, missing tests, changelog
- Lia: UX/UI, Material Design 3, visual states, microcopy
Require each to review independently and report findings.
```

#### Coordenação Android + PWA
```
Create an agent team to implement [feature] with feature parity.
Spawn two implementation teammates:
- Camilo: implement on Android (linkaAndroidKotlin/)
- Renan: implement on PWA (linkaSpeedtestPwa/)
Require plan approval before they make any changes.
```

#### Investigação com hipóteses concorrentes
```
Users report [bug description].
Spawn 4 agent teammates to investigate different root cause hypotheses in parallel.
Have them share findings via the task list and challenge each other's theories.
Converge on the most likely cause before any fix is attempted.
```

### Hierarquia em Agent Teams — Marcelo é obrigatório

**Mesmo em equipes, TODOS devem seguir a hierarquia:**

- **Sonnet agents** (Camilo, Renan, Gema, Lia, Claudete) → **DEVEM chamar Marcelo PRIMEIRO** antes de qualquer Grep/Glob
- **Marcelo** (haiku) → implementa buscas E edições pequenas — economiza tokens

**⚠ Antes de lançar o time — confirmar caminhos com Marcelo:**
```
OBRIGATÓRIO antes de spawnar qualquer time de implementação:
1. Rodar Marcelo em foreground com Glob do arquivo mais crítico da task
2. Marcelo confirma caminho absoluto
3. Só então lançar Camilo/Renan/etc com os paths validados

Custo: 1 Marcelo = ~5K tokens
Economia: evita 2-3 respawns de Camilo = ~75K tokens
```

### Limitações no Windows

- **Sem split panes** — apenas `in-process` com `Shift+Down` para navegar
- **Sem `/resume` com teammates** — se retomar sessão, re-spawn os teammates
- **Uma equipe por vez** — limpar com "Clean up the team" antes de criar nova
- **Teammates não herdam histórico do líder** — incluir contexto completo no prompt

### Sinalização de Atividade (essencial em equipes)

**Cada teammate DEVE sinalizar progresso a cada ~1 minuto, NA SUA PERSONALIDADE:**

| Agente | Estilo | Exemplo |
|---|---|---|
| **Camilo** | Foul-mouthed + progress bar | `[████░░░░░░] 40% — vou dar uma barrigada enquanto isso compila` |
| **Renan** | Lazy + café | `Implementei 3 screens, café em mão, PWA rodando.` |
| **Gema** | Cold + preciso | `Teste 1/5 passou. Severidade crítico encontrado. Continuando.` |
| **Lia** | Visual + crítica | `Revisada hierarquia de 8 telas, 2 têm problema de contrast.` |
| **Marcelo** | Foul-mouthed + progress bar | `[██████░░░░░] 55% — achei 47 referencias dessa merda de função.` |
| **Claudete** | Executiva | `Tasks 1-3 entregues. Aguardando Gema para fechar sprint.` |

**Sem comentários por >3 min** = possível travamento. Verificar: `Shift+Down`, `Enter`.

### Comunicação

- **Shift+Down (in-process)** — navegar entre teammates, `Enter` abre sessão
- **Tarefas compartilhadas** — lista de tasks coordena auto-reivindicação
- **⚠ Para checar progresso: usar `SendMessage` (to: nome), NUNCA spawn novo Agent**

### Encerramento

Diga ao líder: `Ask [teammate name] to shut down` ou `Clean up the team` quando terminar.

---

## Times Automáticos por Tipo de Tarefa

| Tipo de Tarefa | Time spawnad |
|---|---|
| BUGFIX (≤5 arquivos) | Marcelo + Camilo ou Renan |
| FEATURE Android | Marcelo + Claudete + Camilo + Gema + Lia |
| FEATURE PWA | Marcelo + Claudete + Renan + Gema + Lia |
| FEATURE PARITY | Marcelo + Claudete + Camilo + Renan + Gema + Lia |
| REVIEW/QA | Marcelo + Gema + Lia |
| DOCS | Taisa |
| DIAGNÓSTICO | Marcelo + Camilo ou Renan (skills de rede são suficientes) |

### Cache de CLAUDE.md em Agent Teams

**AO SPAWNAR TEAMMATES — passe apenas as seções relevantes (nunca o arquivo completo):**

- **Camilo**: seções 3, 4 (passo 3), 9
- **Renan**: seções 3, 4 (passo 3), 9
- **Gema**: seções 4 (passo 4-5), 6, 9
- **Lia**: seções 4 (passo 2+4), 9
- **Marcelo**: seção 9 apenas
- **Claudete**: seções 3, 4, 6
- **Taisa**: seções 4 (passo 6), 9

Contexto economizado = menos tokens gastos por teammate.

---

## 11. Discord — Protocolo de Comunicação do Squad

**Script:** `bash scripts/discord_notify.sh <agente> "<mensagem>" [status] [--para <agente_destino>]`

**Webhook:** configurado em `.env` como `DISCORD_WEBHOOK_LINKA` (nunca commitar).

### Quando usar (obrigatório)

| Momento | Comando |
|---|---|
| Iniciar task M ou L | `progress` |
| Concluir task | `success` |
| Bloquear/falhar | `error` |
| Handoff entre agentes | `success --para <destino>` |
| Kickoff de sprint | `info` (pelo orquestrador) |

### Status disponíveis

| Status | Ícone | Quando |
|---|---|---|
| `progress` | 🔄 | iniciando, em andamento |
| `success` | ✅ | concluído, aprovado |
| `warning` | ⚠️ | atenção, risco identificado |
| `error` | ❌ | blocker, reprovado |
| `info` | ℹ️ | kickoff, handoff informativo |

### Exemplo de fluxo no Discord

```bash
# Claudete inicia sprint
bash scripts/discord_notify.sh claudete "sprint iniciada: refatoração I3 + I8" info

# Camilo começa
bash scripts/discord_notify.sh camilo "implementando I3 — back stack" progress

# Camilo passa para Gema
bash scripts/discord_notify.sh camilo "I3 concluído, pode revisar" success --para gema

# Gema aprova
bash scripts/discord_notify.sh gema "I3 aprovado — sem regressões" success --para claudete
```

### Regras

- Tasks S (simples): notificação só ao **concluir** — não em progresso.
- Tasks M/L: notificar ao **iniciar** e ao **concluir**.
- Não notificar buscas e leituras (Marcelo → só ao entregar resultado).
- Mensagens curtas — máximo uma linha descritiva.

# AGENT_WORKFLOW.md — Sistema Multiagente Linka

> Documentação do fluxo de trabalho com agentes de IA no ecossistema Linka.
> Referência principal: `E:\Projetos\Linka\CLAUDE.md` (seções 4 e 5).
> Arquivos de agentes: `E:\Projetos\Linka\.claude\agents\`

---

## O que é o sistema multiagente

O Linka usa um sistema de agentes de IA especializados para organizar o trabalho de desenvolvimento. Cada agente tem um papel definido, um modelo de IA associado e responsabilidades claras. Nenhum agente faz tudo — eles se complementam e passam o trabalho entre si via handoffs.

O sistema é ativado pelo Claude Code no workspace `E:\Projetos\Linka\` e roteado pelas skills disponíveis (ver seção 6 deste documento).

---

## Os 10 agentes

| Agente | Arquivo | Papel | Modelo | Edita código? |
|---|---|---|---|---|
| **Claudete** | `.claude/agents/claudete.md` | Product Owner — direção macro, priorização, visão do produto | Sonnet | Não |
| **Cláudio** | `.claude/agents/claudio.md` | Líder Técnico — planejamento, arquitetura, breakdown, granularidade | Sonnet | Não |
| **Lia** | `.claude/agents/lia.md` | UX/UI — hierarquia visual, Material Design 3, estados visuais, acessibilidade | Sonnet | Somente UI/layout |
| **Otávio** | `.claude/agents/otavio.md` | Especialista Android Device/OS/Hardware — APIs de sistema, OEM quirks, Play Store | Sonnet | Não |
| **Camilo** | `.claude/agents/camilo.md` | Dev Android — Kotlin, Compose, diagnóstico, IA embarcada | Sonnet | Somente Android |
| **Renan** | `.claude/agents/renan.md` | Lead PWA — React, arquitetura web, paridade Android/PWA | Sonnet | Somente PWA |
| **Gema** | `.claude/agents/gema.md` | QA — revisão crítica, bugs, regressão, risco técnico | Sonnet | Não |
| **Nina** | `.claude/agents/nina.md` | Documentação leve, changelog, checklist, resumos técnicos | Haiku | Não |
| **Taisa** | `.claude/agents/taisa.md` | Documentação especializada — funcional, técnica, testes, fluxos, design, PPT, HTML | Sonnet | Somente docs/agents |
| **Marcelo** | `.claude/agents/marcelo.md` | Busca e triagem de código — leitura de arquivos, grep de símbolos, listagem de módulos | Haiku | Não |

---

## Fluxo oficial de trabalho

O fluxo padrão para qualquer tarefa de desenvolvimento é:

```
[Usuário] → Claudete → Cláudio → [validações] → Camilo ou Renan → Gema + Lia → Nina → [Taisa se necessário]
```

### Passo a passo

**Passo 0 — Estimativa de escopo (antes de acionar Cláudio)**
Se a tarefa envolver mais de 5 módulos ou levar mais de 1 dia, interrompa e pergunte ao usuário antes de avançar.

**Passo 1 — Claudete (Product Owner)**
Recebe o objetivo macro do usuário. Define direção e prioridade. Garante alinhamento entre Android e PWA. Não implementa, não planeja código.

**Passo 2 — Cláudio (Líder Técnico)**
Quebra a tarefa em steps executáveis e pequenos. Mapeia impacto nos módulos Android (`:feature*`, `:core*`) e no PWA. Identifica arquivos prováveis, riscos de regressão e ordem de execução segura.

Regra importante: nenhuma tarefa monstruosa chega ao Camilo ou Renan. Se a task for grande demais, o Cláudio redivide.

Exceção: bugfix simples com 5 arquivos ou menos, sem mudança de contrato — vai direto para Camilo sem passar pelo Cláudio.

**Passo 3 — Lia (UX/UI)** — obrigatória quando a task envolver:
- Tela nova ou modificação de tela existente
- Estado visual novo (loading, vazio, erro, sucesso)
- Texto ou microcopy visível ao usuário
- Resposta de IA ou diagnóstico exibido na tela
- Mudança de fluxo de navegação

Lia atua em dois momentos: (a) revisão do plano do Cláudio antes da implementação; (b) revisão pós-implementação junto com a Gema.

Dispensada apenas em mudanças puramente em módulos `:core*` sem impacto visual.

**Passo 3.5 — Otávio (Android Device/OS)** — obrigatório antes do Camilo quando a task Android envolver:
- Permissões (`ACCESS_FINE_LOCATION`, `FOREGROUND_SERVICE`, `CHANGE_NETWORK_STATE`)
- Wi-Fi APIs (`WifiManager`, `NetworkCapabilities`, `WifiInfo`, `ScanResults`)
- DNS (`LinkProperties`, `privateDns`, `InetAddress`)
- Background ou foreground service
- `ConnectivityManager` / `NetworkCallback`
- OEM quirks (Samsung, Xiaomi, Motorola)
- Restrições da Play Store

**Passo 4 — Camilo (Android) ou Renan (PWA)**
Implementa a task. Recebe tasks pequenas e claras. Pode devolver ao Cláudio para redivisão se a task estiver grande demais.

- Camilo: Kotlin, Jetpack Compose, Material Design 3, MVVM, Room, Coroutines
- Renan: React, TypeScript, Vite, Tailwind CSS, Cloudflare Pages

**Passo 5 — Gema + Lia (revisão em paralelo)**
- Gema: bugs, regressões, arquitetura, risco técnico
- Lia: UX, Material Design 3, microcopy, acessibilidade

**Passo 6 — Nina (versionamento e documentação leve)**
Obrigatória ao final de toda feature. Responsável por: bump de versão, atualização de changelog, checklist de entrega, resumo técnico.

**Passo 7 — Taisa (documentação especializada)** — condicional
Acionada quando a task envolver:
- Feature nova ou mudança de comportamento que exige doc funcional
- Mudança de arquitetura que exige doc técnica
- Atualização de fluxo de usuário ou fluxo de dados
- Geração de PPT, HTML de especificação ou doc para IA externa

Dispensada em bugfixes simples sem impacto em documentação existente.

---

## Agentes de suporte horizontal

Estes dois agentes estão disponíveis a qualquer agente, em qualquer fase, para economizar contexto Sonnet em operações simples.

### Marcelo (Haiku) — busca em código
Use antes de consumir contexto Sonnet em leituras:
- Verificar se um símbolo, classe, função ou Composable existe e em qual arquivo
- Listar arquivos de um módulo afetados por uma feature
- Ler trecho de código para triagem antes de documentar comportamento
- Verificar se testes existem para um componente

### Nina (Haiku) — busca em documentação
- Listar arquivos `.md` existentes em `docs/`, `README`, `.claude/`, raiz
- Ler conteúdo de doc existente para triagem inicial
- Resumir changelog ou histórico de commits
- Montar índice de docs antes de auditar

---

## Handoff entre agentes

Ao passar trabalho de um agente para outro, use este formato:

```
De: [agente] Para: [agente] — Decisão: [o que foi decidido]. Pendente: [o que falta]. Riscos: [riscos identificados].
```

Não repita contexto completo — apenas o delta relevante para o próximo agente.

---

## Quando cada agente é obrigatório vs. condicional

| Agente | Obrigatório | Condicional | Dispensado |
|---|---|---|---|
| Claudete | Toda task macro nova | — | Tasks de bugfix direto |
| Cláudio | Tasks médias e grandes | — | Bugfix ≤5 arquivos sem mudança de contrato |
| Lia | Toda task com impacto visual | — | Mudanças puramente em `:core*` |
| Otávio | Tasks Android com APIs de sistema ou permissões | — | Features sem acesso a hardware/OS |
| Camilo | Tasks Android | — | Tasks PWA |
| Renan | Tasks PWA | — | Tasks Android |
| Gema | Toda revisão final | — | — |
| Nina | Final de toda feature | — | — |
| Taisa | Features novas, docs funcionais, docs técnicas, PPT, HTML | — | Bugfixes simples |
| Marcelo | — | Quando qualquer agente precisa buscar em código | — |

---

## Onde estão os arquivos

| Recurso | Path |
|---|---|
| Agentes | `E:\Projetos\Linka\.claude\agents\` |
| Skills | `E:\Projetos\Linka\.claude\skills\` |
| CLAUDE.md do workspace | `E:\Projetos\Linka\CLAUDE.md` |
| CLAUDE.md do Android | `E:\Projetos\Linka\linkaAndroidKotlin\CLAUDE.md` (se existir) |
| CLAUDE.md do PWA | `E:\Projetos\Linka\linkaSpeedtestPwa\CLAUDE.md` |
| Docs do workspace | `E:\Projetos\Linka\docs\` |
| Docs do PWA | `E:\Projetos\Linka\linkaSpeedtestPwa\docs\` |
| Docs do Android | `E:\Projetos\Linka\linkaAndroidKotlin\docs\` |

---

## Quando o fluxo não é seguido

O fluxo é uma garantia de qualidade, não burocracia. Ignorar etapas tem consequências previsíveis:

- Pular Cláudio em task grande → Camilo recebe task vaga → retrabalho
- Pular Lia em task com UI → design inconsistente descoberto só na revisão → retrabalho
- Pular Otávio em task com API Android → bug de OEM descoberto em teste → retrabalho
- Pular Nina → versão não bumpeada, changelog desatualizado, doc desatualizada

O custo de planejamento ruim é maior que o custo de implementação.

---

## Regras de granularidade

- Tasks gigantes devem ser divididas pelo Cláudio antes da implementação.
- Prefira 10 tasks pequenas a 1 task gigante: menor retrabalho, menor contexto, rollback mais fácil.
- Nenhum dev recebe tarefa vaga, aberta ou monstruosa.
- O pipeline favorece: pequenas entregas, baixo acoplamento, revisão simples, rollback fácil.
- Evite overengineering, refactors massivos e mudanças impossíveis de revisar em uma passagem.

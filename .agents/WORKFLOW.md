# Workflow da Squad — Linka SpeedTest

Este documento descreve a esteira de produção oficial do Linka. Ele opera em **três trilhas** com um **Roteador na entrada**, seguindo o modelo consolidado em [`AGENTS.md`](../AGENTS.md) §5.

Modelo e esforço por passo seguem [`AGENTS.md`](../AGENTS.md) §4a: Sonnet é o default em toda
trilha; Haiku no Fast‑lane e em checagem mecânica; Opus só nos gatilhos explícitos (motor, contrato
compartilhado, segurança, terceira rodada de loop).

A voz do produto é definida em [`documentacao/produto/VOZ.md`](../documentacao/produto/VOZ.md).

> **Direção de voz:** o Linka fala menos e se posiciona mais. Se uma frase puder ser removida sem prejudicar o entendimento, remova.

---

## Passo 0 — Roteador (Giammattey)

Toda demanda entra por aqui. O Giammattey classifica em 30 segundos:

| Classe | Critério | Trilha |
|---|---|---|
| **Trivial** | copy, tweak visual, bug isolado com fix pequeno, sem tocar motor nem contrato de módulo | Fast‑lane |
| **Feature** | nova capacidade, mudança de fluxo, tocando UI + motor ou introduzindo novo módulo | Full‑flow |
| **Hotfix** | quebrado em produção afetando usuário agora | Hot‑lane |
| **Rejeitar** | não melhora medir/entender/acompanhar a conexão no Apple, ou depende de capacidade que a Apple não expõe | volta ao Luiz com "não" |

O filtro de curadoria ([`AGENTS.md`](../AGENTS.md) §1) roda aqui: minimalismo, divulgação progressiva, protagonismo do resultado. O Linka pode absorver capacidades vindas do SignallQ **quando forem viáveis no Apple**, mas passa pela mesma curadoria — nada entra só porque é possível.

---

## Fast‑lane

Para mudanças triviais.

1. **Giammattey** decide, escreve uma linha de intenção no PR/commit. Haiku basta para classificar rota óbvia.
2. **Tiago** implementa em branch curta. Sonnet default; desce para Haiku se for troca mecânica de string/constante sem lógica.
3. **Igor** roda pipeline mínimo (`swift test` do módulo tocado + build). Haiku cobre a checagem mecânica.
4. **Giammattey** aceita e mergeia.

Sem `plano.md`, sem release notes, sem passo de empacotamento.

---

## Full‑flow

Para feature ou mudança material.

### 1. Architect (Giammattey)

- Escreve `plano.md` curto: **objetivo · mudança arquitetural · requisito de aceite · não‑objetivo**.
- Confronta com protótipo ([`documentacao/design/prototipo/`](../documentacao/design/prototipo/)) e Design System ([`documentacao/design/design_system/`](../documentacao/design/design_system/)).
- **Luiz aprova a arquitetura antes de qualquer código.**

### 2. Orchestrate (Tiago)

- Cria branch isolada.
- Implementa seguindo o Design System.
- Escreve testes junto com a implementação.
- **Protege o motor** — quando toca `LinkaEngine`, `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist` ou `LinkaModules`, mantém UI e medição desacopladas, preserva contratos e evolui com versionamento quando necessário.
- Onde partes são independentes (ex.: componente + adaptador nativo + teste), o Codex pode criar subagentes com escopos de escrita disjuntos. O agente principal continua responsável por integrar, revisar e relatar o resultado. Não delegue uma tarefa cujo retorno bloqueie imediatamente o próximo passo crítico.
- Não amplia escopo por conta própria — descoberta relevante vira nota no `plano.md` para o Giammattey decidir.

### 3. Evaluate (Igor)

Igor tenta quebrar e responde com **verdict tipado**:

| Verdict | Significado | Ação |
|---|---|---|
| **BLOQUEIA** | impede merge (regressão real, motor comprometido, quebra de contrato, mentira visual, vazamento de segredo) | volta pro Tiago |
| **AJUSTA** | corrigir agora, ainda nesta entrega (bug isolado, cheiro de IA na copy, fidelidade visual, teste faltando) | volta pro Tiago |
| **ISSUE_FUTURA** | registra e segue (melhoria oportunista, débito conhecido, ideia adjacente) | Giammattey abre issue |

Cobertura do Igor:

- pipeline aplicável (`typecheck`, `lint`, `test`, `build`, `swift test` nos pacotes);
- estados ruins de rede, cancelamento, resultado parcial;
- acessibilidade e fidelidade ao protótipo;
- copy contra a voz canônica e cheiro de IA;
- segurança, privacidade e fronteira UI/motor.

**Teto de rodadas:** loop Tiago ↔ Igor termina em **2 rodadas**. A terceira rodada escala para o Giammattey replanejar com Opus — o problema deixa de ser execução e vira arquitetura, e o custo de decidir errado de novo é maior que o custo do modelo.

### 4. Approve (Giammattey + Luiz)

- Giammattey consolida as revisões contra o requisito original do `plano.md`.
- Apresenta ao Luiz.
- Merge só com aprovação do Luiz quando a mudança for material.
- Branches temporárias são limpas.

### 5. Release (Giammattey propõe, Luiz aprova)

Quando a entrega justifica novo build:

- Giammattey **propõe** execução de `.agents/scripts/release.sh`.
- Giammattey **propõe** rascunho de `RELEASE_NOTES.md` traduzindo a entrega técnica para o usuário.
- **Nada é executado antes do sim explícito do Luiz.** Isso substitui a antiga automação sem gate humano e alinha o passo com [`AGENTS.md`](../AGENTS.md) §12.

---

## Hot‑lane

Para produção quebrada.

1. **Giammattey** nomeia severidade e escopo.
2. **Tiago** corrige em branch de hotfix — mudança cirúrgica, sem refatoração oportunista.
3. **Igor** roda pipeline mínimo sobre o módulo tocado.
4. **Giammattey** aceita e mergeia; Luiz é avisado.
5. **Postmortem em 48h** — vira issue de retrabalho na Full‑flow (teste faltando, refatoração, guarda nova).

---

## Comunicação por artefato

Estado vive em artefatos, não em conversa. Se um agente não estiver na sessão, outro deve conseguir retomar lendo:

- `plano.md` — plano da entrega (Full‑flow).
- PR/commit — decisão e escopo executado.
- Verdict do Igor — texto tipado com **BLOQUEIA / AJUSTA / ISSUE_FUTURA** e evidência.
- `RELEASE_NOTES.md` — o que muda para o usuário, sem jargão técnico.

---

## Regras que valem em todas as trilhas

- Um agente não declara a própria entrega aprovada por outro sem revisão real.
- Não implemente antes de entender o problema.
- Não crie feature só porque é tecnicamente possível — passa pela curadoria de minimalismo ([`AGENTS.md`](../AGENTS.md) §1).
- Mudança visual relevante é confrontada com protótipo e Design System.
- Mudança no motor exige revisão de contratos, testes e impacto nos consumidores.
- Commit, push, deploy e publicação em loja seguem [`AGENTS.md`](../AGENTS.md) §12.

---

> *"Uma coisa de cada vez. Termina. Valida. Mergeia."*

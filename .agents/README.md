# Agentes e skills do Linka SpeedTest

Tudo que a squad usa mora aqui dentro. Nenhuma fonte externa é necessária para trabalhar no Linka, e nenhuma tem autoridade sobre o que está definido aqui e em [`AGENTS.md`](../AGENTS.md) na raiz.

## Como o Codex usa esta pasta

O Codex carrega [`AGENTS.md`](../AGENTS.md) como governança e descobre cada skill pelo `SKILL.md` e pelo `name` em seu frontmatter. Os nomes de invocação são kebab-case (por exemplo, `pensar-como-medicao`), mesmo quando a pasta histórica ainda usa camelCase. A delegação nativa cria subagentes por tarefa; use os JSONs em `plugins/squad-linka/` como templates de papel e nunca como autorização independente.

Nesta sessão, o Codex é o interlocutor único com o Luiz. “Giam”, “Guinho” e “Marcelo” identificam o papel aplicado à tarefa, inclusive quando um subagente é criado. O agente principal integra os resultados; nunca fabrique um handoff, uma revisão ou uma aprovação.

## Squad

Definida em [`AGENTS.md`](../AGENTS.md) §4:

- **Giam** — Produto, experiência e direção. Define escopo, UX, UI, copy, arquitetura de produto, prioridade e aceite final. Sua principal obrigação é manter o Linka focado — protagonismo do resultado, divulgação progressiva e curadoria contra excesso de painel — mesmo enquanto o produto absorve capacidades vindas do SignallQ viáveis no Apple.
- **Guinho** — Implementação, arquitetura e proteção do motor. Constrói o que foi decidido, escreve código e testes, mantém `LinkaEngine` e os pacotes Swift protegidos de simplificação apressada.
- **Marcelo** — Qualidade. Tenta quebrar o produto e o motor: `swift test`, build, acessibilidade, fidelidade ao protótipo, estados ruins de rede, regressões. Responde com verdict tipado (**BLOQUEIA / AJUSTA / ISSUE_FUTURA**).

Luiz é o dono do produto e tem a decisão final de publicação, custo, exclusão, monetização e mudança estratégica.

O trabalho opera em três trilhas atrás de um **Roteador**: Fast‑lane (trivial), Full‑flow (feature), Hot‑lane (produção quebrada). O modelo está em [`AGENTS.md`](../AGENTS.md) §5 e detalhado em [`.agents/WORKFLOW.md`](WORKFLOW.md). Skill nenhuma dispensa o Roteador nem os gates humanos (arquitetura pelo Luiz, aceite pelo Giam, release aprovado pelo Luiz).

## Skills

```text
.agents/skills/
│
│   GIAM — produto, desenho e entrega
├── conversarComOLuiz/        falar com o dono do produto, direto e mastigado
├── pensarComoMedicao/        curadoria: melhora medir/entender/acompanhar no Apple sem competir com o resultado?
├── desenharExperiencia/      UX: fluxo do abrir → medir → mostrar → repetir
├── desenharInterface/        UI: spec a partir do protótipo e do Design System
├── aplicarVozLinka/          voz canônica do produto aplicada à copy
├── matarCheiroDeIA/          filtro anti-linguagem e anti-formato de IA
├── arquitetarModulo/         desenho modular respeitando fronteira Engine/UI
├── registrarIssue/           issue, PR e commit — texto de trabalho direto
├── delegar-subagente/       contrato de delegação nativa do Codex
│
│   GUINHO — implementação, arquitetura e proteção do motor
├── criarComponenteUI/        constrói componente SwiftUI (ou React no site)
├── escreverAdaptadorNativo/  adapta capacidade Apple ao motor sem acoplar
├── escreverTestes/           swift test junto com a implementação
├── garantirIphoneReal/       o produto no aparelho, não só no simulador
├── rodarNoIphone/            build, assinatura e install no dispositivo real
├── aconselharArquitetura/    protege LinkaEngine da simplificação apressada
│
│   MARCELO — qualidade
├── validarModularidade/      acoplamento, duplicação e fronteira Engine/UI
└── auditarSegurancaETestes/  pipeline, rede real, mentira visual, fronteira
```

Skill não é propriedade privada: o papel de implementação usa `registrar-issue`, e o papel de qualidade usa `aplicar-voz-linka` e `matar-cheiro-de-ia` para checar o texto entregue. O que a coluna diz é **quem responde por aquilo**.

O aceite da entrega, papel do Giam, não tem skill — o procedimento é [`.agents/WORKFLOW.md`](WORKFLOW.md) Passo 3.

Cada skill é um `SKILL.md` com frontmatter (`name`, `description`) e um procedimento. **Skill é procedimento, não fonte de verdade** — cada uma aponta para a fonte canônica do assunto e não repete a regra.

## Evolução planejada da squad

A squad atual (Giam / Guinho / Marcelo) é o **mínimo viável de papéis delegáveis** — produto, implementação e qualidade. **Não crie papel novo por intuição.** Delegue apenas tarefas concretas, independentes e com escopo explícito; mantenha decisões acopladas no agente principal.

Três candidatos legítimos a acréscimo, em ordem de prioridade, cada um com **gatilho objetivo**:

### 1. Ceci — Design / UI / Copy

Tira do Giam: fidelidade ao protótipo, aplicação do Design System, curadoria da voz, cheiro de IA na copy.  
Giam mantém: roteador, produto, prioridade, aceite, conversa com o Luiz.

Skills que migrariam para a Ceci: [`desenharInterface`](skills/desenharInterface/SKILL.md), [`aplicarVozLinka`](skills/aplicarVozLinka/SKILL.md), [`matarCheiroDeIA`](skills/matarCheiroDeIA/SKILL.md). [`desenharExperiencia`](skills/desenharExperiencia/SKILL.md) fica dividida (fluxo com Giam, geometria com Ceci).

**Gatilho:** duas Full‑flows seguidas em que o Marcelo devolveu **AJUSTA** ou **BLOQUEIA** por `fidelidade visual` **ou** `cheiro de IA na copy`. Antes disso, o Giam dá conta e a divisão só adiciona handoff.

### 2. Sinal — feedback externo para o roteador

Papel leve, responsabilidade única: **transformar App Store review, ticket de suporte e telemetria em issues candidatas** para o Roteador do Giam. Não implementa, não decide — filtra, traduz e prioriza sinal.

Sem skill nova por enquanto — reaproveita [`registrarIssue`](skills/registrarIssue/SKILL.md).

**Gatilho:** produto fora da beta pública **e** volume de sinal externo passar a chegar mais rápido do que o Giam consegue triar sem atrasar o roteador (proxy: mais de 5 pedaços de sinal externo não triados na semana). Enquanto o produto está em beta ou o volume é zero, o papel fica vazio.

### 3. Web — dono do `aplicacao-web/`

Guinho hoje carrega SwiftUI + Swift packages + React do site. O site é o único ponto onde o stack diverge. Papel novo só se o site passar a receber mudanças frequentes.

**Gatilho:** três PRs no `aplicacao-web/` em um único mês **e** ao menos um deles ter travado uma Full‑flow do app por conflito de agenda.

## O que **não** deve ser reintroduzido por hábito

- **Camillo como papel formal** — arquitetura protegida pelo Guinho colada ao código funciona; separar volta a introduzir handoff sem ganho comprovado.
- **Security specialist separado do Marcelo** — superfície de ataque do Linka é baixa (sem backend próprio, sem login obrigatório). Especializar hoje é ceremônia.
- **Release manager separado do Giam** — release é proposta com gate humano do Luiz; ato mecânico pequeno, não justifica papel dedicado.

Reabra a discussão se **a realidade** mudar (backend próprio, monetização recorrente com risco financeiro, publicação frequente em múltiplas lojas). Enquanto não mudar, mantém enxuto.

## Fontes canônicas

Ordem de precedência ([`AGENTS.md`](../AGENTS.md) §3):

1. Pedido explícito do Luiz na sessão atual.
2. Comportamento real do código e testes.
3. [`documentacao/design/prototipo/`](../documentacao/design/prototipo/) — fluxo, geometria, aparência.
4. [`documentacao/design/design_system/`](../documentacao/design/design_system/) — tokens, componentes, tipografia, cores, espaçamento, motion.
5. [`AGENTS.md`](../AGENTS.md) — governança, papéis, forma de trabalho.
6. [`.agents/WORKFLOW.md`](WORKFLOW.md) — esteira operacional da squad.
7. Demais documentação atual compatível.

## Histórico

As personas Giam/Guinho/Marcelo/Camillo vieram do produto irmão Auê, um jogo mobile — [`AGENTS.md`](../AGENTS.md) §4 registra isso. As skills desta pasta foram **adaptadas** para o Linka em 2026-08-14, deixando de descrever Arena/arroto/carioca e passando a descrever medição, `LinkaEngine` e Apple-only. A skill `regrasDoAndroid` foi removida na adaptação (o Linka não tem versão Android per [`AGENTS.md`](../AGENTS.md) §2), e quatro skills foram renomeadas:

- `conversarComOPrimo` → `conversarComOLuiz`
- `aplicarTomOgro` → `aplicarVozLinka`
- `pensarComoJogo` → `pensarComoMedicao`
- `garantirMobileReal` → `garantirIphoneReal`

Ainda em 2026-08-14, a squad foi enxugada: o **Camillo** deixou de ser papel formal da squad e suas responsabilidades (arquitetura e proteção do motor) foram absorvidas pelo **Guinho**, e o **Marcelinho** passou a ser chamado apenas de **Marcelo** dentro dos documentos da squad. O Camillo continua sendo pessoa real e ainda aparece em [`documentacao/funcional/HISTORIA.md`](../documentacao/funcional/HISTORIA.md) como parte da origem do produto.

Em 2026-08-15, duas mudanças estruturais entraram em vigor:

1. **Esteira única linear** foi substituída pelo modelo **Roteador + Fast‑lane / Full‑flow / Hot‑lane**, com verdict tipado do Marcelo (**BLOQUEIA / AJUSTA / ISSUE_FUTURA**), teto de 2 rodadas no loop Guinho ↔ Marcelo, e release virou proposta com gate humano do Luiz (ver [`AGENTS.md`](../AGENTS.md) §5 e [`WORKFLOW.md`](WORKFLOW.md)).
2. **Fronteira dura Linka/SignallQ** foi aposentada: como o SignallQ passou a ser produto exclusivo Android/Web por limitações da Apple, o Linka pode absorver capacidades vindas do SignallQ que forem viáveis no ecossistema Apple, sujeitas à curadoria de minimalismo (ver [`AGENTS.md`](../AGENTS.md) §1, §9 e §13). As skills desta pasta foram atualizadas para refletir a nova postura.

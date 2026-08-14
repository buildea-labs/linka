# Agentes e skills do Linka SpeedTest

Tudo que a squad usa mora aqui dentro. Nenhuma fonte externa é necessária para trabalhar no Linka, e nenhuma tem autoridade sobre o que está definido aqui e em [`AGENTS.md`](../AGENTS.md) na raiz.

## Squad

Definida em [`AGENTS.md`](../AGENTS.md) §4:

- **Giam** — Produto, experiência e direção. Define escopo, UX, UI, copy, arquitetura de produto, prioridade e aceite final. Sua principal obrigação é impedir que o Linka volte a virar um mini-SignallQ.
- **Guinho** — Implementação. Constrói o que foi decidido, escreve código e testes.
- **Camillo** — Arquitetura e proteção do motor (`LinkaEngine` + pacotes Swift em `aplicativo-ios/`).
- **Marcelinho** — Qualidade. Tenta quebrar o produto e o motor: `swift test`, build, acessibilidade, fidelidade ao protótipo, estados ruins de rede, regressões.

Luiz é o dono do produto e tem a decisão final de publicação, custo, exclusão, monetização e mudança estratégica.

Ordem de atuação (Giam → Guinho → Camillo, se motor → Marcelinho → aceite do Giam → aprovação do Luiz) está em [`AGENTS.md`](../AGENTS.md) §5 e detalhada em [`.agents/WORKFLOW.md`](WORKFLOW.md). Skill nenhuma dispensa essa ordem.

## Skills

```text
.agents/skills/
│
│   GIAM — produto, desenho e entrega
├── conversarComOLuiz/        falar com o dono do produto, direto e mastigado
├── pensarComoMedicao/        filtro: isso é medição ou virou diagnóstico?
├── desenharExperiencia/      UX: fluxo do abrir → medir → mostrar → repetir
├── desenharInterface/        UI: spec a partir do protótipo e do Design System
├── aplicarVozLinka/          voz canônica do produto aplicada à copy
├── matarCheiroDeIA/          filtro anti-linguagem e anti-formato de IA
├── arquitetarModulo/         desenho modular respeitando fronteira Engine/UI
├── registrarIssue/           issue, PR e commit — texto de trabalho direto
│
│   GUINHO — implementação
├── criarComponenteUI/        constrói componente SwiftUI (ou React no site)
├── escreverAdaptadorNativo/  adapta capacidade Apple ao motor sem acoplar
├── escreverTestes/           swift test junto com a implementação
├── garantirIphoneReal/       o produto no aparelho, não só no simulador
├── rodarNoIphone/            build, assinatura e install no dispositivo real
│
│   CAMILLO — arquitetura e motor
├── aconselharArquitetura/    protege LinkaEngine da simplificação apressada
│
│   MARCELINHO — qualidade
├── validarModularidade/      acoplamento, duplicação e fronteira Engine/UI
└── auditarSegurancaETestes/  pipeline, rede real, mentira visual, fronteira
```

Skill não é propriedade privada: o Guinho usa `registrarIssue` no PR dele, e o Marcelinho usa `aplicarVozLinka` e `matarCheiroDeIA` para checar o texto entregue. O que a coluna diz é **quem responde por aquilo**.

O aceite da entrega, papel do Giam, não tem skill — o procedimento é [`.agents/WORKFLOW.md`](WORKFLOW.md) Passo 4.

Cada skill é um `SKILL.md` com frontmatter (`name`, `description`) e um procedimento. **Skill é procedimento, não fonte de verdade** — cada uma aponta para a fonte canônica do assunto e não repete a regra.

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

As personas Giam/Guinho/Marcelinho/Camillo vieram do produto irmão Auê, um jogo mobile — [`AGENTS.md`](../AGENTS.md) §4 registra isso. As skills desta pasta foram **adaptadas** para o Linka em 2026-08-14, deixando de descrever Arena/arroto/carioca e passando a descrever medição, `LinkaEngine`, Apple-first e a fronteira Linka/SignallQ. A skill `regrasDoAndroid` foi removida na adaptação (o Linka não tem versão Android per [`AGENTS.md`](../AGENTS.md) §2), e quatro skills foram renomeadas:

- `conversarComOPrimo` → `conversarComOLuiz`
- `aplicarTomOgro` → `aplicarVozLinka`
- `pensarComoJogo` → `pensarComoMedicao`
- `garantirMobileReal` → `garantirIphoneReal`

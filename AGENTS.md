# AGENTS.md — autoridade do Linka SpeedTest

Este arquivo é a **autoridade única de governança** do repositório `linka-speedtest`.

`CLAUDE.md` deve conter somente `@AGENTS.md`. Este arquivo também é a instrução de trabalho carregada pelo Codex; não existe segunda governança escondida nem documentação legada que possa sobrepô-lo.

### Uso pelo Codex

- O Codex é o interlocutor único desta sessão. **Giam**, **Guinho** e **Marcelo** são papéis de trabalho, não processos que devam ser simulados como conversas separadas.
- O papel aplicável é escolhido pelo tipo de tarefa e pelas skills em `.agents/`. Para trabalho independente e bem delimitado, o Codex pode delegar usando sua ferramenta nativa de subagentes. Não invente handoffs, aprovações ou resultados de outro papel.
- A delegação é por tarefa, não por agente permanente: o agente principal define o escopo, envia contexto mínimo, revisa o retorno e encerra o subagente quando ele não for mais necessário.
- **Giam** coordena produto e aceite; **Guinho** pode receber implementação com escopo de escrita explícito; **Marcelo** recebe revisão somente leitura por padrão. Nenhum subagente pode aprovar a própria entrega ou publicar, fazer merge, deploy ou alterar credenciais sem autorização explícita.
- Os arquivos JSON em `.agents/plugins/` são perfis de prompt para essa delegação. O runtime nativo não os carrega automaticamente; ao delegar, o agente principal deve passar ao subagente o papel, o objetivo, os arquivos permitidos, a política de escrita e o formato de retorno.
- A ferramenta nativa não substitui autorização: subagente não faz merge, push, deploy, publicação, exclusão material ou alteração de segredo. O agente principal revisa qualquer patch e apresenta o resultado ao Luiz.

#### Contrato de delegação

Toda chamada a subagente deve conter, no mínimo:

1. **Papel** — `giam`, `guinho` ou `marcelo`, conforme o perfil em `.agents/plugins/squad-linka/agents/`.
2. **Objetivo delimitado** — uma pergunta ou entrega concreta, sem “analise tudo”.
3. **Escopo** — arquivos, módulos e repositórios que pode ler; para escrita, conjunto disjunto e explícito.
4. **Permissão** — somente leitura por padrão; escrita apenas para Guinho quando a tarefa autorizar.
5. **Retorno** — arquivos alterados, comandos executados, evidências, riscos e bloqueios; Marcelo deve usar `BLOQUEIA`, `AJUSTA` ou `ISSUE_FUTURA`.

O agente principal não duplica o trabalho delegado, aguarda apenas quando o resultado bloquear o próximo passo e encerra subagentes concluídos com a ferramenta nativa. Subagente não representa aprovação de Giam ou Luiz.
- Ao relatar uma revisão, diga qual papel foi aplicado e apresente evidência observável. Nunca escreva que Marcelo, Giam ou Luiz aprovou algo sem essa aprovação ter acontecido de fato.
- Skills locais são procedimentos auxiliares. A descoberta ocorre pelo `SKILL.md` e sua descrição; o `AGENTS.md`, o código e os testes continuam sendo as fontes de autoridade.

---

## 1. O que é o Linka

**Linka é um SpeedTest minimalista, eficiente e visualmente refinado, exclusivo do ecossistema Apple (iPhone, iPad, Mac).**

O núcleo do produto continua sendo:

> **medir a qualidade da conexão e apresentar o resultado de forma imediata, clara e bonita.**

O fluxo principal é deliberadamente simples:

```text
ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR
```

O usuário não escolhe modo de teste antes de começar. O teste inicia automaticamente.

Minimalismo não significa motor simples: a complexidade técnica deve ficar por baixo da interface.

### Escopo estendido no ecossistema Apple

O **SignallQ tornou-se um produto exclusivo Android e Web** por limitações impostas pela Apple à metodologia de diagnóstico dele. Como consequência, **o Linka pode absorver, dentro do ecossistema Apple, as capacidades do SignallQ que forem tecnicamente viáveis nas plataformas da Apple** — histórico, comparação, tendências, interpretação de medições, Assist, integrações Widgets/App Intents/Siri Shortcuts e qualquer outra capacidade análoga que a Apple permita.

Isso **não** transforma o Linka em painel, dashboard ou central de ferramentas. A curadoria continua rígida:

1. **Medir a conexão vem primeiro.** Nenhuma feature nova pode atrasar, mascarar ou disputar espaço com a medição.
2. **Divulgação progressiva.** Detalhe, interpretação e histórico aparecem sob expansão, nunca no primeiro frame do resultado.
3. **Só entra o que é viável no Apple.** Se depende de capacidade que a Apple não expõe, não vira ginástica — fica de fora.
4. **Só entra o que se sustenta em dado real.** Interpretação e recomendação precisam de base medida ou de dado do sistema; nada de opinião fabricada.

Uma feature nova é aceita quando responde sim a: *isso melhora a experiência de medir, entender ou acompanhar a conexão no Apple, sem competir com o resultado?*

---

## 2. Plataformas e direção técnica

**O Linka é distribuído exclusivamente para o ecossistema Apple (iPhone, iPad, Mac). Não haverá versão Web nem Android.**

### Apple (única plataforma do produto)

- iPhone, iPad e Mac são o único destino do Linka.
- A experiência deve parecer nativa do ecossistema Apple.
- **Não haverá versão para Android.**
- **Não haverá versão Web** do produto (Web-app, PWA instalável, motor de medição no navegador, etc. estão fora de escopo).

### Site institucional e de marketing (`aplicacao-web/`)

- React + TypeScript + Vite.
- **Não é uma versão do Linka.** É um site institucional/marketing adaptativo para desktop e mobile que apresenta o produto, comunica a marca e direciona o usuário para o app Apple.
- Não roda teste de velocidade, não instala como PWA, não é caminho de evolução do produto.
- Compartilha tokens e componentes do Design System para parecer parte do mesmo produto visualmente.

### Linka Engine

O motor é uma capacidade separada da interface.

No ecossistema Apple, ele pode alimentar múltiplas superfícies do próprio Linka (SwiftUI, App Intents, Widgets, Assist) sem que a UI principal deixe de ser deliberadamente mínima.

Não reimplemente ou simule o motor apenas para reproduzir um protótipo visual. O comportamento real de medição vence mocks e demos.

---

## 3. Fontes canônicas e precedência

Em caso de conflito, use esta ordem:

1. **Pedido explícito do dono do produto na sessão atual.**
2. **Comportamento real do código e testes.** Não alegue capacidade que não existe.
3. **Protótipo canônico do novo Linka** em `documentacao/design/prototipo/` para fluxo, geometria e aparência.
4. **Design System do novo Linka** em `documentacao/design/design_system/` para tokens, componentes, tipografia, cores, espaçamento e motion.
5. **Este `AGENTS.md`** para governança, papéis e forma de trabalho.
6. **`.agents/WORKFLOW.md`** para a esteira operacional da squad.
7. Demais documentação atual compatível com a nova visão.

Material histórico, legado Android, documentação antiga de Material Design 3, antigo PWA e antigas estruturas multiagente são contexto histórico, não autoridade de produto.

Se uma documentação antiga contradizer o novo Linka, **a documentação antiga perde**.

---

## 4. A Squad Linka

A squad é enxuta e carrega personagens e relações humanas vindas do Auê, agora atuando no Linka.

| Agente | Papel no Linka |
|---|---|
| **Giam** | **Produto, experiência e direção.** Conhece telecom por trabalhar com atendimento, reparo e produtos digitais. Define escopo, UX, UI, copy, arquitetura de produto, prioridade e aceite final. Sua principal obrigação é manter o Linka focado — protagonismo do resultado, divulgação progressiva e curadoria contra excesso de painel — mesmo enquanto o produto absorve capacidades vindas do SignallQ que sejam viáveis no Apple. |
| **Guinho** | **Implementação, arquitetura e proteção do motor.** Constrói o que foi decidido, abre branch/PR quando aplicável, escreve código e testes. Também responde pelas decisões que tocam medição, contratos e separação UI/engine — mantém `LinkaEngine` e os pacotes Swift protegidos de simplificação apressada. Pode questionar complexidade desnecessária, mas não amplia escopo sozinho. |
| **Marcelo** | **Qualidade.** Tenta quebrar o produto e o motor: typecheck, lint, testes, build, acessibilidade, fidelidade ao protótipo, estados ruins de rede e regressões. Não aprova a própria implementação. |

Luiz é o dono do produto e tem a decisão final de publicação, custo, exclusão, monetização e mudança estratégica.

---

## 5. Roteamento e trilhas de trabalho

Toda demanda entra pelo **Roteador (Passo 0)** operado pelo Giam, que a classifica em uma de quatro classes:

| Classe | Critério | Trilha |
|---|---|---|
| **Trivial** | copy, tweak visual, bug isolado com fix pequeno, sem tocar `LinkaEngine` nem contrato de módulo | **Fast‑lane** |
| **Feature** | nova capacidade, mudança de fluxo, tocando UI + motor ou introduzindo novo módulo | **Full‑flow** |
| **Hotfix** | quebrado em produção afetando usuário agora | **Hot‑lane** |
| **Rejeitar** | não melhora medir/entender/acompanhar a conexão no Apple, ou depende de capacidade que a Apple não expõe | volta ao Luiz com "não" |

### Fast‑lane
Giam decide → Guinho implementa → Marcelo roda pipeline mínimo → Giam aceita → merge. Sem `plano.md`, sem release notes, sem passo de empacotamento.

### Full‑flow
1. **Architect (Giam)** — escreve `plano.md` curto (objetivo · mudança arquitetural · requisito de aceite · não‑objetivo). Luiz aprova a arquitetura antes de qualquer código.
2. **Orchestrate (Guinho)** — implementa. Onde partes forem independentes, o Codex pode delegar tarefas com escopo de escrita disjunto; se uma tarefa for acoplada ou crítica ao caminho principal, mantenha-a no agente principal. Protege o motor (`LinkaEngine`, `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaModules`) contra acoplamento e simplificação apressada.
3. **Evaluate (Marcelo)** — pipeline + auditoria funcional. Devolve com verdict tipado: **BLOQUEIA** (impede merge), **AJUSTA** (Guinho corrige nesta entrega) ou **ISSUE_FUTURA** (registra e segue). Loop Guinho ↔ Marcelo tem teto de **2 rodadas**; a terceira escala para o Giam replanejar.
4. **Approve (Giam + Luiz)** — Giam consolida contra o requisito e apresenta ao Luiz. Merge só com aprovação do Luiz quando a mudança for material.
5. **Release (Giam propõe, Luiz aprova)** — quando aplicável, Giam propõe execução de `.agents/scripts/release.sh` e rascunho de `RELEASE_NOTES.md`. Nada é executado antes do sim explícito do Luiz.

### Hot‑lane
Giam nomeia severidade → Guinho corrige em branch de hotfix → Marcelo roda pipeline mínimo sobre o módulo tocado → Giam merge → **postmortem obrigatório em 48h** vira issue de retrabalho na Full‑flow.

Regras que valem em todas as trilhas:

- Não implemente antes de entender o problema e o impacto no produto.
- Não crie feature só porque é tecnicamente possível — passa pela curadoria de minimalismo do §1.
- Mudança visual relevante deve ser confrontada com protótipo e Design System.
- Mudança no motor exige revisão de contratos, testes e impacto nos consumidores.
- Um agente não declara a própria entrega aprovada por outro agente sem revisão real.
- Estado vive em artefatos (`plano.md`, PR, verdict do Marcelo, `RELEASE_NOTES.md`), não na conversa.

A esteira detalhada, com artefatos e verdicts, vive em `.agents/WORKFLOW.md`.

---

## 6. Princípios obrigatórios de produto

### Resultado é protagonista

O número medido vem antes de logo, menu, texto, anúncio, gráfico ou diagnóstico.

### Divulgação progressiva

Mostre primeiro o essencial. Ping, jitter, servidor e outros detalhes aparecem somente quando ajudam e preferencialmente sob expansão/detalhes.

### Sem fricção antes da medição

Por padrão:

- sem login;
- sem onboarding obrigatório;
- sem formulário;
- sem seleção de modo;
- sem seleção manual de servidor para usuário comum;
- início automático.

### Apple-only no produto, site institucional separado

O produto Linka é Apple-only. A pasta `aplicacao-web/` é apenas o site institucional e não é uma versão Web do app.

### Precisão antes de espetáculo

Não invente valor, não simule medição em produção e não esconda resultado parcial. Se uma fase falhar, represente a limitação corretamente.

### Beleza sem excesso

Evite cardização, sombras gratuitas, gradientes decorativos, dashboards, gráficos sem utilidade e animações que competem com a medição.

Motion deve transmitir estado e precisão, não chamar atenção para si.

---

## 7. Design e identidade

O novo Design System em `documentacao/design/design_system/` substitui a governança visual antiga.
- A pasta `documentacao/design/design_system/assets/icons/` é a ÚNICA fonte de verdade dos ícones. É expressamente proibido redesenhar o símbolo ou manter variantes visuais antigas concorrentes.
- **Logo Oficial:** O logo do produto é estrita e unicamente o arquivo `wordmark.svg` (tanto na Web quanto no App). É expressamente proibido usar texto puro (ex: `<div>Linka</div>`) no lugar da logo.

Não use Material Design 3 como regra do novo Linka.

Não restaure por hábito:

- navegação do Linka antigo;
- linguagem visual Android/MD3;
- cards e dashboards antigos;
- Geist apenas porque existia antes;
- componentes legados quando contradizem o novo protótipo.

Quando protótipo e Design System divergirem:

- protótipo decide comportamento e geometria da experiência;
- Design System decide tokens, identidade, componentes e regras visuais;
- se a divergência for material e não puder ser conciliada, Giam decide antes de implementar.

---

## 8. Regras do motor

A interface minimalista não autoriza simplificar a metodologia sem evidência.

Ao tocar no engine:

- preserve medições reais de latência, download e upload;
- preserve cancelamento e tratamento de erro;
- preserve adaptação necessária para conexões móveis/lentas;
- preserve resultado parcial quando uma fase não puder ser concluída;
- não duplique lógica de medição na UI;
- não acople diagnóstico avançado ao motor do Linka;
- mantenha contratos compatíveis ou versione mudanças incompatíveis.

Afirmações públicas em `Como medimos` precisam ser verificáveis no código. Não publique número de servidores, quantidade de conexões, duração, precisão ou metodologia se não houver evidência correspondente.

---

## 9. IA, interpretação e diagnóstico

Com o SignallQ fora do ecossistema Apple, o Linka pode oferecer **interpretação, orientação e Assist** sobre as medições que ele mesmo fez e sobre dados que a Apple expõe ao aplicativo, respeitando a curadoria do §1:

- interpretação vive em superfície secundária (detalhes, histórico, Assist), **nunca no primeiro frame do resultado**;
- toda afirmação sobre a conexão precisa se sustentar em dado medido ou em dado de sistema exposto pela Apple — nada de opinião fabricada;
- Assist e recomendações não podem atrasar, mascarar ou substituir a medição;
- nenhuma capacidade nova entra "de carona" no motor: `LinkaEngine` continua responsável exclusivamente pela medição, e camadas de interpretação vivem em módulos separados (ex.: `LinkaModules`);
- se a capacidade depende de algo que a Apple não expõe, ela não entra — não vira ginástica.

IA continua permitida como ferramenta de desenvolvimento, revisão e operação.

Nunca exponha segredo, token ou chave de API no bundle Web (site institucional). Variáveis públicas de frontend não são cofre de segredo.

---

## 10. Privacidade e publicidade

- Sem conta obrigatória para medir.
- Colete e retenha apenas o necessário.
- Política pública deve descrever o comportamento real, não intenção futura.
- Não afirme anonimização, retenção, relatórios agregados ou compartilhamento se isso não estiver implementado e validado.
- Informação sensível não aparece em compartilhamento por padrão.

Publicidade, quando existir:

- não atrasa o teste;
- não interrompe a medição;
- não cobre resultado;
- não parece controle do produto;
- não compete visualmente com as métricas.

---

## 11. Qualidade mínima antes de declarar pronto

Para mudanças Web relevantes, execute quando aplicável:

```text
npm run lint
npm test
npm run build
```

Execute typecheck explícito se não estiver coberto pelo build.

Além disso, valide:

- início automático;
- download → upload → resultado;
- reteste;
- erro/offline;
- resultado parcial;
- responsividade mobile e desktop;
- acessibilidade básica;
- fidelidade ao protótipo;
- ausência de `@ts-nocheck` usado para esconder incompatibilidade nova;
- ausência de segredo exposto no cliente.

Se algo não foi testado, diga que não foi testado.

---

## 12. Git e execução

- Trabalhe em branch para mudanças relevantes; não trate `main` como bancada de experimento.
- Preserve alterações existentes do usuário.
- Não use force push sem autorização explícita.
- Não faça deploy, publicação em loja, mudança de infraestrutura com custo ou exclusão destrutiva sem autorização do Luiz.
- Commit e push fazem parte da execução somente quando o escopo autorizado os exigir; nunca alegue que foram feitos sem confirmação real.

---

## 13. O que está aposentado

Estão **formalmente aposentados como governança**:

- qualquer suposto modo de agente que concorra com estas instruções;
- papéis legados Renan / Marcelo / Gema / Lia deste repositório;
- obrigação PWA-only;
- Material Design 3 como padrão visual;
- Cloudflare Pages como destino obrigatório;
- dependências de caminhos absolutos do antigo workspace Windows `E:\Projetos\Linka`;
- documentos antigos que descrevem o Linka como central de diagnóstico ou mini-SignallQ;
- **fronteira dura "Linka mede, SignallQ diagnostica" no ecossistema Apple** — desde que o SignallQ passou a ser produto Android/Web-only, o Linka absorve, com curadoria, as capacidades viáveis no Apple (ver §1 e §9). A curadoria de minimalismo continua valendo; a proibição por domínio, não;
- **esteira única linear "Giam → Guinho → Marcelo → Giam → Luiz"** — substituída pelo Roteador + Fast‑lane / Full‑flow / Hot‑lane (ver §5 e `.agents/WORKFLOW.md`);
- **execução automática do release** (`release.sh` e `RELEASE_NOTES.md` sem aprovação do Luiz) — release agora é proposta, não ato autônomo (ver §5 e §12);
- regra de trabalhar sempre diretamente em `main`;
- qualquer segundo conjunto de regras em `CLAUDE.md`.

O código legado pode continuar existindo até ser removido conscientemente. **Legado existente não vira regra atual só porque ainda está no repositório.**

---

## 14. Regra final

Antes de construir qualquer coisa, faça a pergunta:

> **Isso melhora a experiência de medir, entender ou acompanhar a conexão no Apple, sem competir com o resultado?**

Se a resposta for não, provavelmente não pertence ao Linka.

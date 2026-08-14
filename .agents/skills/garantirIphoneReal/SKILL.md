---
name: garantirIphoneReal
description: Procedimento do Guinho para o Linka funcionar em iPhone/iPad/Mac reais — não simulador — com atenção às condições que o desktop e o simulador não reproduzem.
---

# Skill: garantirIphoneReal

Procedimento do **Guinho** para o Linka funcionar **no aparelho de verdade** — iPhone, iPad e Mac — e não só no simulador ou no Mac de desenvolvimento.

> ## SIMULADOR NÃO PROVA MEDIÇÃO
>
> No simulador a rede é a do Mac. Latência costuma ser 1 ms, banda é a do Ethernet do desenvolvedor. Nada disso é o que o usuário vê.
>
> Simulador serve para: layout, safe area, navegação, comportamento visual, verificação rápida em várias telas Apple. Não serve para: medição de rede real, permissão iOS pedida de verdade, cronômetro do sistema sob load, background/foreground real.

Autoridade: [`AGENTS.md`](../../../AGENTS.md) §2 (Apple-only), §6 (precisão antes de espetáculo), §11 (qualidade mínima).

## 1. Aparelho real é alvo de validação, não "quando der"

Cada mudança que toca o motor, a medição ou o resultado precisa de teste no aparelho antes do aceite. É o item mais fácil de pular e o mais fácil de esconder no PR — Marcelo vai perguntar diretamente.

## 2. Layout que não quebra no dispositivo

**iPhone:**

- safe area respeitada (topo, bottom, Dynamic Island, gesto de home);
- retrato + paisagem se aplicável (o Linka pode travar retrato — se travar, decisão explícita no plano);
- notch de iPhone antigo, Dynamic Island de iPhone recente, iPhone SE (sem notch) — todos cabem;
- densidade de pixel (`@2x`, `@3x`) e escala de tipografia dinâmica (Dynamic Type) — texto não estoura, layout não corta.

**iPad:**

- portrait + landscape;
- Split View / Slide Over — o app se comporta razoavelmente ou declara que precisa da janela cheia;
- Stage Manager.

**Mac:**

- janela redimensionável (largura mínima definida);
- toolbar/menu bar consistente com convenções macOS;
- comportamento em Full Screen.

## 3. Onde o dispositivo real castiga

- **Rede móvel de verdade.** 4G/5G com sinal fraco, com carrier congestionado, com fallback para 3G. É diferente do Wi-Fi doméstico.
- **Troca de rede no meio.** Wi-Fi cai, celular assume — o motor lida?
- **Modo Baixo Consumo (Low Power Mode) do iOS.** Reduz frequência de tarefas em background — o motor termina a medição ou avisa?
- **Chamada telefônica no meio.** Interrompe? Recupera?
- **App para background e volta.** Task cancelada corretamente, medição não fica órfã.
- **App Store Review em iPad quando o app foi validado só em iPhone.** Review roda em iPad — se o layout quebra, rejeição.

## 4. Permissão iOS

Se o Linka pedir alguma permissão nova (localização precisa, rede local, etc.), pedir no gesto do usuário, com string clara no `Info.plist`, com caminho de recuperação quando negada. Negar duas vezes silencia o diálogo — se acontecer, o app precisa mandar para Ajustes com explicação.

Hoje o Linka não pede permissão sensível para o fluxo principal (medição não exige localização nem microfone). Se for adicionar, isso é discussão de escopo com o Giam antes.

## 5. Compartilhamento e integrações do sistema

- ShareSheet do sistema (`UIActivityViewController` / `NSSharingServicePicker`) para compartilhar resultado — dado sensível (IP, BSSID, operadora) não vai por padrão ([`AGENTS.md`](../../../AGENTS.md) §10).
- App Intents / Shortcuts funcionam na Siri e no app Shortcuts real?
- Widget (se existir) atualiza dentro dos limites de refresh do WidgetKit?
- Deep link / Universal Link abre no app instalado?

## 6. Acessibilidade real

- **VoiceOver** lê o resultado corretamente: `AccessibilityValue` do número, rótulo de "Testar novamente".
- **Dynamic Type** em escalas grandes não estoura layout.
- **Contraste alto** (`Increase Contrast`) — as hairlines viram bordas legíveis.
- **Reduzir movimento** (`Reduce Motion`) — animações se degradam sem perder informação.
- **VoiceControl** — comandos por voz funcionam nos botões principais.

## 7. Checklist antes de declarar pronto

**iPhone real (mínimo um):**

- [ ] mede em Wi-Fi de verdade
- [ ] mede em celular de verdade
- [ ] cancelar durante a medição libera a task
- [ ] mandar app para background durante medição não quebra ao voltar
- [ ] rotação (se permitida) não perde estado
- [ ] safe area respeitada em iPhone com notch/Dynamic Island

**iPad:**

- [ ] mesmo roteiro do iPhone
- [ ] Split View não quebra layout crítico

**Mac:**

- [ ] janela pequena e grande OK
- [ ] Full Screen OK

**Todos:**

- [ ] modo escuro + modo claro
- [ ] rede desligada: erro tratado, sem promessa falsa
- [ ] rede lenta o suficiente para gerar `partial`: resultado é honesto
- [ ] `Reduce Motion` ligado: informação completa

O que não foi testado **vai escrito como não testado** no relatório ([`.agents/WORKFLOW.md`](../../WORKFLOW.md) Passo 2, [`registrarIssue`](../registrarIssue/SKILL.md)).

## Relacionados

- **Rodar no iPhone (build + install):** [`rodarNoIphone`](../rodarNoIphone/SKILL.md)
- **Adapter entre motor e UI:** [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)
- **Design System:** [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md)
- **Auditoria final:** [`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)

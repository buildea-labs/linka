---
name: desenharExperiencia
description: Procedimento do Giam para desenhar o fluxo e os estados do Linka (abrir → medir → mostrar → repetir) sem inventar tela nova nem inflar o produto.
---

# Skill: desenharExperiencia

Procedimento do **Giam** para desenhar **o que acontece** — fluxo, estado, sensação e saída — antes de qualquer pixel e antes de qualquer código.

> ## FONTES CANÔNICAS DA EXPERIÊNCIA
>
> Nesta ordem:
>
> 1. [`documentacao/funcional/VISAO.md`](../../../documentacao/funcional/VISAO.md) — o que o Linka é hoje;
> 2. [`AGENTS.md`](../../../AGENTS.md) §1, §6 — o essencial do produto e os princípios obrigatórios;
> 3. [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) — fronteira Free/Plus;
> 4. [`documentacao/design/prototipo/`](../../../documentacao/design/prototipo/) — o protótipo canônico do fluxo e da geometria;
> 5. [`documentacao/design/design_system/readme.md`](../../../documentacao/design/design_system/readme.md) — como cada estado se parece.
>
> Se o desenho quiser um estado que o protótipo não descreve, isso é escopo novo. Volta para o §0.

## 0. Escopo antes de tudo

Leia [`AGENTS.md`](../../../AGENTS.md) §14 (a pergunta final):

> Isso ajuda o Linka a medir a internet melhor, mais rápido, mais confiável ou de forma mais clara?

Se a resposta for "não", provavelmente não pertence ao Linka. Registra no backlog e não desenha.

## 1. O fluxo do Linka é curto

O Linka tem um fluxo principal deliberadamente simples ([`AGENTS.md`](../../../AGENTS.md) §1):

```text
ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR
```

Estados principais (na prática):

- **preparação** — app abre, medição inicia automaticamente;
- **medição de latência** — pode ser silenciosa se a UI já comunicar;
- **medição de download** — número dominante;
- **medição de upload** — mesma tela, muda a fase;
- **resultado** — download + upload lado a lado, opção de detalhes, ação "testar novamente";
- **erro/parcial** — se uma fase falhou, mostrar o que foi possível medir com honestidade.

Não invente "tela nova". Se a mudança precisa de um sexto estado, provavelmente é feature de SignallQ, não de Linka.

## 2. As perguntas

Para cada mudança, responda por escrito:

1. **Qual estado muda?** Muda o conteúdo, a saída, ou nasce transição nova?
2. **O que o usuário está sentindo** ao entrar nesse estado? E ao sair?
3. **Quantos toques** até o resultado? Dá para tirar um?
4. **Qual é a saída?** Todo estado tem saída. Estado sem saída é bug de design.
5. **E se der ruim?** Sem rede, permissão negada, servidor lento, medição incompleta. Cada caso vai para onde?
6. **Depois do resultado, o que naturalmente acontece?** No Linka a resposta padrão é "testar novamente" — não é "compartilhar", "compare com outros", "adicione ao histórico" (o histórico é background). Divulgação progressiva ([`AGENTS.md`](../../../AGENTS.md) §6).
7. **Com `prefers-reduced-motion` ligado**, a informação continua completa?
8. **O que isso NÃO deve virar?** Escreve. Isso vira o "Não viaja" da issue.

## 3. Regras que não se negociam

- **Nada finge que funciona.** Botão sem backend fica desabilitado. Mock fica marcado. Falha não vira sucesso por copy ([`AGENTS.md`](../../../AGENTS.md) §6, §8).
- **Estado nunca fica preso.** Sempre existe caminho de cancelar ou tentar de novo.
- **Recurso sensível tem começo e fim visíveis.** `URLSession`, `Task`, timer: usuário entende que o app está trabalhando e entende quando parou.
- **Erro conta a verdade.** Se a medição de upload falhou mas o download foi bom, o resultado é `partial` e a UI reflete isso, sem inventar valor.
- **Resultado é medida, não interpretação.** Nunca "sua conexão está boa para X" (isso é SignallQ). Ver [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md).
- **A tela de medição não é feed.** Sem cards, sem histórico visível no meio, sem gráfico decorativo. Histórico é background acessível, não é hero.

## 4. Sem fricção antes da medição

Por padrão, o Linka NÃO faz o usuário passar por:

- login;
- onboarding obrigatório;
- formulário;
- seleção de modo (rápido/completo);
- seleção manual de servidor.

O teste inicia automaticamente. Ver [`AGENTS.md`](../../../AGENTS.md) §6.

## 5. A saída

O que sai daqui entra no plano do Giam ([`.agents/WORKFLOW.md`](../../WORKFLOW.md) Passo 0) e na issue:

```text
ESTADO: qual estado do fluxo, e o que muda nele
ANTES:  o que o usuário vê e sente ao entrar
AÇÃO:   o que ele faz (se aplicável — muitos estados são passivos)
DEPOIS: o que ele vê ao sair, e para onde vai
DEU RUIM: cada falha e para onde ela leva
REDUCED MOTION: o que muda
NÃO VIAJA: no que isso não pode virar
```

Depois entra a [`desenharInterface`](../desenharInterface/SKILL.md).

## Relacionados

- **Como isso vira forma:** [`desenharInterface`](../desenharInterface/SKILL.md)
- **Filtro de escopo do produto:** [`pensarComoMedicao`](../pensarComoMedicao/SKILL.md)
- **Voz e copy:** [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md)
- **Arquitetura:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)
- **Quem implementa:** [`criarComponenteUI`](../criarComponenteUI/SKILL.md)

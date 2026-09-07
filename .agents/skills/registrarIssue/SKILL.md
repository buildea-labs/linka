---
name: registrar-issue
description: Como o Linka escreve issue, PR e commit com linguagem direta, factual e compatível com a voz do produto.
---

# Skill: registrar-issue

Issue, PR e commit são texto de trabalho, não cerimônia.

O **Codex principal** normalmente consolida e registra informações de produto, decisão técnica e qualidade quando aplicáveis.

Passe pelo filtro `matar-cheiro-de-ia`.

## Issue

### Título

Diga o problema ou mudança de forma humana e específica.

### Corpo recomendado

```markdown
## Qual é o problema

Comportamento atual ou capacidade ausente.

## Como deveria ser

Comportamento esperado.

## Onde no protótipo / design system

Referência, quando aplicável.

## Não vira

Limites explícitos de escopo.

## Aceite

Comportamentos verificáveis.
```

Evite história de usuário corporativa, Definition of Done, estimativa decorativa, seções que repetem contexto e excesso de template.

## Commit

Use o padrão adotado pelo repositório. Título diz o que mudou; corpo explica motivo quando não for óbvio.

Exemplo:

```text
fix(engine): upload incompleto devolve resultado parcial
```

Não misture mudanças não relacionadas no mesmo commit.

## PR

O corpo do PR deve carregar o que o revisor precisa para decidir:

- problema e mudança observável;
- principais decisões técnicas;
- critérios de produto, quando aplicável;
- relatório de qualidade com automático/leitura/aparelho real/não testado;
- passos manuais de verificação quando necessários;
- riscos ou pendências reais.

Não escreva que especialista ou Luiz aprovou se essa aprovação não aconteceu.

## Regra final

Texto de trabalho deve permitir que outra pessoa retome a decisão sem precisar reconstruir uma conversa entre agentes.

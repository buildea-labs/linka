---
name: registrar-issue
description: Como o Linka escreve issue, PR e commit — linguagem direta, sem corporativismo, obedecendo à voz canônica do produto.
---

# Skill: registrarIssue

Issue, PR e commit do Linka são **texto de trabalho** — direto, factual, curto. Não são documento de banco, não são ticket de service desk, não são história de sprint.

Quem abre issue normalmente é o **Giammattey** (é ele quem planeja e prioriza). PR e commit são do **Tiago**. A voz é a mesma para os três.

Tudo aqui passa obrigatoriamente pela [`matarCheiroDeIA`](../matarCheiroDeIA/SKILL.md).

A fonte da voz é [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md).

---

## 1. Formato da issue

### Título

Frase de gente, em PT-BR, minúscula depois da primeira palavra. Diz o que é.

> ❌ `Implementação de mecanismo de tratamento de falhas na fase de upload do motor de medição`
>
> ✅ `medição de upload que falha no meio ainda conta como sucesso`

### Corpo

```markdown
## Qual é o problema

O que acontece hoje, ou o que não existe ainda. Contado como alguém do time contaria.

## Como deveria ser

Comportamento esperado. Sem virar manual, sem enunciar princípio.

## Onde no protótipo / design system

Aponta arquivo e estado se aplicável (`documentacao/design/prototipo/...`).

## Não vira

O que essa mudança NÃO pode virar. Escreve mesmo. É o que segura o escopo.

## Aceite

Lista que o Giammattey vai conferir. Cada linha conferível — não princípio.
```

Critério técnico, contrato, segurança e detalhes de execução entram **onde forem necessários para fazer** — não dominam a história.

## 2. O que não entra em issue

- `Como usuário, eu quero… para que…`
- `Critérios de aceitação` (use `Aceite`, com linhas conferíveis)
- `Definition of Done`, `entregável`, `stakeholder`, `impacto no negócio`
- estimativa em pontos, t-shirt size, `P0/P1/P2` corporativa
- seção `## Contexto` que repete o título com mais palavras
- emoji abrindo cada bullet
- gráfico de arquitetura desnecessário

## 3. Exemplo

> **medição de upload que falha no meio ainda conta como sucesso**
>
> **Qual é o problema**
>
> Usuário está no 5G, conexão oscila, o upload sobe até 60% e cai. O motor termina, a UI mostra o resultado como se tivesse dado certo, download 91 Mbps, upload 4,2 Mbps. Só que aquele 4,2 é do que subiu antes de cair — não é upload real.
>
> **Como deveria ser**
>
> Se a fase de upload não completou, o resultado é `partial` (contrato canônico v1). A UI mostra o download com o valor real e o upload como "não foi possível medir", com opção de tentar de novo.
>
> **Onde no protótipo**
>
> Ver estado `RESULT` no protótipo, faixa de upload. Padrão de `partial` já existe para o caso de rede desligada.
>
> **Não vira**
>
> - retry automático (usuário decide se tenta de novo);
> - popup pedindo desculpa;
> - copy tentando explicar o que aconteceu na rede.
>
> **Aceite**
>
> - com rede oscilando (simulável via Network Link Conditioner), o resultado mostra upload como não-medido, não como zero;
> - `NetworkCore` continua produzindo `NetworkMeasurement` válido com `outcome: partial`;
> - `swift test` verde em `NetworkCore` e `LinkaEngine`;
> - testado em iPhone real em rede móvel.

## 4. Commit

PT-BR, proporcional ao diff, `tipo(escopo): o que mudou`.

Título diz o que mudou. Corpo diz por que, se não for óbvio. Sem redação.

```text
fix(engine): upload que falha no meio devolve partial em vez de valor incompleto

Antes, se a fase de upload caía no meio, LinkaEngine terminava e reportava
o valor parcial como se fosse a medição final. Agora produz NetworkMeasurement
com outcome: partial e a UI mostra "não foi possível medir".
```

Escopos comuns: `engine`, `core`, `history`, `insights`, `assist`, `app`, `ui`, `web`, `docs`, `agents`, `ci`.

## 5. PR

Mesma voz. Corpo do PR carrega, além da história:

- **Relatório do Igor** ([`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)), separando: verificado automaticamente (`swift test`, `build`), verificado por leitura, verificado em aparelho real, e o que **não** foi verificado.
- **Aceite do Giammattey** contra o `Aceite` da issue.
- **Test plan** — passos para o revisor conferir.

Essas partes podem ser secas e diretas. Relatório não é lugar de piada nem de enfeite.

## 6. Antes de publicar

- [ ] título é frase de gente?
- [ ] tem `Não vira` escrito?
- [ ] o `Aceite` é conferível linha por linha?
- [ ] passou na [`matarCheiroDeIA`](../matarCheiroDeIA/SKILL.md)?
- [ ] se PR: tem relatório de qualidade separando automático/leitura/aparelho real/não-testado?

## Relacionados

- **A voz:** [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md)
- **Sem cheiro de IA:** [`matarCheiroDeIA`](../matarCheiroDeIA/SKILL.md)
- **O plano que vira issue:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)
- **Falar com o Luiz:** [`conversarComOLuiz`](../conversarComOLuiz/SKILL.md)
- **Auditoria de qualidade:** [`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)

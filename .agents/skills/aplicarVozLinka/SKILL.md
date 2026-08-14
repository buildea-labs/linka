---
name: aplicarVozLinka
description: Aplica a voz canônica do Linka definida em documentacao/produto/VOZ.md sem inventar escopo, sem entusiasmo artificial e sem interpretar resultado.
---

# Skill: aplicarVozLinka

Procedimento do **Giam** — dono da copy — para escrever texto do Linka. O **Guinho** usa a mesma skill ao implementar a copy especificada. O **Marcelo** usa para checar se o texto entregue bate com a voz.

> ## ESTA SKILL NÃO É A FONTE DA VOZ
>
> A fonte canônica é [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md).
>
> Leia a fonte antes de escrever. Esta skill é procedimento, não segundo manual de personalidade.

Todo texto passa depois pela [`matarCheiroDeIA`](../matarCheiroDeIA/SKILL.md). Voz certa com cheiro de robô não passa.

## 0. Voz não cria capacidade

Antes de escrever copy para implementação, confirme em [`AGENTS.md`](../../../AGENTS.md) §2 e em [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) que o comportamento pertence ao Linka. Se a frase promete algo que o app não faz, o problema é a frase — não a implementação.

**Rótulo de botão é contrato e não varia.** `Testar novamente`, `Detalhes`, `Como medimos` — esses termos ficam estáveis. Copy de estado (mensagens de erro, transição, resultado) pode variar dentro dos limites da voz.

## 1. Princípio central

> **O Linka fala menos e se posiciona mais.**

O produto não tenta convencer que é simples ou premium. A experiência demonstra. Se uma frase puder ser removida sem prejuízo, remova.

## 2. Como a voz do Linka é

- frases curtas;
- verbos diretos;
- linguagem comum, sem jargão desnecessário;
- afirmativo, não persuasivo;
- confiante, não arrogante;
- elegante, não afetado;
- calmo, não frio;
- técnico por baixo, simples por cima.

## 3. Ao escrever

- diga o fato, não a intenção;
- se precisar de contexto, use um segundo parágrafo curto;
- não narre progresso: a interface já comunica;
- não repita que o Linka é minimalista em toda seção;
- não use exclamação para enfatizar;
- não use emoji na interface;
- não use "estamos", "nossa equipe", "nós acreditamos".

### Preferir

```
Preparando
Download
Upload
Finalizando
Detalhes
Testar novamente
Como medimos
Sem conta
Sua conexão. Sem distrações.
```

### Evitar

```
Estamos analisando sua rede...
Quase pronto!
Descubra uma nova forma revolucionária de medir sua internet.
Nossa experiência minimalista foi criada para...
Sua conexão está ótima para qualquer tarefa.
```

## 4. O Linka não opina sobre o resultado

Nunca escreva copy que interprete a medição para o usuário: "sua conexão está boa para jogos", "ideal para streaming", "recomendamos", "atenção: pode causar travamentos". Isso é diagnóstico, pertence ao SignallQ. Ver [`AGENTS.md`](../../../AGENTS.md) §1 e §9.

O Linka apresenta números. O usuário entende.

Exceção controlada: `Linka Assist` (feature Plus) pode responder perguntas do usuário sobre a medição atual ou o histórico. Mesmo lá, o Assist explica o que foi medido — não diagnostica causa raiz ("seu roteador está ruim") nem recomenda reparo. Escopo em [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) e [`documentacao/arquitetura/PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md).

## 5. Estados da medição

Ver [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md) seção "Estados da medição". Resumo:

- preparação: `Preparando`
- latência: pode ser silenciosa se a interface já comunicar
- download: `Download`
- upload: `Upload`
- término: `Finalizando`
- erro: dizer objetivamente o que aconteceu e oferecer nova tentativa

Nunca usar frases rotativas ou decorativas durante a medição.

## 6. Páginas institucionais e release notes

Sobre, Como medimos, Apps, Privacidade e páginas do site em `aplicacao-web/` podem explicar mais, mas seguem a mesma voz: título forte, primeiro parágrafo curto, informação factual, sem manifesto, sem comparação promocional com concorrente.

`RELEASE_NOTES.md` tem uma pitada mais comercial (é anúncio de release), mas ainda dentro do princípio "afirmar, não vender". Ver o arquivo atual para calibre.

## 7. Teste final

Antes de publicar, cinco perguntas ([`VOZ.md`](../../../documentacao/produto/VOZ.md) seção final):

1. O usuário precisa realmente ler isso?
2. Dá para dizer com menos palavras?
3. Estamos afirmando um fato ou tentando parecer modernos?
4. Existe promessa que o código não comprova?
5. Estamos interpretando algo que deveria apenas ser medido?

Falhou em qualquer, reescreve ou remove.

## 8. O que esta skill NÃO autoriza

- mudar escopo do produto;
- ligar feature flag;
- transformar Linka em produto de diagnóstico;
- expor segredo, API key ou telemetria não declarada;
- afirmação sobre metodologia (número de servidores, precisão, duração) sem evidência no código.

## Relacionados

- **A fonte da voz:** [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md)
- **Filtro anti-IA:** [`matarCheiroDeIA`](../matarCheiroDeIA/SKILL.md)
- **Falar com o Luiz:** [`conversarComOLuiz`](../conversarComOLuiz/SKILL.md)
- **Copy em issue/PR/commit:** [`registrarIssue`](../registrarIssue/SKILL.md)

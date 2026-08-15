---
name: pensarComoMedicao
description: Curadoria do Giam para julgar se uma mudança fortalece o Linka como SpeedTest mínimo no ecossistema Apple, ou se está inchando o produto em painel/dashboard.
---

# Skill: pensarComoMedicao

Curadoria do **Giam**: isto aqui melhora **medir, entender ou acompanhar** a conexão no Apple, sem competir com o resultado?

O Linka é um **SpeedTest minimalista**, exclusivo do ecossistema Apple, com núcleo em **medir a qualidade da conexão e apresentar o resultado de forma imediata, clara e bonita** ([`AGENTS.md`](../../../AGENTS.md) §1). Com o SignallQ agora exclusivo Android/Web, o Linka **pode** absorver capacidades vindas de lá que sejam viáveis no Apple (histórico, comparação, tendências, interpretação sustentada, Assist, Widgets, App Intents). O que não muda é a curadoria: nada vira dashboard, nada compete com o resultado, nada entra só porque é possível.

O fluxo é deliberadamente curto:

```text
ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR
```

## 1. O usuário imaginado

Alguém abre o Linka porque quer uma resposta rápida para:

> **"Quanto está dando minha internet agora?"**

Está em pé, na varanda, no elevador, no trabalho, no meio de uma reunião ruim, na casa da mãe. Não quer configurar nada. Não quer escolher servidor. Não quer criar conta. Não quer ler tutorial.

Todo desenho é julgado contra essa pessoa. Não contra um técnico procurando o problema da rede.

Consequências diretas:

- funciona sem login;
- funciona sem onboarding;
- não pede permissão sensível para o fluxo principal;
- inicia automaticamente;
- termina rápido, com número óbvio;
- oferece "testar novamente" como próxima ação natural.

## 2. Os números que importam

| Pergunta | Alvo |
|---|---|
| Do abrir o app até a medição começar | zero toques |
| Do começar a medição até ver a primeira métrica | poucos segundos |
| Duração total do teste | curto o bastante para o usuário não sacar o celular |
| Do resultado até "testar novamente" | um toque |
| Do resultado até detalhes (opcionais) | um toque, se o usuário quiser |

Se uma mudança **aumenta** qualquer um desses, precisa de motivo escrito no plano.

## 3. O que faz o produto ser bom

- **Resultado é protagonista.** O número domina a tela em tamanho, tipografia e destaque. Não compete com card, ilustração ou anúncio ([`AGENTS.md`](../../../AGENTS.md) §6).
- **Feedback contínuo, sem drama.** Progresso visível durante a medição, sem barra que pula, sem animação exagerada.
- **Precisão antes de espetáculo.** Se uma fase falhar, mostrar `partial` honesto. Nunca inventar valor.
- **Divulgação progressiva.** Ping, jitter, servidor, operadora, contexto Wi-Fi: só aparecem sob "Detalhes" ou "Como medimos". A tela principal fica limpa.
- **Beleza sem excesso.** Alinhamento, proporção, tipografia. Sem sombra gratuita, gradiente decorativo, glassmorphism ou dashboard.
- **Apple-native.** A experiência parece nativa do ecossistema, não site colocado dentro do app.

## 4. O que mata o produto

- **Cadastro antes da medição.** Ninguém cria conta para descobrir se a internet está boa.
- **Onboarding.** Três telas explicando o que é SpeedTest = fricção pura. Ver [`AGENTS.md`](../../../AGENTS.md) §6.
- **Seleção de modo (rápido/completo).** O Linka mede uma coisa; usuário não escolhe o teste.
- **Seleção manual de servidor.** Escolha automática. Usuário avançado pode ver qual servidor foi usado nos detalhes.
- **Menu com mais de um nível.** Se precisa de submenu, alguma feature está tentando entrar que não deveria.
- **Métrica que ninguém entende.** "Bufferbloat", "TCP retransmit ratio" — ficam em detalhes ou em "Como medimos", não na tela principal.
- **Interpretação no primeiro frame do resultado.** "Sua conexão está ótima para jogos", "atenção: pode causar travamentos" nunca aparecem antes do número medido. Interpretação vive em superfície secundária (detalhes, histórico, Assist) e precisa se sustentar em dado real ([`AGENTS.md`](../../../AGENTS.md) §1, §9).
- **IA opinando no fluxo principal.** `Linka Assist` (Plus) responde perguntas do usuário sob demanda, não interrompe o resultado com diagnóstico automático (ver [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) e [`documentacao/arquitetura/PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md)).
- **Dashboard, gráfico decorativo, "análise avançada" no free.** Se um dado não muda decisão do usuário no momento, ele é enfeite.
- **Anúncio que atrasa o teste, cobre resultado ou parece controle do app** ([`AGENTS.md`](../../../AGENTS.md) §10).

## 5. Curadoria de escopo

A antiga "fronteira dura Linka/SignallQ" foi aposentada ([`AGENTS.md`](../../../AGENTS.md) §13) porque o SignallQ virou produto Android/Web-only. No Apple, o Linka pode absorver interpretação, histórico, comparação, Assist e integrações que a Apple permitir. A curadoria continua rígida ([`AGENTS.md`](../../../AGENTS.md) §1):

1. **Medir vem primeiro.** Nenhuma feature nova atrasa, mascara ou disputa espaço com a medição.
2. **Divulgação progressiva.** Interpretação e histórico aparecem sob expansão, nunca no primeiro frame.
3. **Só entra o que é viável no Apple.** Se depende de capacidade que a Apple não expõe, fica de fora — sem ginástica.
4. **Só entra o que se sustenta em dado real.** Interpretação e recomendação precisam de base medida ou dado do sistema; nada de opinião fabricada.

Sinais de que a mudança precisa recuar (não necessariamente cair fora, mas revisar):

- promete causa raiz com dado que a Apple não expõe (canal Wi-Fi específico do vizinho, saúde do modem do provedor);
- coloca interpretação **no primeiro frame** em vez de sob expansão;
- exige análise cruzada com histórico de outros usuários sem que o valor supere o custo de privacidade;
- vira dashboard/painel decorativo em vez de resposta acionável;
- adiciona menu de segundo nível ou modo selecionável para o usuário comum.

Se qualquer um desses aparecer, a mudança volta para desenho — não some do backlog.

## 6. O teste

Antes de aprovar uma mudança, três perguntas:

1. **Isso melhora a experiência de medir, entender ou acompanhar a conexão no Apple, sem competir com o resultado?** ([`AGENTS.md`](../../../AGENTS.md) §14)
2. **Se tirar isso, o produto fica pior de usar — ou só fica com menos coisa?**
3. **A capacidade se sustenta em dado real e é viável no Apple?**

Se a resposta da (1) for "não", da (2) for "só fica com menos coisa" ou da (3) for "não", não entra. Registra no backlog.

## Relacionados

- **Autoridade:** [`AGENTS.md`](../../../AGENTS.md) §1, §6, §14
- **Escopo Free/Plus:** [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md)
- **Voz:** [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md)
- **Fluxo:** [`desenharExperiencia`](../desenharExperiencia/SKILL.md)
- **Arquitetura:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)

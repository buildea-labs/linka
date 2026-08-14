---
name: pensarComoMedicao
description: Filtro do Giam para julgar se uma mudança fortalece o Linka como SpeedTest mínimo, ou se está transformando o produto em diagnóstico/dashboard.
---

# Skill: pensarComoMedicao

Filtro do **Giam**: isto aqui é medição, ou virou diagnóstico?

O Linka é um **SpeedTest minimalista**, Apple-only, focado em uma coisa só: **medir a qualidade da conexão e apresentar o resultado de forma imediata, clara e bonita** ([`AGENTS.md`](../../../AGENTS.md) §1). Ele não é dashboard, não é central de diagnóstico, não é rede social, não é assistente de suporte técnico. Diagnóstico e recomendação pertencem ao SignallQ.

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
- **Diagnóstico interpretado.** "Sua conexão está ótima para jogos", "atenção: pode causar travamentos", "recomendamos" — tudo isso é SignallQ. Ver [`AGENTS.md`](../../../AGENTS.md) §1, §9.
- **IA opinando no resultado como parte do fluxo principal.** `Linka Assist` (Plus) responde perguntas do usuário sobre medição/histórico, não faz diagnóstico automático (ver [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) e [`documentacao/arquitetura/PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md)).
- **Dashboard, gráfico decorativo, "análise avançada" no free.** Se um dado não muda decisão do usuário no momento, ele é enfeite.
- **Anúncio que atrasa o teste, cobre resultado ou parece controle do app** ([`AGENTS.md`](../../../AGENTS.md) §10).

## 5. Fronteira com o SignallQ

Existe uma linha dura ([`AGENTS.md`](../../../AGENTS.md) §1):

- **Linka mede.**
- **SignallQ interpreta, diagnostica e orienta.**

Sinais de que a mudança pertence ao SignallQ, não ao Linka:

- promete descobrir causa raiz (roteador ruim, canal Wi-Fi congestionado, cabo defeituoso);
- classifica a conexão para um uso (jogos, streaming, chamada);
- recomenda ação (trocar canal, reiniciar modem, mudar plano);
- integra chatbot com opinião;
- exige análise cruzada com histórico de outros usuários;
- coleta contexto de rede não relacionado à medição (dispositivos vizinhos, mapa Wi-Fi).

Se aparece qualquer um desses no pedido, a resposta padrão é: "isso é SignallQ, não Linka. Registra e passa adiante."

## 6. O teste

Antes de aprovar uma mudança, três perguntas:

1. **Isso ajuda o Linka a medir a internet melhor, mais rápido, mais confiável ou de forma mais clara?** ([`AGENTS.md`](../../../AGENTS.md) §14)
2. **Se tirar isso, o produto fica pior de usar — ou só fica com menos coisa?**
3. **Isso é medição, ou é interpretação/diagnóstico disfarçado?**

Se a resposta da (1) for "não" ou a (3) for "diagnóstico", não entra. Registra no backlog e passa para o SignallQ se aplicável.

## Relacionados

- **Autoridade:** [`AGENTS.md`](../../../AGENTS.md) §1, §6, §14
- **Escopo Free/Plus:** [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md)
- **Voz:** [`documentacao/produto/VOZ.md`](../../../documentacao/produto/VOZ.md)
- **Fluxo:** [`desenharExperiencia`](../desenharExperiencia/SKILL.md)
- **Arquitetura:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)

# Squad Linka — aposentada (2026-07-23)

Os 11 agentes deste diretório (Bernardo, Camilo, Claudete, Claudio, Gema, Lia, Marcelo, Nina,
Otavio, Renan, Taisa) eram uma squad de projeto própria do workspace Linka (`linkaAndroidKotlin` +
`linkaSpeedtestPwa`), esquecida e sem manutenção — confirmado pelo Luiz em 2026-07-23.

Aposentados (não deletados, mesmo precedente já usado pra Felipe/Gema no SignallQ e Rafael/Caio/
Vera/Marisa/Marcelo no Nethal). O workspace Linka passa a usar a squad global de nível de usuário
(`~/.claude/agents/` — Claudete, Camilo, Lia, Rhodolfo, Juninho, Bruno), que já cobre repo pessoal
via roteamento por stack. Ver `DECISAO_ROTEAMENTO_STACK_MULTIPRODUTO_2026-07-23.md` em
`C:\Projetos\_workspace\docs\decisions\`.

Motivo do arquivamento e não da exclusão: nomes coincidiam com os agentes globais (Camilo, Claudete,
Lia) e, por precedência de projeto sobre usuário, estavam silenciosamente shadowing a squad global
nesse workspace — ninguém percebeu até o teste de roteamento em `linka-speedtest`.

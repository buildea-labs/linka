# LINKA Mockup Audit

Fonte visual oficial usada: `docs/mockups/linka-webapp.png`.

## Metodologia
1. Comparação de baseline (`docs/visual-audit/screenshots/`) com o mockup.
2. Correção de escala/densidade e navegação.
3. Nova captura em `docs/visual-audit/screenshots-v2/`.

## Home / Início
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- Títulos, métricas e ações rápidas estavam maiores que o mockup.
- Grid de ações rápidas em 4 colunas criava quebra visual e baixa legibilidade.
- Espaço inferior dava sensação de tela incompleta.

### Correções aplicadas (v2)
- Compactação de tipografia e ícones da faixa superior e cards.
- Ações rápidas reorganizadas em 2x2, com cards menores.
- Ajuste de padding vertical/global para reduzir sensação de layout inflado.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/home-v2.png`

## Velocidade
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- Gauge, chips e card de resultado estavam superdimensionados.
- Botão primário grande (`Iniciar teste`) dominava a tela.

### Correções aplicadas (v2)
- Redução do gauge (arco, número, labels e escala).
- Chips compactados.
- Botão gigante removido do destaque principal; ação virou link secundário (`Iniciar novo teste`).

### Screenshot gerado
`docs/visual-audit/screenshots-v2/velocidade-v2.png`

## Sinal
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- Banner offline e linhas de rede estavam mais altos que o mockup.
- Densidade da lista estava baixa.

### Correções aplicadas (v2)
- Banner offline compactado.
- Linhas/cards de rede e badges (dBm/canal) compactados.
- Card `Análise de canal` com proporção menor.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/sinal-v2.png`

## Dispositivos
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- Estado ativo da bottom nav estava inconsistente em rota secundária.
- Lista ainda estava mais espaçada que o mockup.

### Correções aplicadas (v2)
- Estado ativo corrigido para `Início` na rota `Dispositivos` (via ação rápida da Home).
- Linhas, ícones e textos compactados.
- Mantidos os 8 devices e `PlayStation 5` com `Limitado` em laranja.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/dispositivos-v2.png`

## Histórico
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- `99,2%` e card do gráfico estavam desproporcionais.
- Legenda/eixos aparentavam card de dashboard grande.

### Correções aplicadas (v2)
- Redução do valor principal e da área do gráfico.
- Linha azul e ponto offline com proporção mais discreta.
- Chips e card de resumo compactados.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/historico-v2.png`

## Ajustes
### Status visual
Aprovado

### Principais diferenças encontradas (v1)
- Linhas e seções tinham altura acima do mockup.
- Espaçamento entre seções estava amplo.

### Correções aplicadas (v2)
- Compactação dos rows (ícones, título, subtítulo, paddings).
- Redução do espaçamento vertical entre seções.
- Mantido nome arquitetural correto `SettingsScreen`.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/ajustes-v2.png`

## IA / rota fora do mockup principal
### Status visual
Aprovado (isolada)

### Principais diferenças encontradas (v1)
- Captura antiga aparecia vazia (`09-ia.png`).
- Fluxo fora do mockup principal sem tratamento visual consistente.

### Correções aplicadas (v2)
- Rota isolada com placeholder visual no design system do Linka (`AiScreen`), eliminando tela vazia.
- Mantida navegabilidade sem interferir nas 6 telas principais.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/ia-v2.png`

## Resultado do teste (evidência extra)
### Status visual
Parcial

### Principais diferenças encontradas
- Tela ainda pertence ao fluxo legado e mantém maior densidade de informação que o mockup principal.

### Correções aplicadas nesta rodada
- Isolamento visual priorizado nas telas do mockup principal; resultado mantido funcional e capturado para auditoria.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/resultado-v2.png`

## Teste em andamento (evidência extra)
### Status visual
Parcial

### Principais diferenças encontradas
- Layout é de fluxo técnico legado e não corresponde ao mockup estático de velocidade final.

### Correções aplicadas nesta rodada
- Mantido fora da navegação principal de abas e capturado para rastreabilidade.

### Screenshot gerado
`docs/visual-audit/screenshots-v2/teste-andamento-v2.png`

## Diferenças que ainda permanecem
- `Resultado` e `Teste em andamento` ainda não estão 1:1 com o novo mockup (fluxo legado técnico).
- Home/Histórico ainda têm área de respiro maior na metade inferior em capturas full-page longas.

## Rodada v3 — Headers e navegação

### Headers adicionados/ajustados
- Criado header reutilizável `AppHeader` em `src/components/ui/app-ui.tsx` + estilos em `src/components/ui/app-ui.css`.
- Aplicado nas telas raiz:
  - `Velocidade` (título + ação de info, sem voltar)
  - `Sinal` (título raiz, sem voltar)
  - `Histórico` (título raiz, sem voltar)
  - `Ajustes` (título raiz, sem voltar)
- Home manteve header próprio com avatar/saudação/sino (sem botão voltar e sem hambúrguer).

### Telas com botão voltar (secundárias)
- `Resultado do teste`: botão voltar no topo (retorna para `Velocidade`).
- `Dispositivos conectados`: botão voltar no topo (retorna para `Início`).

### Menus hambúrguer removidos
- Removido hambúrguer/`HamburgerMenu` da `ResultScreen`.
- Removido ícone tipo menu hambúrguer de `Dispositivos` e substituído por ação visual de filtro/ordenação (sem navegação paralela para Ajustes).

### Regra de acesso ao Ajustes
- `Ajustes` permanece acessível pela bottom navigation.
- Removido atalho do avatar da Home que navegava para Ajustes.
- Removido caminho por menu hambúrguer na tela de resultado.
- Resultado não oferece mais atalho para Ajustes/Ferramentas externas via topo/menu.

### Estado da bottom nav em telas secundárias
- `Dispositivos` mantém `Início` ativo como tela de origem.
- `Resultado` e `Running` permanecem fora da bottom nav (nav oculta), evitando estado ativo falso.

### Evidências v3
- `docs/visual-audit/screenshots-v3/home-v3.png`
- `docs/visual-audit/screenshots-v3/velocidade-v3.png`
- `docs/visual-audit/screenshots-v3/running-v3.png`
- `docs/visual-audit/screenshots-v3/resultado-v3.png`
- `docs/visual-audit/screenshots-v3/sinal-v3.png`
- `docs/visual-audit/screenshots-v3/dispositivos-v3.png`
- `docs/visual-audit/screenshots-v3/historico-v3.png`
- `docs/visual-audit/screenshots-v3/ajustes-v3.png`

## Rodada v4 — Resultado sem nota/conceito

### Status visual
Aprovado

### O que estava errado antes (v3)
- A tela de resultado ainda carregava herança visual de avaliação por conceito/score no fluxo legado.
- A comunicação de diagnóstico estava menos direta do que o solicitado para a rodada atual.

### Correções aplicadas (v4)
- Removidos da tela `Resultado do teste`:
  - letra `A`;
  - círculo gigante com letra;
  - score/nota/conceito visual tipo boletim (`A+`, `B`, `C` etc.).
- Card principal substituído por diagnóstico prático:
  - título `Conexão excelente`;
  - texto objetivo de adequação de uso;
  - indicadores discretos (`Download alto`, `Upload bom`, `Baixa latência`, `Sem perda detectada`).
- Card de métricas mantido compacto com foco em valores:
  - `Download 524 Mbps`;
  - `Upload 98,4 Mbps`;
  - `Ping 12 ms`;
  - `Oscilação 4 ms`;
  - `Falhas 0%`;
  - `DNS 21 ms`.
- Card de confiabilidade mantido sem alarme exagerado:
  - `Confiabilidade da medição`;
  - status `Baixa`;
  - recomendação de repetição do teste.
- Card de recomendação ajustado para ação direta:
  - `Teste complementar recomendado`;
  - ação `Abrir avançado`.
- Header/topbar confirmado:
  - botão voltar à esquerda;
  - sem menu hambúrguer;
  - retorno para `Velocidade`.

### Screenshot gerado
`docs/visual-audit/screenshots-v4/resultado-v4.png`

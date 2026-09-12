# Plano: UX responsiva do Linka para Mac

> **Trilha:** Full-flow | **Produto:** Íris | **Arquitetura:** Camillo | **Orquestração:** Codex

## Objetivo

Consolidar o Velocímetro do Mac em um painel responsivo e honesto: ação
explícita para medir, progresso sem escala artificial de Mbps, estados sem
resultados residuais e Histórico inacessível enquanto há medição ativa.

## Mudança técnica

- Alterar somente `LinkaApp/Sources/UI/MacMainView.swift`.
- Limitar o conteúdo a 1120 pt e adaptar o painel entre uma e duas colunas
  internas conforme a largura útil, sem criar cards concorrentes.
- Projetar o gauge a partir de `SpeedTestViewModel.progress`, nunca de um teto
  de velocidade; download, upload e resultado recebem rótulos coerentes.
- Consumir solicitação de Histórico por App Intent sem navegar quando a
  medição estiver ativa.
- Exibir dados finais apenas em `.done`; fases transitórias mostram somente
  o dado que está sendo medido.
- Dar ao macOS uma sheet de Ajustes própria, com tamanho e hierarquia de
  desktop, sem alterar o `Form` compartilhado de iOS/iPad.

## Aceite

- Em 780×560, 1120×700 e maximizada: sem corte, painel esticado ou CTA
  desproporcional.
- Nenhum caminho abre Histórico durante connecting, download ou upload.
- Cancelar, erro e mudança de rede não exibem métricas residuais como
  resultado.
- O gauge comunica fase/progresso real, com rótulo acessível.
- iOS/iPad, `LinkaEngine`, contratos e persistência permanecem intocados.
- Durante a medição, Histórico e Ajustes não abrem; a assinatura não empilha
  uma nova sheet sobre Ajustes no Mac.

## Não-objetivos

- Compartilhamento nativo macOS, detalhe/filtros/exportação de Histórico,
  novos dados Wi-Fi e mudança no XcodeGen.

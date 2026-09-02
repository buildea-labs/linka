# Plano - Issue #135 - Finalizar Ajustes

## Objetivo

Finalizar Ajustes como central simples de controle do produto publicado: plano, compra, rede,
aparencia, links oficiais, suporte, versao/build e ausencia de controles improprios em Release.

## Auditoria antes do codigo

- Linka Plus: ja existe estado Free/Plus, paywall, gerenciar assinatura via Apple e restaurar
  compra. Parcial: a tela nao mostra verificacao ativa do entitlement ao abrir Ajustes.
- Links oficiais: ja existem Sobre, Como medimos, Privacidade e Termos. Parcial: usam
  `linka-speedtest.web.app`, e suporte esta `nil`.
- Site institucional: as URLs respondem HTTP 200, mas as rotas precisam de conteudo especifico
  no codigo local para nao depender de uma Home generica.
- App Store Connect: nao ha metadata canonica no repo. Falta documentar os campos esperados com
  a mesma origem usada pelo app.
- Identificacao Wi-Fi: ja existe preferencia local e pedido de permissao. Parcial: estados de
  permissao negada/restrita e desativada pelo usuario nao ficam distintos o suficiente.
- Wi-Fi avancado: ja existe gate Plus, flags persistidas e chamada ao Atalhos. Parcial: "Ativo"
  depende so de flag local; falta indicar quando esta configurado mas desativado e usar a URL
  oficial do atalho em um unico lugar.
- Aparencia: ja persiste com `@AppStorage("appAppearance")` e e aplicada no root. Falta apenas
  preservar e testar o mapeamento.
- Versao/build: ja le do Bundle e mostra em Ajustes.
- Release: DEBUG UI esta sob `#if DEBUG`, mas existe bloco DEBUG vazio e AdMob com IDs de teste
  no bundle, alem de feature flags de ads congeladas.

## Mudanca

- Centralizar URLs publicas em `https://linka.app` e expor suporte oficial em `suporte@linka.app`.
- Adicionar paginas especificas no site para Sobre, Como medimos, Privacidade, Termos e Suporte.
- Melhorar estado textual/acessivel de assinatura, Wi-Fi e Wi-Fi avancado sem redesenhar Ajustes.
- Centralizar a URL do atalho Wi-Fi avancado.
- Remover configuracao provisoria de ads/teste do app Release e ocultar BannerView como recurso
  congelado ate haver IDs reais.
- Adicionar testes para URLs, estado Wi-Fi, estado Wi-Fi avancado, aparencia e versao/build.

## Aceite

- Ajustes continua usando `Form`, `Section`, `Picker`, `Link` e botoes nativos.
- Free/Plus nao concede acesso sem entitlement ativo.
- Restaurar compra informa sucesso, ausencia de compra ou falha.
- Links usam a origem canonica e apontam para paginas especificas.
- Suporte existe no app e no site.
- Wi-Fi mostra estados distintos para ativo, desativado, necessario e negado/restrito.
- Wi-Fi avancado distingue Free, configurar, ativo e desativado.
- Release nao carrega controles DEBUG nem IDs de teste AdMob.
- Testes, build Debug e build Release passam.

## Nao objetivos

- Nao transformar Ajustes em dashboard.
- Nao criar conta, perfil, tab bar ou novos cards promocionais.
- Nao publicar deploy/site/App Store sem autorizacao explicita.

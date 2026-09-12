# CHANGELOG - Linka

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

## [Em desenvolvimento]

### macOS

- Formalizado o target `LinkaApp_macOS` no XcodeGen, com entitlements, Info.plist e dependências preservados.
- Adicionados comandos nativos de medição/Ajustes, atalhos de teclado, affordances discretas de hover e comportamento de janela responsivo.
- Histórico, compartilhar, painel do roteador, Wi-Fi avançado e App Intents receberam a paridade prevista para o Mac sem transformar a tela em dashboard. A interface é intencionalmente diferente: no iOS a ação de compartilhar fica no contexto da tela; no Mac ela está no menu “Mais” do resultado.

### Geral

- A descoberta de gateway passou a usar uma única fonte canônica baseada na rota ativa, sem varredura Bonjour, associação por nome ou palpite de endereço.
- Adicionados testes do provider de timeline do widget e da leitura do App Group; artefatos locais de build passaram a ser ignorados.

## [v1.1.0] - 2026-09-01
### Melhorias
- Padronização do processo de release e versionamento (Issue #150).
- Unificação da versão na tela de Ajustes para o formato "1.1.0 (42)".
- CI evoluído para validar consistência de versão e build number, e testes em Release.

---

## [v1.0.0-beta] - Agosto 2026

### O Início do Fim da Fricção
O Linka nasce hoje como a ferramenta de medição mais limpa e focada do ecossistema Apple. Deixamos as interfaces poluídas, os gráficos complexos e as obrigatoriedades de login para trás. Construímos um utilitário nativo que respeita o seu tempo e o design do seu iPhone.

**Destaques desta versão:**
- **Abriu, Mediu:** O teste inicia instantaneamente sem exigir conta ou toques desnecessários.
- **Integração Real (Fim das Mentiras):** O motor de medição (`LinkaEngine`) agora se conecta diretamente com infraestruturas globais robustas para entregar dados cravados de Ping, Download e Upload.
- **Linka Assist (Premium):** Introduzimos nosso bot nativo baseado em IA que avalia o seu histórico e entrega insights contextuais sobre a sua rede com um elegante efeito de máquina de escrever. Sem promessas falsas de diagnósticos pesados.
- **Paywall Honesta e Transparente:** O Linka (nível premium) permite a guarda infinita do seu histórico e acesso ao Assist. Limpamos qualquer promessa de feature futura que ainda não está no motor, e implementamos todas as exigências legais da Apple.
- **Estética Apple-first:** Transições orgânicas de *morphing* ao concluir o teste. Nada de engasgos, apenas fluidez.

O app está limpo, maduro e pronto para o TestFlight!

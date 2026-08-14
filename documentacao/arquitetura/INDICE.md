# Documentação — linka-speedtest

**Atualizado:** 2026-08-14
**Autoridade única de governança:** [`AGENTS.md`](../../AGENTS.md) na raiz do repo.

Este arquivo é apenas um índice. Ele não decide nada — só aponta para o que existe hoje e é considerado válido. Em caso de conflito entre qualquer doc listado aqui e `AGENTS.md`, `AGENTS.md` vence (ver ordem de precedência na seção 3 do próprio `AGENTS.md`).

---

## Governança e produto

- [`AGENTS.md`](../../AGENTS.md) — autoridade única do repositório
- [`CLAUDE.md`](../../CLAUDE.md) — só reencaminha para `AGENTS.md`
- [`documentacao/produto/LINKA_PLUS.md`](../produto/LINKA_PLUS.md) — fronteira Linka Free / Linka Plus, escopo do Assist, fronteira com o SignallQ
- [`documentacao/produto/VOZ.md`](../produto/VOZ.md) — voz, tom e copy oficial
- [`documentacao/funcional/HISTORIA.md`](../funcional/HISTORIA.md) — origem histórica do produto (Velu → SignallQ → Linka atual); explicitamente enquadrado como história, não como escopo atual
- [`documentacao/funcional/VISAO.md`](../funcional/VISAO.md) — visão de produto atual (Apple-first, resultado como protagonista, sem fricção)

## Arquitetura do motor (pacotes Swift em `aplicativo-ios/`)

- [`PLANO_HISTORICO_MEDICOES.md`](PLANO_HISTORICO_MEDICOES.md) — `NetworkCore` + `MeasurementHistory`
- [`PLANO_NETWORK_INSIGHTS.md`](PLANO_NETWORK_INSIGHTS.md) — `NetworkInsights` (fatos estatísticos, sem diagnóstico)
- [`PLANO_NETWORK_ASSIST.md`](PLANO_NETWORK_ASSIST.md) — `NetworkAssist` (contexto para IA, sem diagnóstico)
- [`contratos/network-measurement.schema.json`](contratos/network-measurement.schema.json) — schema canônico v1 da medição
- [`contratos/fixtures/`](contratos/fixtures/) — exemplos válidos e inválidos

## Design

- [`documentacao/design/design_system/readme.md`](../design/design_system/readme.md) — Design System atual (Apple HIG, tokens, motion, contraste WCAG AA nos dois temas)
- [`documentacao/design/design_system/SKILL.md`](../design/design_system/SKILL.md) — wrapper de skill
- [`documentacao/design/design_system/components/`](../design/design_system/) — 19 componentes documentados (brand, content, core, layout, speedtest)
- [`documentacao/design/prototipo/`](../design/prototipo/) — protótipo canônico do novo Linka (fluxo e geometria)

## Release notes

- [`RELEASE_NOTES.md`](../../RELEASE_NOTES.md) — v1.0.0-beta (iOS)

## Referências externas

- [`DSI_ARQUITETURA.md`](../../DSI_ARQUITETURA.md) — arquitetura do backend DSI (seções 1-3 do antigo plano Firebase/Web/Desktop estão marcadas como superadas)

---

## Arquivado nesta auditoria (2026-08-14)

Toda a documentação que descrevia workspaces antigos (`E:\Projetos\Linka\`, `C:\Projetos\Linka WebApp\`, `D:\Projetos\Linka SpeedTest\`) ou apresentava os projetos `linkaAndroidKotlin/` e `linkaSpeedtestPwa/` como realidade atual foi movida para `<pasta>/.old/` com sufixo `.2026-08-14.old.md`.

Também foram arquivados:

- **Pasta `aplicativo-android/` inteira** (removida do working tree; recuperável via `git log`) — o código Kotlin nativo já estava em `kotlin/_archive/`, o build Android/Capacitor não é mais alvo do produto. O Linka é **exclusivamente Apple** (iPhone/iPad/Mac): não haverá versão Web nem Android. O site em `aplicacao-web/` continua existindo, mas apenas como site institucional/marketing, não como versão do produto.
- **Roster de personas legadas** (Claudete/Renan/Marcelo/Gema/Lia/Otavio/Camilo/Nina/**Taisa**) documentado em `GUIA_CONVIVENCIA_IA.md` / `GUIA_DESENVOLVIMENTO_IA.md` / `GUIA_SELECAO_MODELO_IA.md` — superado por `AGENTS.md` §4-5 e explicitamente listado como aposentado em §13.
- **`PoliticaBranchUnico.md`** — a regra "toda IA trabalha exclusivamente na branch `main`" conflitava diretamente com `AGENTS.md` §12 ("Trabalhe em branch para mudanças relevantes") e §13 ("regra de trabalhar sempre diretamente em `main`" está formalmente aposentada). A política de branches vive agora em `AGENTS.md` §12.
- **Design system do SignallQ** (`design_system/_ds/signallq-design-system-.../`) — pacote de outro produto (MD3, Android StatusBar, Google Sans Flex) que aterrissou por engano nesta pasta.
- **Dois snapshots antigos do design tool** (Quicksand, sem dark mode) — superados pelo `design_system/readme.md` canônico.

Cada arquivo em `.old/` mantém seu nome original com data anexada. O motivo específico por documento está listado nos títulos e no primeiro parágrafo dos próprios arquivos arquivados; o motivo estrutural (a que direção do produto ele pertencia) está resumido aqui.

### Onde procurar cada `.old/`

- `documentacao/arquitetura/.old/`
- `documentacao/funcional/.old/`
- `documentacao/tecnica/.old/`
- `documentacao/deploy-e-scripts/.old/`
- `documentacao/design/design_system/_ds/.old/`
- `documentacao/design/design_system/uploads/.old/`
- `documentacao/design/prototipo/.old/`

Nada em `.old/` é referência viva. Se algum conteúdo lá se provar ainda útil, o padrão é extrair explicitamente para um novo doc no local certo — não reativar o arquivo antigo.

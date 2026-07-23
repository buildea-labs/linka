# Material Design 3 — Tokens e Uso no Linka

> Tokens de design, paleta de cores, tipografia e componentes MD3 em uso no ecossistema Linka.
> Inclui valores reais extraidos do codigo.

---

## 1. Contexto de uso

O Linka usa Material Design 3 como sistema de design base, com customizacoes proprias que formam o
design system "iOS-Calma" — superficies neutras, zero sombras, hierarquia pelo tamanho, accent restrito.

| Projeto | Como usa MD3 |
|---|---|
| Android (`linkaAndroidKotlin/`) | `ThemeData` com `useMaterial3: true`, `ColorScheme`, componentes nativos MD3 via Flutter |
| PWA (`linkaSpeedtestPwa/`) | CSS Custom Properties como tokens — convencao MD3 adaptada para web |

> Nota: o projeto Android usa Flutter/Dart (nao Kotlin/Compose) para a camada de UI. O tema e definido em
> `linkaAndroidKotlin/source/app/lib/src/features/redesign/theme/linka_theme.dart`.

---

## 2. Paleta de cores — Android (Dart/Flutter)

Arquivo de referencia: `linkaAndroidKotlin/source/app/lib/src/features/redesign/theme/linka_theme.dart`

### Tokens semanticos — modo claro

| Token | Valor | Uso |
|---|---|---|
| `bgPrimary` | `#FFFFFF` | Fundo principal |
| `bgSecondary` | `#F6F7F9` | Cards, listas |
| `bgAccentSubtle` | `#F3F0FF` | Fundo de badge accent |
| `textPrimary` | `#0D0D1A` | Texto principal |
| `textSecondary` | `#6B7280` | Texto de suporte |
| `textTertiary` | `#9CA3AF` | Labels, metadados |
| `border` | `#E5E7EB` | Bordas de cards |
| `accent` | `#6C2BFF` | CTAs, links, foco |
| `blue` | `#3AB6FF` | Download (velocidade) |
| `success` | `#22C55E` | Upload, estados bons |
| `warning` | `#F5A623` | Avisos |
| `error` | `#FF4D4F` | Falha, erro critico |

### Tokens semanticos — modo escuro

| Token | Valor | Uso |
|---|---|---|
| `bgPrimary` | `#000000` | Fundo principal |
| `bgSecondary` | `#0D0D0D` | Cards, listas |
| `bgAccentSubtle` | `#140A28` | Fundo de badge accent |
| `bgTertiary` | `#111111` | Camadas adicionais |
| `textPrimary` | `#F3F4F6` | Texto principal |
| `textSecondary` | `#A1A7B3` | Texto de suporte |
| `textTertiary` | `#6B7280` | Labels, metadados |
| `border` | `#1C1C1E` | Bordas de cards |
| `accent` | `#6C2BFF` | CTAs, links, foco (identico ao claro) |
| `blue` | `#3AB6FF` | Download (identico ao claro) |
| `success` | `#22C55E` | Upload (identico ao claro) |
| `warning` | `#F5A623` | Avisos (identico ao claro) |
| `error` | `#FF4D4F` | Falha (identico ao claro) |

### Mapeamento para ColorScheme MD3

| MD3 slot | Valor Android |
|---|---|
| `primary` | `accent` (`#6C2BFF`) |
| `secondary` | `accent` (`#6C2BFF`) |
| `surface` | `bgSecondary` |
| `error` | `error` |
| `outline` | `border` |
| `onPrimary` | `Colors.white` |
| `onSurface` | `textPrimary` |
| `onSurfaceVariant` | `textSecondary` |

---

## 3. Paleta de cores — PWA (CSS Custom Properties)

Arquivo de referencia: `linkaSpeedtestPwa/docs/GuiaBranding.md` (secao Cores)

### Tokens de superficie

| Token | Dark | Light | Uso |
|---|---|---|---|
| `--bg` | `#0D0D12` | `#F2F2F7` | Fundo principal |
| `--surface` | `#16161E` | `#FFFFFF` | Sheets sobrepostas |
| `--surface-deep` | `#11121A` | `#FBFBFD` | Tom canonico de card |
| `--surface-2` | `#1E1E28` | `#F2F2F7` | Hover/active |
| `--surface-3` | `#25252F` | `#ECECF1` | Separadores, track do gauge |
| `--hairline` | `rgba(255,255,255,0.06)` | `rgba(0,0,0,0.06)` | Separadores de linha |
| `--border` | `rgba(255,255,255,0.10)` | `rgba(0,0,0,0.10)` | Bordas de cards |

### Tokens de cor semantica

| Token | Dark | Light | Uso |
|---|---|---|---|
| `--accent` | `#6C2BFF` | `#6C2BFF` | CTAs, links, foco, anel do gauge |
| `--accent-tint` | `rgba(108,43,255,0.12)` | `rgba(108,43,255,0.10)` | Fundo de icones accent |
| `--dl` | `#3AB6FF` | `#0A84FF` | Download — todos os valores e icones |
| `--dl-tint` | `rgba(58,182,255,0.12)` | `rgba(10,132,255,0.10)` | Fundo de icone download |
| `--ul` | `#22C55E` | `#30D158` | Upload — todos os valores e icones |
| `--ul-tint` | `rgba(34,197,94,0.12)` | `rgba(48,209,88,0.10)` | Fundo de icone upload |
| `--error` | `#FF453A` | `#FF3B30` | Falha, latencia critica |
| `--warn` | `#F5A623` | `#FF9F0A` | Aviso, jitter alto |

### Tokens de texto

| Token | Dark | Light | Uso |
|---|---|---|---|
| `--text` | `#F2F2F7` | `#1C1C1E` | Texto primario |
| `--text-2` | `rgba(242,242,247,0.55)` | `rgba(28,28,30,0.55)` | Texto secundario |
| `--text-3` | `rgba(242,242,247,0.30)` | `rgba(28,28,30,0.30)` | Labels, metadados |

---

## 4. Tipografia

### Android — escala tipografica (Dart/Flutter)

Fonte principal: **Geist** (para display e body)

| Papel | Tamanho | Peso | Tracking | Line-height |
|---|---|---|---|---|
| `h1` (displayLarge) | 34px | 700 | -0.015em | 36/34 |
| `h2` (displayMedium) | 20px | 600 | -0.005em | 24/20 |
| `h3` (displaySmall) | 15px | 500 | neutro | 20/15 |
| `body` | 14px | 400 | neutro | 20/14 |
| `secondaryMetric` | 17px | 600 | -0.005em | 20/17 |
| `label` | 12px | 400 | +0.01em | 16/12 |

Todos os estilos usam `FontFeature.tabularFigures()` onde aplicavel (metricas numericas).

### PWA — escala tipografica

Fontes disponíveis via tokens:
- `var(--font-display)` e `var(--font-body)` → **Geist** (300, 400, 500, 600, 700)
- `var(--font-mono)` → **JetBrains Mono** (400, 500, 600, 700)
- `var(--font-editorial)` → **Instrument Serif** — reservada, nao usada em producao

| Papel | Tamanho | Peso | Familia |
|---|---|---|---|
| Numero hero (gauge) | 72px | 700 | `--font-display` |
| Titulo de tela grande | 22-24px | 700 | `--font-display` |
| Titulo de tela medio | 20px | 700 | `--font-display` |
| Valor de metrica (lista) | 14px | 600 | `--font-display` |
| Botao primario | 15px | 500-600 | `--font-display` |
| Body / descricao | 13-14px | 400 | `--font-body` |
| Label secundario | 12px | 400-500 | `--font-body` |
| Label uppercase (secao) | 11px | 600 | `--font-display`, `letter-spacing: 0.06em` |
| Metadado / hint | 11-12px | 400 | `--font-body` |
| Valores numericos em listas | qualquer | qualquer | `--font-mono` + `tabular-nums` |

**Regra de uso de mono:** JetBrains Mono e exclusiva para VALORES NUMERICOS com tabular-nums.
Nunca para labels, mesmo em telas tecnicas.

---

## 5. Espaçamento

### Android — sistema de espacamento (4pt)

| Token | Valor | Uso tipico |
|---|---|---|
| `spacingXs` | 4dp | Gap minimo |
| `spacingSm` | 8dp | Gap interno de chips |
| `spacingMd` | 12dp | Gap padrao entre elementos |
| `spacingLg` | 16dp | Gap entre secoes, padding horizontal |
| `spacingXl` | 24dp | Separacao maior entre blocos |
| `spacingXxl` | 32dp | Margem de tela |

### Android — raios de borda

| Token | Valor | Uso |
|---|---|---|
| `radiusCard` | 16dp | Cards |
| `radiusButton` | 12dp | Botoes |
| `radiusInput` | 10dp | Campos de entrada |

### PWA — tokens de espacamento

| Token | Valor | Uso tipico |
|---|---|---|
| `--space-xs` | 4px | Gap minimo entre icone e texto |
| `--space-sm` | 8px | Gap interno de chips, rows compactas |
| `--space-md` | 12px | Gap padrao entre elementos |
| `--space-lg` | 16px | Gap entre secoes, padding horizontal |
| `--space-xl` | 24px | Separacao maior entre blocos |
| `--space-2xl` | 32px | Margem de tela |
| `--space-3xl` | 48px | Espaco vertical generoso |

### PWA — tokens de raio

| Token | Valor | Uso tipico |
|---|---|---|
| `--radius-sm` | 8px | Icones pequenos (28px), chips |
| `--radius` | 12px | Cards, listas, botoes |
| `--radius-lg` | 20px | Modais, sheets |
| `--radius-xl` | 28px | Elementos grandes arredondados |
| `--radius-pill` | 9999px | Badges, step-badges |

---

## 6. Componentes MD3 em uso

### Android

| Componente MD3 | Customizacao Linka |
|---|---|
| `FilledButton` | Fundo `accent`, texto branco, altura minima 52dp, radius 12dp |
| `OutlinedButton` | Borda `accent`, texto `accent`, altura minima 52dp, radius 12dp |
| `TextButton` | Cor `accent` |
| `Chip` | Radius `999dp` (pill), background `bgSecondary`, selecionado = `bgAccentSubtle` |
| `ListTile` | Icone cor `accent`, texto `textPrimary` |
| `Dialog` | Background `bgSecondary`, radius 16dp, borda `border` |
| `SnackBar` | Floating, radius 12dp, background escuro |
| `FAB` | Background `accent`, icone branco |
| `Switch` | Track/thumb cor `accent` quando selecionado |
| `AppBar` | Sem elevacao, centro, altura 56dp, fundo `bgPrimary` |
| `TabBar` | Indicador `accent`, label selecionado `accent`, nao selecionado `textSecondary` |
| `Card` | Radius 12dp, sem sombra no modo escuro, sombra sutil no claro |

### PWA

| Componente | Arquivo | Descricao |
|---|---|---|
| `Chip` | `src/components/Chip.tsx` | Badge semantico: `good`, `maybe`, `bad`, `accent`, `neutral` |
| `IOSList` | `src/components/IOSList.tsx` | Lista estilo iOS Settings — fundo `--surface`, borda, radius |
| `Gauge` | `src/components/Gauge.tsx` | SVG com dois circles: track `--surface-3` + fill por fase |
| `TopBar` | `src/components/TopBar.tsx` | Barra superior com scroll-aware blur |
| `PageHeader` | `src/components/PageHeader.tsx` | Titulo de tela no topo do scroll content |
| `Skeleton` | `src/components/Skeleton.tsx` | Estado de loading |
| `DraggableSheet` | `src/components/DraggableSheet.tsx` | Sheet arrastavel |
| `Accordion` | `src/components/Accordion.tsx` | Secao expansivel |

---

## 7. Regras de uso de cor

**Valido para ambas as plataformas:**

- **Zero sombras** (box-shadow, text-shadow, elevation). Profundidade por cor de superficie.
- **Accent `#6C2BFF`** apenas em: botoes primarios, orb, anel do gauge, icone pinned, links.
- **DL (azul) e UL (verde)** reservados para metricas de velocidade.
- **Gradientes:** proibidos. Excecao: `--bg-radial` no body do PWA (definido em `tokens.css` — nao duplicar).
- Cores sempre via tokens — nunca valores hex hardcoded em componentes.

---

## 8. Animacoes e transicoes

### PWA — tokens de transicao

| Token | Valor | Uso |
|---|---|---|
| `--t-fast` | `180ms cubic-bezier(0.32, 0.72, 0, 1)` | Hover, active, fade rapido |
| `--t-med` | `280ms cubic-bezier(0.32, 0.72, 0, 1)` | Transicoes de tela, entrada de modal |
| `--t-slow` | `480ms cubic-bezier(0.32, 0.72, 0, 1)` | Animacoes expressivas (orb, gauge fill) |

- Maximo 300ms para transicoes utilitarias.
- Classe de entrada de tela: `.fade-in` (definida em `src/index.css`).

### Android

- Transicoes via `AnimatedContent`, `AnimatedVisibility` do Compose — [a confirmar valores especificos]

---

## 9. Arquivos de tema por plataforma

| Plataforma | Arquivo de tema |
|---|---|
| Android (Flutter) | `linkaAndroidKotlin/source/app/lib/src/features/redesign/theme/linka_theme.dart` |
| Android (Kotlin nativo) | `linkaAndroidKotlin/linka-android-kotlin/app/src/main/res/values/themes.xml` |
| PWA | tokens.css (dentro de `linkaSpeedtestPwa/src/`) — [a confirmar path exato] |

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa

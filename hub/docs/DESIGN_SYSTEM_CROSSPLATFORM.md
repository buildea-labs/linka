# Design System Cross-Platform — Linka

**Versão:** Android v0.6.3 | PWA v1.0.0
**Público-alvo:** Time de desenvolvimento humano
**Última atualização:** 2026-05-16
**Mantido por:** Taisa

> Este documento responde: "Como o Linka se parece e se comporta visualmente, nas duas plataformas?"
> Para tokens detalhados por plataforma com valores exatos, consulte `MATERIAL_DESIGN_3.md`.
> Para funcionalidades e fluxos, consulte `FUNCIONAL_CROSSPLATFORM.md`.

---

## 1. Princípios Visuais — Ambas as Plataformas

O design system do Linka segue a direção **iOS-Calma**, aplicada de forma idêntica nas duas plataformas.

### 1.1 Os Cinco Princípios

| Princípio | Descrição | Android | PWA |
|---|---|---|---|
| **Superfícies neutras** | Sem fundo colorido de tela. Toda cor está nos dados. | `bgPrimary: #FFFFFF / #000000` | `--bg: #F2F2F7 / #0D0D12` |
| **Hierarquia pelo tamanho** | O número hero comunica a métrica. Labels e contexto ficam secundários. | `displayLarge: 34sp` para número hero | Número hero: 72px (gauge), 96px (RunningScreen) |
| **Zero sombras** | Profundidade via cor de superfície, nunca por sombra. | `elevation = 0` em todos os componentes | `box-shadow: none` absoluto |
| **Accent restrito** | `#6C2BFF` apenas em elementos interativos primários. | Botão CTA, navegação ativa, Orbit | Botão CTA, orb animado, anel do gauge, ícone pinned |
| **Listas estilo iOS Settings** | No lugar de cards aninhados com sombra. | Componente próprio | `IOSList.tsx` |

### 1.2 Regras Invioláveis

**Zero sombras:**
- Android: nenhum `elevation` nos componentes (exceto shadow sutil em cards no tema claro)
- PWA: `box-shadow: none` e `text-shadow: none` em todos os componentes

**Accent restrito — `#6C2BFF` aparece apenas em:**
- Botão primário (CTA)
- Orb animado (tela de medição)
- Anel do gauge (durante medição)
- Ícone pinned / navegação ativa
- Links de navegação

**Gradientes proibidos:**
- Zero gradientes em componentes e telas
- Exceção única: PWA tem `--bg-radial` no `body` (definido em `tokens.css` — não duplicar)
- Android: sem gradientes — sem equivalente ao `--bg-radial` do PWA. Fundos Android são cores sólidas puras (`#000000` dark / `#FFFFFF` light)

**Cores semânticas de velocidade:**
- Download: sempre azul (`#3AB6FF` dark / `#0A84FF` light)
- Upload: sempre verde (`#22C55E` dark / `#30D158` light)
- Latência: roxo/accent (`#6C2BFF`)
- Jitter: amarelo/aviso (`#F5A623`)
- Perda de pacotes: vermelho/erro (`#FF453A`)
- Essas cores são **reservadas** — não usar em outros contextos

---

## 2. Paleta de Cores

### 2.1 Brand — Compartilhado

| Conceito | Valor | Plataformas | Observação |
|---|---|---|---|
| Accent primário | `#6C2BFF` | Ambas | Idêntico nas duas |
| Accent secundário (blue) | `#2563EB` / `#3AB6FF` | Ambas | Valores ligeiramente diferentes por plataforma |
| Download (azul) | `#3AB6FF` dark / `#0A84FF` light | Ambas | Android mantém constante; PWA muda por tema |
| Upload (verde) | `#22C55E` dark / `#30D158` light | Ambas | Android mantém constante; PWA muda por tema |

### 2.2 Superfícies — Android

| Token | Tema Claro | Tema Escuro | Uso |
|---|---|---|---|
| `bgPrimary` | `#FFFFFF` | `#000000` | Fundo principal de telas |
| `bgSecondary` | `#F3F4F6` | `#1A1A1A` | Backgrounds secundários, superfícies elevadas |
| `bgCard` | `#FFFFFF` | `#111111` | Cards, superfícies de conteúdo |
| `textPrimary` | `#0D0D1A` | `#F3F4F6` | Texto principal (título, corpo) |
| `textSecondary` | `#6B7280` | `#9CA3AF` | Texto secundário, descrições |
| `textTertiary` | `#9CA3AF` | `#6B7280` | Labels, captions, hints |
| `border` | `#E5E7EB` | `#2A2A2A` | Divisores, bordas leves |

### 2.3 Superfícies — PWA

| Token CSS | Tema Escuro | Tema Claro | Uso |
|---|---|---|---|
| `--bg` | `#0D0D12` | `#F2F2F7` | Fundo principal |
| `--surface` | `#16161E` | `#FFFFFF` | Sheets sobrepostas |
| `--surface-deep` | `#11121A` | `#FBFBFD` | Tom canônico de card |
| `--surface-2` | `#1E1E28` | `#F2F2F7` | Hover / active |
| `--surface-3` | `#25252F` | `#ECECF1` | Separadores, track do gauge |
| `--hairline` | `rgba(255,255,255,0.06)` | `rgba(0,0,0,0.06)` | Separadores de linha |
| `--border` | `rgba(255,255,255,0.10)` | `rgba(0,0,0,0.10)` | Bordas de cards |
| `--text` | `#F2F2F7` | `#1C1C1E` | Texto primário |
| `--text-2` | `rgba(242,242,247,0.55)` | `rgba(28,28,30,0.55)` | Texto secundário |
| `--text-3` | `rgba(242,242,247,0.30)` | `rgba(28,28,30,0.30)` | Labels, metadados |

**Diferença estrutural:** PWA usa gradiente radial no `body` (`--bg-radial`). Android usa cores sólidas.

### 2.4 Status — Comparação

| Conceito | Android | PWA Dark | PWA Light | Alinhado? |
|---|---|---|---|---|
| Sucesso | `#22C55E` | `#34D399` | `#16A34A` | Parcial |
| Aviso | `#F5A623` | `#FBBF24` | `#D97706` | Parcial |
| Erro | `#FF4D4F` | `#FF453A` | `#FF3B30` | Parcial |
| Accent | `#6C2BFF` | `#6C2BFF` | `#6C2BFF` | ✓ Idêntico |

### 2.5 Orbit — Sempre Escuro (Idêntico nas Duas Plataformas)

A paleta de IA é **idêntica** nas duas plataformas. Não adapta ao tema do sistema — mantém sempre escuro.

| Token | Valor | Uso |
|---|---|---|
| Background Orbit | `#0D0D1A` | Fundo da interface de IA |
| Surface | `#1A0B2E` | Superfícies secundárias |
| Card | `#1E1130` | Cards de bolhas de IA |
| Texto primário | `#F3F4F6` | Texto de alta legibilidade |
| Accent | `#6C2BFF` | Destaques, ações |

### 2.6 SpeedTest — Phase Colors

| Fase | Android | PWA Dark | PWA Light | Alinhado? |
|---|---|---|---|---|
| Latência | `#60A5FA` | `#60A5FA` | `#2563EB` | Parcial |
| Download | `#34D399` | `#34D399` | `#16A34A` | Parcial |
| Upload | `#FBBF24` | `#FBBF24` | `#D97706` | Parcial |

---

## 3. Tipografia

### 3.1 Família de Fontes

| Uso | Android | PWA | Alinhado? |
|---|---|---|---|
| Display / Body | Fonte padrão do sistema MD3 (sem família definida em `linkaTypography` — `LinkaTheme.kt` usa apenas `TextStyle` com `fontSize` e `fontWeight`, sem `fontFamily`) | Geist (`--font-display`, `--font-body`) | Não alinhado — Android usa fonte do sistema; PWA usa Geist |
| Monoespaçada | Não explicitado | JetBrains Mono (`--font-mono`) | PWA-only |
| Editorial | Não explicitado | Instrument Serif (`--font-editorial`) — reservada, não usada em produção | PWA-only |

**Regra PWA — mono:** JetBrains Mono exclusiva para valores numéricos com `tabular-nums`. Nunca para labels, mesmo em telas técnicas.

**Fontes proibidas no PWA:** `Inter`, `Space Grotesk`, `system-ui` hardcoded em CSS/TSX.

### 3.2 Escala Tipográfica — Android (Material Design 3)

Todos os tamanhos em `sp` para respeitar `fontScale` do sistema (acessibilidade).

| Estilo MD3 | Tamanho | Peso | Uso |
|---|---|---|---|
| `displayLarge` | 34 sp | Bold | Heading de destaque, hero text |
| `headlineLarge` | 24 sp | SemiBold | Títulos principais de seção |
| `headlineMedium` | 20 sp | SemiBold | Subtítulos de seção |
| `headlineSmall` | 18 sp | SemiBold | Headings menores, card titles |
| `titleLarge` | 16 sp | Medium | Títulos de features |
| `titleMedium` | 15 sp | Medium | Títulos secundários |
| `titleSmall` | 14 sp | Medium | Labels de componentes |
| `bodyLarge` | 16 sp | Normal | Texto principal, descrições longas |
| `bodyMedium` | 14 sp | Normal | Corpo padrão |
| `bodySmall` | 12 sp | Normal | Texto menor, suplementar |
| `labelLarge` | 14 sp | Medium | Labels de botões/chips |
| `labelMedium` | 12 sp | Normal | Hints, captions |
| `labelSmall` | 11 sp | Normal | Footnotes |

### 3.3 Escala Tipográfica — PWA

| Papel | Tamanho | Peso | Família |
|---|---|---|---|
| Número hero (gauge) | 72px | 700 | `--font-display` |
| Número instantâneo (RunningScreen) | 96px | 700 | `--font-display` |
| Título de tela grande | 24–32px | 700 | `--font-display` |
| Título de tela médio | 20px | 700 | `--font-display` |
| Valor de métrica (lista) | 14px | 600 | `--font-display` |
| Botão primário | 15px | 500–600 | `--font-display` |
| Body / descrição | 13–14px | 400 | `--font-body` |
| Label secundário | 12px | 400–500 | `--font-body` |
| Label uppercase (seção) | 11px | 600 | `--font-display` + `letter-spacing: 0.06em` |
| Metadado / hint | 11–12px | 400 | `--font-body` |
| Valores numéricos em listas | qualquer | qualquer | `--font-mono` + `tabular-nums` |

### 3.4 Correspondência Android ↔ PWA

| Contexto | Android | PWA | Nota |
|---|---|---|---|
| Número hero | `displayLarge` (34 sp) | 72px (gauge) / 96px (running) | PWA usa tamanhos maiores no hero |
| Headline | `headlineLarge` (24 sp) | 24–32px | Compatíveis |
| Body | `bodyMedium` (14 sp) | 14px | Idêntico |
| Label | `labelMedium` (12 sp) | 12px | Idêntico |

**Acessibilidade Android:** Mínimo `bodyMedium` (14sp) para texto de leitura. Todos os tamanhos em `sp` para respeitar zoom do sistema.

---

## 4. Espaçamento e Grid

### 4.1 Sistema de Espaçamento

| Token | Android (`LkSpacing`) | PWA (`--space-*`) | Alinhado? |
|---|---|---|---|
| xs | 4 dp | 4px | ✓ |
| sm | 8 dp | 8px | ✓ |
| md | 12 dp | 12px | ✓ |
| lg | 16 dp | 16px | ✓ |
| xl | 24 dp | 24px | ✓ |
| xxl | 32 dp | 32px | ✓ |
| 3xl | — | 48px | PWA-only |

**Grid base:** Android usa grid 8dp (MD3). PWA usa grid 4px (Tailwind). Multiplicadores compatíveis.

### 4.2 Raios de Borda

| Contexto | Android | PWA | Alinhado? |
|---|---|---|---|
| Card | 16 dp | 12px (`--radius`) | Próximo |
| Botão | 12 dp | 12px | ✓ |
| Input | 12 dp | 12px | ✓ |
| Pequeno (ícones, chips) | — | 8px (`--radius-sm`) | PWA-only |
| Modal / Sheet | — | 20px (`--radius-lg`) | PWA-only |
| Elementos grandes | — | 28px (`--radius-xl`) | PWA-only |
| Pill (badges) | 999 dp (em chips) | 9999px (`--radius-pill`) | ✓ |

**Nota:** Android define `card = 16dp` nos tokens, mas `MATERIAL_DESIGN_3.md` indica 12dp para cards. Verificar `LinkaTheme.kt` para valor canônico.

### 4.3 Aplicação Correta (Android)

```kotlin
// Correto — usar tokens
Box(modifier = Modifier.padding(LkSpacing.lg))  // 16 dp

// Evitar — hardcoding
Box(modifier = Modifier.padding(16.dp))
```

### 4.4 Hit Targets (Acessibilidade)

Mínimo 44×44 px (PWA) / 56dp (Android MD3) para elementos interativos por toque.

---

## 5. Componentes — Mapeamento Cross-Platform

### 5.1 Componentes com Equivalente Direto

| Componente Android | Arquivo Android | Equivalente PWA | Arquivo PWA |
|---|---|---|---|
| `GaugeCircular` | `GaugeCircular.kt` | `Gauge` | `Gauge.tsx` |
| `MiniGrafico` | `MiniGrafico.kt` | Incorporado em `Gauge.tsx` | `Gauge.tsx` |
| `PulseResultCard` | `PulseResultCard.kt` | `PulseResultCard` | `PulseResultCard.tsx` |
| `LinkaPulseSymbol` | `LinkaPulseSymbol.kt` | `LinkaPulseSymbol` | `LinkaPulseSymbol.tsx` |
| `AppBorderGlowEffect` | `AppBorderGlowEffect.kt` | `AppBorderGlow` | `AppBorderGlow.tsx` |
| `RotatingMessageText` | `RotatingMessageText.kt` | `RotatingMessage` | `RotatingMessage.tsx` |
| `DiagnosisChipsRow` | `DiagnosisChipsRow.kt` | `DiagnosisChips` | `DiagnosisChips.tsx` |
| `ContextualQuestionCard` | `ContextualQuestionCard.kt` | `ContextualQuestion` | `ContextualQuestion.tsx` |
| `SheetDragHandle` | `SheetDragHandle.kt` | `DraggableSheet` | `DraggableSheet.tsx` |

### 5.2 Componentes Android sem Equivalente PWA

| Componente | Arquivo | Motivo da Ausência no PWA |
|---|---|---|
| `OrbitSymbol` | `OrbitSymbol.kt` | Chat Orbit é Android-only |
| `OrbitTopBar` | `OrbitTopBar.kt` | Chat Orbit é Android-only |
| `OrbitInputArea` | `OrbitInputArea.kt` | Chat Orbit é Android-only |
| `OrbitUserMessageBubble` | `OrbitUserMessageBubble.kt` | Chat Orbit é Android-only |
| `OrbitAiMessageBubble` | `OrbitAiMessageBubble.kt` | Chat Orbit é Android-only |
| `OrbitTechnicalResultBubble` | `OrbitTechnicalResultBubble.kt` | Chat Orbit é Android-only |
| `OrbitThinkingBubble` | `OrbitThinkingBubble.kt` | Chat Orbit é Android-only |
| `OrbitWelcomeState` | `OrbitWelcomeState.kt` | Chat Orbit é Android-only |
| `OrbitActionsCard` | `OrbitActionsCard.kt` | Chat Orbit é Android-only |
| `OrbitInlineQuestion` | `OrbitInlineQuestion.kt` | Chat Orbit é Android-only |
| `WifiChannelGuide` | `WifiChannelGuide.kt` | Wi-Fi detalhado é Android-only |
| `SilentSpeedtestIndicator` | `SilentSpeedtestIndicator.kt` | WorkManager é Android-only |
| `LinkaIaHeader` | `LinkaIaHeader.kt` | Layout específico Android |
| `AiModelFooter` | `AiModelFooter.kt` | Layout específico Android |

### 5.3 Componentes PWA sem Equivalente Android

| Componente | Arquivo | Motivo da Ausência no Android |
|---|---|---|
| `BottomNavBar` | `BottomNavBar.tsx` | Android usa BottomNavBar nativo do Compose |
| `IOSList` | `IOSList.tsx` | Android usa componente nativo |
| `TopBar` | `TopBar.tsx` | Android usa TopAppBar do MD3 |
| `BackButton` | `BackButton.tsx` | Android usa navegação nativa |
| `HamburgerMenu` | `HamburgerMenu.tsx` | Android usa padrão de navegação diferente |
| `PageHeader` | `PageHeader.tsx` | Layout específico PWA (scroll-aware) |
| `LiveChart` | `LiveChart.tsx` | Android tem `MiniGrafico.kt` via Canvas + `PontoAoVivo` list (publicada no `SnapshotExecucaoSpeedtest`) — gráfico em tempo real via Canvas, porém com abordagem diferente (não é um equivalente direto do LiveChart) |
| `PathRow` | `PathRow.tsx` | Visualização específica PWA |
| `Skeleton` | `Skeleton.tsx` | Android usa CircularProgressIndicator |
| `PullToRefreshIndicator` | `PullToRefreshIndicator.tsx` | PWA-only (gesto) |
| `PwaUpdatePrompt` | `PwaUpdatePrompt.tsx` | Service Worker — PWA-only |
| `InfoTooltip` | `InfoTooltip.tsx` | Android usa componente nativo |
| `Accordion` | `Accordion.tsx` | Android usa ExpansionPanel ou custom |

### 5.4 Componentes MD3 em Uso — Android

| Componente MD3 | Customização Linka |
|---|---|
| `FilledButton` | Fundo `accent`, texto branco, altura mínima 52dp, radius 12dp |
| `OutlinedButton` | Borda `accent`, texto `accent`, altura mínima 52dp |
| `TextButton` | Cor `accent` |
| `Chip` | Radius 999dp (pill), background `bgSecondary`, selecionado = `bgAccentSubtle` |
| `ListTile` | Ícone cor `accent`, texto `textPrimary` |
| `Card` | Radius 12dp, sem sombra no escuro, sombra sutil no claro |
| `AppBar` | Sem elevação, altura 56dp, fundo `bgPrimary` |
| `Switch` | Track/thumb cor `accent` quando selecionado |
| `FAB` | Background `accent`, ícone branco |

---

## 6. Estados Visuais Obrigatórios

Todos os estados abaixo são obrigatórios em ambas as plataformas. Nenhum componente pode ficar sem estado de loading, erro ou vazio quando aplicável.

### 6.1 Loading

| Estado | Android | PWA |
|---|---|---|
| Tela carregando | `CircularProgressIndicator` (MD3) | `Skeleton.tsx` — placeholder animado |
| Dado em carregamento inline | `CircularProgressIndicator` (MD3) — sem shimmer (biblioteca de shimmer não identificada no código) | `Skeleton.tsx` |
| IA pensando | `OrbitThinkingBubble.kt` — bolha animada com indicador de loading no chat (Android-only) | Sem estado específico de "IA pensando" — diagnóstico exibido como card após carregamento |
| Speedtest rodando | `GaugeCircular.kt` animado, cores por fase | `Gauge.tsx` animado + número instantâneo 96px |

### 6.2 Erro

| Contexto | Android | PWA |
|---|---|---|
| Sem conexão | `EstadoExecucaoSpeedtest.erro` publicado via StateFlow — tela exibe mensagem de erro; comportamento de retry não documentado em detalhe no código lido | "Sem conexão" — sem retry, aguarda evento `online` |
| Falha no speedtest | Estado `EstadoExecucaoSpeedtest.erro` com `erroMensagem` — tela deve tratar; detalhe de UI não verificado | Tela de erro com "Testar novamente" + "Cancelar" |
| Permissão negada (Wi-Fi) | Estado `erro — semPermissaoLocalizacao` + link para Settings | Tela de capacidade indisponível |
| Upload falhou | Campo `uploadNaoDetectado=true` em `ResultadoSpeedtest` — comportamento de exibição na UI não verificado no código lido | Banner "Resultado parcial" + "—" na célula de upload |

### 6.3 Vazio

| Contexto | Android | PWA |
|---|---|---|
| Histórico vazio | `EmptyHistorico` — ícone `History`, texto "Nenhum teste realizado ainda" + subtexto "Os resultados dos testes de velocidade aparecerão aqui." — sem CTA de navegação | Estado vazio com CTA para iniciar teste (comportamento inferido — não verificado em código) |
| Nenhuma rede Wi-Fi (banda selecionada) | Empty state por banda (ORB-202) + mensagem | Não aplicável |
| Orbit sem mensagens | `OrbitWelcomeState.kt` — tela inicial com prompt | Não aplicável |

### 6.4 Sucesso / Resultado

| Contexto | Android | PWA |
|---|---|---|
| Speedtest concluído | `ResultScreen` com métricas + interpretação | `ResultScreen` com card "Diagnóstico" + badges |
| Diagnóstico saudável | `DiagnosticStatus.ok` → grade "A" em verde (`LkColors.success`) em `ResultadoVelocidadeScreen` | Card "Tudo certo" com ícone verde + "Tudo certo com sua rede" |
| Diagnóstico com problemas | `DiagnosticStatus.attention` → "C" (amarelo) / `DiagnosticStatus.critical` → "D" (vermelho) / `DiagnosticStatus.info` → "B" (accent) — exibido como grade na `ResultadoVelocidadeScreen` | Lista `[problema] → [ação]`, glow vermelho/amarelo no card |

### 6.5 Thinking (IA)

| Plataforma | Como é expresso |
|---|---|
| Android | `OrbitThinkingBubble.kt` — bolha animada com indicador de loading no chat |
| PWA | Sem estado "IA pensando" explícito — diagnóstico é gerado após o teste; card de diagnóstico exibe conteúdo diretamente (não há interface de chat no PWA) |

---

## 7. Ícones e Assets

### 7.1 Compartilhados

- **Logo "linka":** sempre em minúsculo; usado no TopBar/Header de ambas as plataformas
- **OrbitSymbol:** logo/ícone da Orbit — mesmo conceito nas duas plataformas
- **LinkaPulseSymbol:** logo do monitoramento passivo — mesmo conceito

### 7.2 Ícones — PWA

- Biblioteca de ícones: `src/components/icons.tsx` — 25+ ícones SVG inline
- Formato: SVG inline (sem dependência externa de icon font)
- Tamanho padrão de pill/botão de ícone: 36×36px, área de toque 44×44px

### 7.3 Ícones — Android

- Material Icons (biblioteca MD3) — importados via `Icons.Outlined.*`, `Icons.Filled.*`, `Icons.AutoMirrored.*`
- Composables custom em `app/src/main/kotlin/io/linka/app/kotlin/ui/component/`: `OrbitSymbol.kt`, `OrbitTopBar.kt`, `OrbitInputArea.kt`, `OrbitUserMessageBubble.kt`, `OrbitAiMessageBubble.kt`, `OrbitTechnicalResultBubble.kt`, `OrbitThinkingBubble.kt`, `OrbitWelcomeState.kt`, `OrbitActionsCard.kt`, `OrbitInlineQuestion.kt`, `WifiChannelGuide.kt`, `SilentSpeedtestIndicator.kt`, `LinkaIaHeader.kt`, `AiModelFooter.kt`, `LinkaPulseSymbol.kt`, `LinkaPulseIcon.kt`

---

## 8. Animações e Transições

### 8.1 PWA — Tokens de Transição (documentados)

| Token | Valor | Uso |
|---|---|---|
| `--t-fast` | `180ms cubic-bezier(0.32, 0.72, 0, 1)` | Hover, active, fade rápido |
| `--t-med` | `280ms cubic-bezier(0.32, 0.72, 0, 1)` | Transições de tela, entrada de modal |
| `--t-slow` | `480ms cubic-bezier(0.32, 0.72, 0, 1)` | Animações expressivas (orb, gauge fill) |

**Regras PWA:**
- Máximo 300ms para transições utilitárias
- Classe de entrada de tela: `.fade-in` (em `src/index.css`)
- Respeita `prefers-reduced-motion: reduce` — sem transições, sem rotações

**Animações específicas PWA:**
- `lkOrbPulse` — dois pseudo-elementos pulsantes no botão de iniciar (offset 1,2s entre eles)
- `filter: drop-shadow(0 0 10px var(--accent-glow))` no orb durante loading

### 8.2 Android — Transições (parcialmente documentadas)

- `AnimatedContent` e `AnimatedVisibility` do Compose para transições de estado
- `TypewriterText.kt` — animação de digitação caractere por caractere; delay padrão: `charDelayMs = 12ms`; usa `rememberSaveable` para não repetir animação já concluída
- `RotatingMessageText.kt` — usa `AnimatedContent` com `fadeIn() togetherWith fadeOut()` (sem duração explícita — padrão Compose: ~300ms)
- `DiagnosticoScreen.kt` — `AnimatedVisibility` com `fadeIn(tween(300)) + expandVertically(tween(300))` para chips contextuais; `tween(900)` com `RepeatMode.Reverse` para animação infinita de estado "analisando"
- Não há arquivo de tokens de animação globais — cada componente define seus valores localmente

### 8.3 Onboarding PWA — Transição entre Cards

- Slide horizontal: 320ms, curva iOS-Calma
- Dots indicator: ativa cresce de 8×8px para 22×8px + cor muda para `--accent`
- Respeita `prefers-reduced-motion: reduce`

---

## 9. TopBar / AppBar — Comportamento Cross-Platform

### 9.1 PWA — TopBar System (documentado)

**Comportamento scroll-aware:**
- Estado inicial (sem scroll): TopBar transparente — conteúdo passa por baixo
- Com scroll: `<PageHeader>` sai da viewport → glass effect ativa (fundo translúcido + `backdrop-filter: blur(20px)` + borda inferior sutil + título pequeno fade-in)
- Altura: 56px + safe-top (safe area iOS)
- Botão voltar: chevron em pill 36×36px, área de toque 44×44px, `scale(0.94)` no active

**Exceções intencionais:**
- StartScreen: logo "linka" no leftSlot (em vez de back)
- RunningScreen: sem botão back, título "Medindo…" sempre visível
- ResultScreen e ExploreScreen: HamburgerMenu via `position: fixed` quando aberto

### 9.2 Android — AppBar (MD3)

- Sem elevação (`elevation = 0`)
- Altura 56dp
- Fundo `bgPrimary`
- Título centralizado — padrão confirmado: `FibraScreen` e `AjustesScreen` usam `CenterAlignedTopAppBar`; `HistoricoScreen` também. Padrão consistente nas telas verificadas.
- Navegação nativa do Compose (back handler, deep links)

---

## 10. Aplicação de Tokens por Arquivo

| Plataforma | Arquivo de tema |
|---|---|
| Android (Kotlin nativo) | `app/src/main/kotlin/io/linka/app/kotlin/ui/LinkaTheme.kt` |
| Android (Flutter/legado) | `source/app/lib/src/features/redesign/theme/linka_theme.dart` |
| PWA | `src/tokens.css` (confirmado) |

**Regras de consumo:**
- Android: sempre via `MaterialTheme.colorScheme.*` ou tokens `LkColors.*`, `LkSpacing.*`
- PWA: sempre via CSS Custom Properties (`var(--token)`) — nunca hex hardcoded em componentes

---

## 11. Checklist de Paridade Visual

Ao criar ou modificar um componente que existe nas duas plataformas, verificar:

- [ ] Cores via tokens (não hex hardcoded)
- [ ] Zero sombras
- [ ] Accent `#6C2BFF` apenas onde permitido
- [ ] Cores semânticas de velocidade corretas (DL azul, UL verde, latência roxo)
- [ ] Estado de loading implementado
- [ ] Estado de erro implementado
- [ ] Estado vazio implementado (quando aplicável)
- [ ] Hit target mínimo (44px / 56dp) em elementos interativos
- [ ] Textos em `sp` (Android) / `px` responsivo (PWA)
- [ ] Orbit mantém paleta escura independente do tema do sistema

---

## 12. Notas de Manutenção

- Ao adicionar nova cor a uma plataforma, atualizar `MATERIAL_DESIGN_3.md` com ambas.
- Orbit deve permanecer idêntica nas duas plataformas — é a identidade da IA.
- Phase colors (speedtest) devem manter saturação semelhante mesmo em temas diferentes.
- Seções com `[a confirmar]` indicam comportamento não verificado em código Android — verificar em `LinkaTheme.kt` antes de usar como referência.
- Referências primárias: `MATERIAL_DESIGN_3.md`, `linkaSpeedtestPwa/docs/GuiaBranding.md`, `linkaAndroidKotlin/docs_ai/design-system/`

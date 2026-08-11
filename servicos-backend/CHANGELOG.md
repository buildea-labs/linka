# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.1] - 2026-05-20

### Added
- **SpeedBarsChart component:** Novo gráfico de velocidade com filtro por tipo conexão (Todos/Wi-Fi/Móvel), barras animadas, estados de loading/vazio/com-dados
- **LinkaPulseOrchestrator improvements:** Timeout 95s para análise IA com fallback robusto; captura operadora móvel em testes celulares

### Fixed
- AjustesScreen: guard para estado "Minha Conexão" vazio ("Toque para configurar") quando sem dados
- SpeedBarsChart: shimmer renderiza com count dinâmico (não fixo em 10 barras)
- PulseResultCard: badge "local" renderizado quando diagnóstico usa fallback
- Card "Diagnostico" conectado ao ChatScreen via FeatureFlag; resultado do speedtest abre independente da tab de origem; titulo dinamico na SinalScreen (Wi-Fi / Sinal Movel / Sinal); PingScreen conectada ao AppShell
- Tab "Mais" renomeada para "Ajustes" + icone correto; CTA HomeScreen alterado para "Medir velocidade"; estado Idle do ChatScreen com OrbitThinkingBubble; botao "Ver resultado" exibido pos-speedtest
- Onboarding redesenhado com mockups visuais (3 slides); botao "Medir agora" no topo do HistoricoScreen; melhorias visuais em CTA Ajustes, badge Canal, frame Concluido, grau "?", turnos Chat, badge Velocidade

### Changed
- BackHandlers (7 instancias) unificados em SnapshotStateList<Overlay> centralizado no AppShell (I3)
- AjustesScreen refatorada de 39 para 17 parametros via data classes AjustesUiState (I8)
- SpeedBarsChart component refatorado com estado loading dinâmico (não fixtures)
- Font size em SpeedBarsChart → typography.labelSmall (acesso design system)

### Fixed (Accessibility)
- contentDescriptions e semantics adicionados em 5 componentes criticos (A1-A5)

## [0.8.5] - 2026-05-19

### Features
- **WiFi Signal Screen:** Enhanced WiFi channel display with congestion indicator
  - Added congestion chip ("Free/Moderate/Congested") to current channel card
  - Highlighted recommended channel with accent color background
  - Integrated channel guide into modal for better space usage

## [0.8.4] - Earlier

(See git history for previous releases)

# Changelog

All notable changes to Linka WebApp are documented here.

## [1.7.0] — 2026-05-26

### Added
- **Análise de Conexão** (`AiScreen`): tela completa com conteúdo real, substituindo o dead-end "Módulo em preparação"
- `connectionAnalysis.ts`: utilitário de métricas locais (stddev, tendência, horários, índice de estabilidade)
- Grid de 6 métricas: download médio, latência, jitter, variação, perda, tendência
- Barra de estabilidade 0–100 com classificação visual
- Análise de melhor/pior horário do dia (quando dados suficientes)
- Cards de insight gerados por `buildHistoryInsights` (regras existentes)
- Estado vazio quando < 5 testes com contador e CTA para testar
- Renomeado de "Diagnóstico IA" para "Análise de Conexão"
- Disclaimer de privacidade: "Os dados nunca saem do seu dispositivo"

### Closes
- #54 — Diagnóstico Inteligente (Orbit / AI)

## [1.6.0] — 2026-05-26

### Added
- **Monitoramento foreground** (`useMonitor`): setInterval + Page Visibility API — pausa quando tab oculta
- **Alertas in-app** (`MonitorAlert`): banner animado para status `warn` (>300ms), `error` (>600ms) e `offline`
- Médias móveis de 3 amostras para evitar falsos positivos nos alertas
- `SettingsScreen`: opção "Notificações em segundo plano" desabilitada com explicação clara
- Nota explicativa: "Requer app nativo para monitoramento em background"

### Changed
- Monitoramento ativado via `settings.notificationsEnabled`; intervalo via `settings.checkInterval`

### Closes
- #52 — Monitoramento Contínuo e Alertas

## [1.5.0] — 2026-05-25

### Added
- **Perfil editável** (`SettingsScreen`): modal para editar nome e provedor, persiste em localStorage via `useSettings`
- **Intervalos de monitoramento**: configuração de intervalo (1/5/10/30 min) via ciclo no tap, lida de `settings.checkInterval`
- **Toggle de notificações in-app**: `settings.notificationsEnabled` controlado pelo usuário
- Novos campos na interface `Settings`: `checkInterval` e `notificationsEnabled`

### Fixed
- `SettingsScreen`: removido `void settings` e `void onUpdateSettings` — props agora usadas de verdade
- Dados "Lucas Ferreira" e "Vivo Fibra 500" não são mais hardcoded

### Closes
- #51 — Sistema de Perfil (Meu Perfil e Provedor)

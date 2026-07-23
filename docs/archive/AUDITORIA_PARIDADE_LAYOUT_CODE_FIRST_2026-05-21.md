# Auditoria de Paridade Layout Android ↔ PWA (Code-First)

Data: 2026-05-21  
Escopo: `linkaSpeedtestPwa/` (correções futuras apenas no PWA)  
Fonte primária: código Android Compose + código PWA React/CSS

## 1) Método executado

1. Android base: `AppShell.kt` (tabs e composição), `ui/screen/*`, `ui/component/*`, `LinkaTheme.kt`.
2. PWA base: `App.tsx` (screen state e tabs), `src/screens/*`, `src/components/*`, `src/tokens.css`.
3. Docs usadas só para contexto secundário (não para decidir paridade).

## 2) Evidências de arquitetura (código)

- Android tabs reais: Início, Velocidade, Sinal, Histórico, Ajustes em `AppBottomNavBar`.
  Evidência: `linkaAndroidKotlin/linka-android-kotlin/app/src/main/kotlin/io/linka/app/kotlin/ui/screen/AppShell.kt:617`.
- Android composição por tab em `when (selectedTab)` com Home/SpeedTest/Sinal/Histórico/Ajustes.
  Evidência: `.../AppShell.kt:257`.
- PWA tabs reais: Início, Velocidade, Diagnóstico, Dispositivos, Ajustes em `BottomNavBar`.
  Evidência: `linkaSpeedtestPwa/src/components/BottomNavBar.tsx:3`.
- PWA screen state canônico (`home|velocidade|running|result|historico|orbit|ajustes|sinal|dispositivos|fibra`) e mapeamento de aba (`TAB_MAP`).
  Evidência: `linkaSpeedtestPwa/src/App.tsx:51` e `:65`.
- PWA esconde navbar durante teste (`running`, `result`).
  Evidência: `linkaSpeedtestPwa/src/App.tsx:77`.
- Tokens de spacing/radius compatíveis em grande parte (4/8/12/16/24/32 e raio card 16).
  Evidência Android: `.../ui/LinkaTheme.kt:81`. Evidência PWA: `linkaSpeedtestPwa/src/tokens.css:9`.
- Divergência tipográfica base: Android usa escala M3 em `MaterialTheme.typography`; PWA usa tokens com fallback `system-ui` no font stack.
  Evidência Android: `.../ui/LinkaTheme.kt:154`. Evidência PWA: `linkaSpeedtestPwa/src/tokens.css:38`.

## 3) Matriz completa (tela a tela)

| screen_android | screen_pwa | status | gap | categoria | severidade | acao | justificativa_tecnica | evidencia_codigo |
|---|---|---|---|---|---|---|---|---|
| HomeScreen.kt | HomeScreen.tsx | MAP_1_1 | Paridade parcial de hero/cards; navegação de atalhos diverge para tabs diferentes | BUG_PARIDADE | P0 | ajustar agora | Jornada principal; impacto alto na percepção de produto | `AppShell.kt:257`, `HomeScreen.kt`, `App.tsx:470`, `HomeScreen.tsx` |
| SpeedTestScreen.kt | SpeedTestScreen.tsx | MAP_1_1 | Estrutura geral compatível, mas densidade/ordem de blocos e affordances não está uniforme | BUG_PARIDADE | P0 | ajustar agora | Tela central de valor; precisa convergir layout first | `AppShell.kt:292`, `SpeedTestScreen.kt`, `App.tsx:366`, `SpeedTestScreen.tsx` |
| VelocidadeScreen.kt (execução) | RunningScreen.tsx | MAP_1_1 | Estado de execução com tratamento visual diferente (header/context line/progress semantics) | BUG_PARIDADE | P0 | ajustar agora | Impacta continuidade de fluxo Start→Running | `VelocidadeScreen.kt`, `RunningScreen.tsx`, `App.tsx:380` |
| ResultadoVelocidadeScreen.kt | ResultScreen.tsx | MAP_1_1 | Estrutura de resultado rica em ambos, mas hierarquia visual e agrupamento dos cards difere | BUG_PARIDADE | P0 | ajustar agora | Fase de maior retenção/compartilhamento; precisa padronização | `ResultadoVelocidadeScreen.kt`, `ResultScreen.tsx`, `App.tsx:398` |
| HistoricoScreen.kt | HistoryScreen.tsx | MAP_1_1 | Similaridade funcional; diferenças de header/ação primária e blocos de insight | BUG_PARIDADE | P0 | ajustar agora | Fecha jornada crítica definida no plano | `AppShell.kt:337`, `HistoryScreen.tsx`, `App.tsx:460` |
| OrbitScreen.kt / ChatScreen.kt | PulseScreen.tsx | MAP_1_N | Convergência visual mínima aplicada (header, bolhas, densidade e tipografia), mantendo diferenças estruturais legítimas do domínio conversacional | DECISAO_PRODUTO | P1 | manter e monitorar | Base técnica diferente, com alinhamento visual suficiente para a wave atual | `OrbitScreen.kt`, `ChatScreen.kt`, `PulseScreen.tsx`, `PulseScreen.css`, `App.tsx:447` |
| AjustesScreen.kt | ExploreScreen.tsx | MAP_1_1 | IA de layout de configurações diverge em agrupamento e ritmo de leitura | BUG_PARIDADE | P1 | onda seguinte | Menor impacto que jornada speedtest, mas alto uso recorrente | `AppShell.kt:349`, `ExploreScreen.tsx`, `App.tsx:428` |
| SinalScreen.kt | LocalWifiScreen.tsx | MAP_1_1 | Divergência esperada em dados disponíveis no browser e diferenças de cards técnicos | LIMITACAO_WEB | P1 | manter com justificativa | Browser não expõe todos os sinais locais; paridade 100% é impossível | `SinalScreen.kt`, `features/local-wifi/LocalWifiScreen.tsx`, `App.tsx:441` |
| DispositivosScreen.kt | LocalNetworkScreen.tsx | MAP_1_1 | Estrutura próxima, mas taxonomia visual de lista/detalhe e controles divergente | BUG_PARIDADE | P1 | onda seguinte | Dá para convergir sem dependência de API nativa adicional | `DispositivosScreen.kt`, `features/local-network/LocalNetworkScreen.tsx`, `App.tsx:443` |
| (domínio fibra no Android distribuído em fluxos de ajustes/modem) | FibraScreen.tsx | MAP_1_N | Mesmo domínio, porém com limitações estruturais no browser para telemetria GPON/ONU | LIMITACAO_WEB | P1 | manter com justificativa | Tela especializada com limitações técnicas reais na web | `FibraScreen.tsx`, `App.tsx:445`, `AjustesScreen.kt` |
| OnboardingScreen.kt | OnboardingScreen.tsx | MAP_1_1 | Convergência visual aplicada: narrativa equivalente em 3 slides, CTA e progressão padronizados, densidade de layout refinada | DEBITO_UI | P2 | manter e monitorar | Fluxo inicial alinhado ao baseline Android sem alterar comportamento funcional | `OnboardingScreen.kt`, `OnboardingScreen.tsx`, `OnboardingScreen.css`, `App.tsx:493` |
| DiagnosticoScreen.kt (hub legado) | DiagnosticScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P1 | aposentada | Código fora do fluxo canônico foi eliminado | `git rm src/screens/DiagnosticScreen.*` |
| — | StartScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P1 | aposentada | Duplicidade de entrada removida | `git rm src/screens/StartScreen.*` |
| — | RecommendScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P2 | aposentada | Fluxo experimental sem rota canônica removido | `git rm src/screens/RecommendScreen.*` |
| — | RoomTestScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P2 | aposentada | Fluxo não canônico removido | `git rm src/screens/RoomTestScreen.*` |
| — | ComparisonScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P2 | aposentada | Fluxo não canônico removido | `git rm src/screens/ComparisonScreen.*` |
| — | BeforeAfterScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P2 | aposentada | Fluxo não canônico removido | `git rm src/screens/BeforeAfterScreen.*` |
| — | DetailsScreen.tsx | MAP_N_A | Tela órfã removida na T-002 | DEBITO_UI | P2 | aposentada | Fluxo não canônico removido | `git rm src/screens/DetailsScreen.*` |
| (Tab model Android: inclui Histórico e Sinal) | (Tab model PWA: inclui Diagnóstico e Dispositivos) | MAP_1_N | Divergência estrutural do BottomNav | DECISAO_PRODUTO | P0 | ajustar agora | Se não padronizar baseline de navegação, layout drift continua | `AppShell.kt:617`, `BottomNavBar.tsx:3` |

## 4) Componentes-base que concentram divergência

1. **Navegação base (BottomNav)**
- Android e PWA têm composição de abas diferente; isso puxa divergência em header, profundidade e retorno.

2. **Sistema de header/topbar**
- PWA usa `TopBar + PageHeader + useScrollHeader`; Android usa `Scaffold`/top app bars por tela.
- Precisa padronizar regras visuais (altura, estados, título colapsado, ações).

3. **Tokens tipográficos**
- Escala Android M3 está explícita; PWA tem stack com fallback `system-ui` em tokens.
- Para paridade real, tipografia precisa regra única sem fallback conflitante.

4. **Governança de telas órfãs no PWA**
- Várias telas `src/screens/*` não passam pelo state machine principal em `App.tsx`.
- Isso cria dívida visual permanente e dificulta auditoria contínua.

## 5) Backlog executável por ondas

### Wave 1 (P0) — Jornada crítica + base estrutural

1. Padronizar modelo de navegação base entre Android e PWA (definir baseline final das abas e política de sub-telas).
2. Normalizar layout de `Home`, `SpeedTest`, `Running`, `Result`, `History` para equivalência visual mínima.
3. Fechar regra oficial de header/topbar (comportamento em scroll, título, ações, safe area).
4. Sanear telas órfãs de alto risco (`StartScreen` e `DiagnosticScreen`): concluído na T-002 (aposentadas).

### Wave 2 (P1) — Domínios secundários relevantes

1. Convergir `Ajustes` (`ExploreScreen`) com `AjustesScreen` Android.
2. Convergir `Sinal` e `Dispositivos` com exceções explícitas por limitação web.
3. Convergir `Fibra` em hierarquia e semântica visual.
4. Convergir `Pulse/Orbit` em pattern visual de diagnóstico conversacional.

### Wave 3 (P2) — Refino e higiene final

1. Manter política de não permitir novas telas fora do fluxo canônico (T-002 concluída para o backlog legado).
2. Polimento de tipografia, spacing e estados sutis.
3. Checklist contínuo de regressão visual por tela antes de release.

## 6) Catálogo oficial de exceções permitidas no PWA

1. **Coleta de sinal/local Wi-Fi avançado**
- Pode divergir do Android por limitação de APIs web (sem simular disponibilidade nativa).

2. **Medições de rede dependentes de plugin nativo**
- Quando capacidade não existir no browser puro, UI deve indicar indisponibilidade real.

3. **Execução em background e comportamentos persistentes**
- Diferenças por política de navegador/PWA instalado são aceitáveis, desde que comunicadas no layout.

4. **Sinal Wi-Fi/Celular no navegador (`LocalWifiScreen`)**
- É permitido divergir do Android quando APIs de browser não expõem `RSSI`, `RSRP`, `RSRQ`, `SINR`, canal e torre.
- Obrigatório sinalizar no layout que é `LIMITACAO_WEB` (sem prometer diagnóstico nativo inexistente).

5. **Fibra/Modem no navegador (`FibraScreen`)**
- Navegadores bloqueiam leitura direta de telemetria GPON/ONU (CORS, sessão local do modem e limitações de rede local em contexto web).
- É permitido exibir apenas dados estimados e acesso manual ao painel do modem.
- Obrigatório sinalizar no layout que é `LIMITACAO_WEB`.

## 7) Próximo artefato operacional

Gerar `PARIDADE_LAYOUT_EXECUTION_BOARD.md` a partir desta matriz, com tasks prontas por wave (P0/P1/P2), cada uma com DoD visual e evidência de validação.

## 8) Status de execução após passes iniciais (2026-05-21)

1. P0 parcialmente executado:
- `HomeScreen`, `SpeedTestScreen`, `RunningScreen`, `ResultScreen`, `HistoryScreen` receberam pass inicial de convergência visual.
- Baseline de tabs e governança de telas órfãs já aplicadas.

2. Pendência para fechamento real da P0:
- Sem pendência técnica de build/test após revalidação em 2026-05-21.

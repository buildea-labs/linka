# PARIDADE_LAYOUT_EXECUTION_BOARD (Code-First)

Data: 2026-05-21
Fonte: `AUDITORIA_PARIDADE_LAYOUT_CODE_FIRST_2026-05-21.md`

## Status de execução

- `T-001` concluída em 2026-05-21.
- Baseline de tabs PWA alinhada ao modelo Android: `Início | Velocidade | Sinal | Histórico | Ajustes`.
- Exceção transitória aplicada para não perder capacidade: acesso a `Dispositivos` via CTA dentro da tela `Sinal` até a tarefa de governança (`T-002`) fechar o destino definitivo.
- `T-002` concluída em 2026-05-21.
- Telas órfãs aposentadas do código: `Start`, `Diagnostic`, `Recommend`, `RoomTest`, `Comparison`, `BeforeAfter`, `Details`.
- `T-003` concluída em 2026-05-21.
- HomeScreen ajustada para convergência visual inicial: título `Início`, CTA principal `Medir velocidade`, densidade de spacing reduzida, avatar simplificado para token `--accent`, copy/ícone do atalho de diagnóstico alinhados.
- `T-004` em progresso em 2026-05-21.
- `SpeedTestScreen` recebeu pass inicial de paridade visual (P0): título `Central de testes`, círculo principal redimensionado para escala Android, densidade de spacing revisada, tipografia de descrição/cartões refinada e ícone da linha de ferramentas alinhado ao contexto de velocidade.
- `RunningScreen` recebeu pass de convergência visual (P0): TopBar padronizada para `Central de testes`, densidade de layout ajustada (safe-top, spacing, frase e footer), linha contextual do servidor refinada e ação `Cancelar` preservada como CTA textual principal.
- `ResultScreen` recebeu pass inicial de convergência visual (P0): título alinhado ao Android (`Resultado do teste`) em TopBar + Large Title, e densidade do CTA principal de pós-teste ajustada (altura/tipografia) para consistência com o restante da jornada crítica.
- `HistoryScreen` recebeu pass inicial de convergência visual (P0): adoção do padrão Large Title (`Histórico`) com sentinel canônico de scroll header, ajuste de densidade dos cards/lista e refinamento tipográfico do detail sheet para aproximar do ritmo visual do Compose.
- `ExploreScreen` recebeu pass inicial de convergência visual (P1): hierarquia de seções MD3 reforçada (kicker/título/subtítulo), densidade das rows ajustada e tipografia dos sheets normalizada para maior paridade com `AjustesScreen.kt`.
- `PulseScreen` recebeu pass inicial de convergência visual (P1): header padronizado para `Diagnóstico IA`, densidade de cards/bolhas refinada, tipografia de conteúdo e chips/botões normalizada para ritmo visual consistente com o baseline Android.
- `OnboardingScreen` recebeu pass de convergência visual (P2): narrativa dos 3 slides alinhada ao Android (`internet explicada`, `dados locais`, `resultado explicado`), ritmo visual refinado (título/sub/bullets/footer) e CTA padronizado para `Próximo/Começar`.

## Checklist rastreável por tela (fonte, cores, botões, espaçamento, ícones)

Legenda de status: `OK` | `GAP` | `N/A`  
Regra: toda linha com pelo menos um `GAP` vira item obrigatório da wave correspondente.

| tela | wave | fonte | cores | botoes | espacamento | icones | acao | evidencia |
|---|---|---|---|---|---|---|---|---|
| HomeScreen.tsx | P0 | OK | OK | OK | OK | OK | manter e monitorar | `HomeScreen.tsx`, `HomeScreen.kt`, `AppShell.kt:257`, `App.tsx:470` |
| SpeedTestScreen.tsx | P0 | OK | OK | OK | OK | OK | manter e monitorar | `SpeedTestScreen.tsx`, `SpeedTestScreen.kt`, `AppShell.kt:292`, `App.tsx:366` |
| RunningScreen.tsx | P0 | OK | OK | OK | OK | OK | manter e monitorar | `RunningScreen.tsx`, `VelocidadeScreen.kt`, `App.tsx:380` |
| ResultScreen.tsx | P0 | OK | OK | OK | OK | OK | manter e monitorar | `ResultScreen.tsx`, `ResultadoVelocidadeScreen.kt`, `App.tsx:398` |
| HistoryScreen.tsx | P0 | OK | OK | OK | OK | OK | manter e monitorar | `HistoryScreen.tsx`, `HistoricoScreen.kt`, `App.tsx:460` |
| ExploreScreen.tsx | P1 | OK | OK | OK | OK | OK | manter e monitorar | `ExploreScreen.tsx`, `AjustesScreen.kt`, `App.tsx:428` |
| LocalWifiScreen.tsx | P1 | OK | OK | OK | OK | OK | manter com justificativa (limitação web aplicada e explícita na UI) | `LocalWifiScreen.tsx`, `SinalScreen.kt`, `App.tsx:441` |
| LocalNetworkScreen.tsx | P1 | OK | OK | OK | OK | OK | manter e monitorar | `LocalNetworkScreen.tsx`, `DispositivosScreen.kt`, `App.tsx:443` |
| FibraScreen.tsx | P1 | OK | OK | OK | OK | OK | manter com justificativa (limitação web explícita na UI) | `FibraScreen.tsx`, `App.tsx:445` |
| PulseScreen.tsx | P1 | OK | OK | OK | OK | OK | manter e monitorar | `PulseScreen.tsx`, `PulseScreen.css`, `OrbitScreen.kt`, `ChatScreen.kt`, `App.tsx:447` |
| OnboardingScreen.tsx | P2 | OK | OK | OK | OK | OK | manter e monitorar | `OnboardingScreen.tsx`, `OnboardingScreen.css`, `OnboardingScreen.kt`, `App.tsx:493` |

Observação: a governança de telas órfãs já foi resolvida na T-002 com aposentadoria das telas fora do fluxo canônico.

## Wave 1 (P0)

1. Definir baseline único de BottomNav (Android vs PWA) e aplicar no PWA.
- DoD: tabs finais aprovadas e consistentes em todas as telas canônicas.

2. Normalizar HomeScreen PWA para paridade estrutural com Home Android.
- DoD: hero, blocos principais e CTAs com hierarquia equivalente.

3. Normalizar SpeedTestScreen/RunningScreen/ResultScreen PWA para jornada crítica.
- DoD: sequência visual start→running→result alinhada em estrutura, spacing e tipografia.

4. Normalizar HistoryScreen PWA.
- DoD: header, ação principal e blocos de histórico/insight com linguagem equivalente.

5. Validar fluxo sem telas órfãs.
- DoD: nenhum caminho do app depende de telas fora da navegação canônica.

## Consolidação P0 (snapshot 2026-05-21)

1. Concluído:
- Baseline de navegação canônica aplicada.
- Telas órfãs aposentadas do fluxo.
- Pass inicial de paridade visual entregue em `Home`, `SpeedTest`, `Running`, `Result` e `History`.

2. Aberto (monitoramento pós-fechamento):
- Validar regressão visual final por captura de tela comparativa Android↔PWA.

3. Gate técnico P0:
- `npm run build` OK em 2026-05-21 (após limpeza de `dist/android` bloqueado).
- `npm test` OK em 2026-05-21 (36 arquivos, 596 testes).
- `npm run lint` OK em 2026-05-21 após hardening e ajuste de escopo do ESLint (incluindo exclusão de artefatos gerados em `android/app/src/main/assets/public/assets`).

## Wave 2 (P1)

1. Normalizar Explore/Ajustes.
- DoD: agrupamento de seções e ritmo de leitura equivalente ao Android.

2. Normalizar Sinal (LocalWifi) com exceções técnicas explícitas.
- DoD: divergências por API web documentadas e UX sem promessas falsas.

3. Normalizar Dispositivos (LocalNetwork).
- DoD: taxonomia visual de lista/detalhe e ações consistente.

4. Normalizar Fibra.
- DoD: prioridade de seções e indicadores alinhados ao modelo Android.

5. Convergência visual mínima de Pulse/Orbit.
- DoD: padrão de bolhas, header e estados intermediários padronizado.

## Wave 3 (P2)

1. Manter higiene de fluxo canônico.
- DoD: novas telas só entram com rota canônica explícita e validação de paridade.

2. Refino final de tipografia/tokens/estados sutis.
- DoD: ausência de drift visual entre telas do mesmo domínio.

3. Gate de regressão visual por release.
- DoD: checklist com evidências para Home/SpeedTest/Running/Result/History + telas da wave em curso.

## Status final da auditoria (snapshot 2026-05-21)

1. Paridade de layout por tela: concluída nas waves P0/P1/P2 (com exceções `LIMITACAO_WEB` explícitas em `LocalWifi` e `Fibra`).
2. Gate técnico: `build`, `test` e `lint` OK.
3. Evidência visual comparativa Android↔PWA: pendente de captura manual para fechamento de release.
4. Artefato de evidência criado: `REGRESSAO_VISUAL_EVIDENCIAS_ANDROID_PWA_2026-05-21.md` (matriz tela a tela pronta para anexos e decisão final).

## Regras de execução

1. Nenhuma alteração no Android nesta iniciativa.
2. Toda divergência marcada como `LIMITACAO_WEB` exige justificativa técnica no PR.
3. Não criar telas novas antes de estabilizar fluxo canônico.
4. Sem deploy/commit/push sem confirmação explícita do usuário.

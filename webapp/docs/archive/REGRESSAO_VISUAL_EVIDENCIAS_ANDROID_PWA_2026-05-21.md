# REGRESSAO VISUAL — EVIDENCIAS ANDROID ↔ PWA (2026-05-21)

Status geral: PENDENTE DE ANEXOS VISUAIS

Objetivo: consolidar evidências lado a lado para fechar o gate final de paridade visual.

## Estrutura de anexos

- Android: `docs/evidencias/2026-05-21/android/`
- PWA: `docs/evidencias/2026-05-21/pwa/`
- Convenção: `<ordem>_<tela>_<plataforma>.png`
  - Ex.: `01_home_android.png`, `01_home_pwa.png`

## Matriz de evidências

| tela | pwa_path | android_path | anexo_pwa | anexo_android | status | observacao |
|---|---|---|---|---|---|---|
| Home | `src/screens/HomeScreen.tsx` | `ui/screen/HomeScreen.kt` | `docs/evidencias/2026-05-21/pwa/01_home_pwa.png` | `docs/evidencias/2026-05-21/android/01_home_android.png` | PENDENTE | |
| SpeedTest | `src/screens/SpeedTestScreen.tsx` | `ui/screen/SpeedTestScreen.kt` | `docs/evidencias/2026-05-21/pwa/02_speedtest_pwa.png` | `docs/evidencias/2026-05-21/android/02_speedtest_android.png` | PENDENTE | |
| Running | `src/screens/RunningScreen.tsx` | `ui/screen/VelocidadeScreen.kt` | `docs/evidencias/2026-05-21/pwa/03_running_pwa.png` | `docs/evidencias/2026-05-21/android/03_running_android.png` | PENDENTE | |
| Result | `src/screens/ResultScreen.tsx` | `ui/screen/ResultadoVelocidadeScreen.kt` | `docs/evidencias/2026-05-21/pwa/04_result_pwa.png` | `docs/evidencias/2026-05-21/android/04_result_android.png` | PENDENTE | |
| History | `src/screens/HistoryScreen.tsx` | `ui/screen/HistoricoScreen.kt` | `docs/evidencias/2026-05-21/pwa/05_history_pwa.png` | `docs/evidencias/2026-05-21/android/05_history_android.png` | PENDENTE | |
| Explore/Ajustes | `src/screens/ExploreScreen.tsx` | `ui/screen/AjustesScreen.kt` | `docs/evidencias/2026-05-21/pwa/06_explore_pwa.png` | `docs/evidencias/2026-05-21/android/06_ajustes_android.png` | PENDENTE | |
| LocalWifi/Sinal | `src/features/local-wifi/LocalWifiScreen.tsx` | `ui/screen/SinalScreen.kt` | `docs/evidencias/2026-05-21/pwa/07_localwifi_pwa.png` | `docs/evidencias/2026-05-21/android/07_sinal_android.png` | PENDENTE | `LIMITACAO_WEB` permitida |
| LocalNetwork/Dispositivos | `src/features/local-network/LocalNetworkScreen.tsx` | `ui/screen/DispositivosScreen.kt` | `docs/evidencias/2026-05-21/pwa/08_localnetwork_pwa.png` | `docs/evidencias/2026-05-21/android/08_dispositivos_android.png` | PENDENTE | |
| Fibra | `src/screens/FibraScreen.tsx` | `dominio fibra distribuido no Android` | `docs/evidencias/2026-05-21/pwa/09_fibra_pwa.png` | `docs/evidencias/2026-05-21/android/09_fibra_android.png` | PENDENTE | `LIMITACAO_WEB` permitida |
| Pulse/Orbit | `src/screens/PulseScreen.tsx` | `ui/screen/OrbitScreen.kt` / `ui/screen/ChatScreen.kt` | `docs/evidencias/2026-05-21/pwa/10_pulse_pwa.png` | `docs/evidencias/2026-05-21/android/10_orbit_android.png` | PENDENTE | |
| Onboarding | `src/screens/OnboardingScreen.tsx` | `ui/screen/OnboardingScreen.kt` | `docs/evidencias/2026-05-21/pwa/11_onboarding_pwa.png` | `docs/evidencias/2026-05-21/android/11_onboarding_android.png` | PENDENTE | |

## Critérios de aprovação por tela

1. Fonte, cores, botões, espaçamento e ícones sem drift perceptível.
2. Header/topbar e hierarquia de blocos consistentes com o baseline Android.
3. Estados críticos coerentes (loading, erro, vazio, sucesso) nas telas aplicáveis.
4. Divergências apenas quando classificadas como `LIMITACAO_WEB` com sinalização explícita.

## Evidências obrigatórias por item

1. Captura Android (tela equivalente).
2. Captura PWA (mesmo estado visual).
3. Nota curta de comparação (`OK` ou gap residual + justificativa).

## Decisão final de release

`APROVADO` somente quando todos os itens acima estiverem com status `OK` ou `OK com LIMITACAO_WEB`.

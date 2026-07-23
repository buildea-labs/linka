# PARIDADE RELEASE CHECKLIST (PWA) — 2026-05-21

## 1) Gate técnico

| item | status | evidencia |
|---|---|---|
| `npm run build` | OK | build Vite concluído, SW gerado |
| `npm test` | OK | 36 arquivos, 596 testes passando |
| `npm run lint` | OK | lint limpo após hardening + ajuste de escopo/ignores |

## 2) Paridade por ondas

| onda | status | telas |
|---|---|---|
| Wave 1 (P0) | OK | `Home`, `SpeedTest`, `Running`, `Result`, `History` |
| Wave 2 (P1) | OK | `Explore`, `LocalWifi`, `LocalNetwork`, `Fibra`, `Pulse` |
| Wave 3 (P2) | OK | `Onboarding` |

## 3) Exceções permitidas (PWA)

1. `LIMITACAO_WEB` em `LocalWifiScreen` (APIs nativas indisponíveis no browser).
2. `LIMITACAO_WEB` em `FibraScreen` (telemetria GPON/ONU indisponível no browser puro).

## 4) Regressão visual Android↔PWA (manual)

Status: PENDENTE DE EVIDÊNCIA MANUAL (capturas lado a lado).

Checklist de captura:
1. `Home`
2. `SpeedTest`
3. `Running`
4. `Result`
5. `History`
6. `Explore`
7. `LocalWifi`
8. `LocalNetwork`
9. `Fibra`
10. `Pulse`
11. `Onboarding`

## 5) Decisão de release

Release de paridade visual: **condicional**.

Condição mínima para liberar:
1. Anexar evidência visual manual da lista acima.

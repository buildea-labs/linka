# Documentacao Tecnica do Sistema

## Escopo

O Linka WebApp e um PWA React/TypeScript empacotado por Vite e publicado em Cloudflare Pages.

Este repositorio nao contem shell nativo, plugins nativos, projeto Android ou empacotamento mobile.

## Build

- Entrada HTML: `index.html`.
- Entrada React: `src/main.tsx`.
- Configuracao Vite/PWA: `vite.config.ts`.
- Saida de producao: `dist/`.
- Manifest e service worker: gerados por `vite-plugin-pwa`.

## Dominios Principais

- `src/utils/speedTestOrchestrator.ts`: orquestracao do teste.
- `src/core`: classificacao, perfis e interpretacao.
- `src/features/diagnosis`: diagnostico e regras.
- `src/features/local-wifi`: estado indisponivel/fallback para diagnostico Wi-Fi no navegador.
- `src/features/local-network`: estado indisponivel/fallback para descoberta de rede local no navegador.
- `src/screens`: composicao de telas.

## Diagnostico IA (canônico)

- Endpoint remoto canônico: `POST https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev/api/ai/diagnostico-conexao`.
- Fluxos que usam o endpoint: diagnostico principal (`useDiagnosis`) e diagnostico conversacional (`Pulse`).
- Disponibilidade: `HEAD` no mesmo endpoint (considerar `200` e `405` como servidor ativo, alinhado ao Android).
- Fallback: em timeout/erro HTTP/parse, o WebApp retorna analise local e identifica explicitamente:
  `Motor de análise: Diagnóstico local do Linka`.

## Capacidades Web

O navegador nao expoe RSSI, canal Wi-Fi, ARP, MAC, varredura LAN, GPON/ONU ou medicao UDP real de packet loss.

Quando uma capacidade nao existe no WebApp:

- o codigo retorna `available: false`;
- a UI explica a limitacao;
- o fluxo principal de speedtest continua funcionando;
- nao ha dependencia de bridge nativa.

## Testes

```bash
npm run lint
npm test
npm run build
```

Scripts auxiliares de QA ficam em `scripts/qa`.

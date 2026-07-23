# LINKA WebApp

PWA de diagnóstico de conexão para navegador, criada para medir velocidade, interpretar a qualidade da rede e apresentar resultados de forma clara ao usuário final.

> Consolidado em 2026-07-23 dentro do repo `linka-speedtest`, como subpasta standalone (build e
> testes próprios — não compartilha nada com a raiz do repo). Era o repo `linka-webapp`.
>
> CI conectado em `../.github/workflows/webapp-ci.yml` (lint/test/build, dispara só com mudanças
> em `webapp/**`). Deploy automático (Cloudflare Pages) ainda não conectado — o workflow original
> apontava por engano pro projeto Pages do speedtest; precisa do nome real do projeto do webapp
> antes de religar. Ver `docs/release/CI-CD.md`.

## Escopo

Este repositório contém apenas a aplicação web/PWA. Código Android, APK, Gradle, keystore, Capacitor e integrações nativas pertencem a outros projetos.

## Stack

- React
- TypeScript
- Vite
- Vitest
- Recharts
- jsPDF e html2canvas
- vite-plugin-pwa
- Cloudflare Pages

## Estrutura

```text
src/                 Código da aplicação
public/              Assets públicos da PWA
scripts/             Automações locais
docs/                Documentação viva e histórico
.github/workflows/   CI e release
.claude/commands/    Comandos auxiliares para agentes
```

## Desenvolvimento

```bash
npm install
npm run dev
```

Para acessar de outro dispositivo na mesma rede:

```bash
npm run dev -- --host 0.0.0.0 --port 5173
```

## Scripts

```bash
npm run dev
npm run build
npm run preview
npm run lint
npm test
```

Automações operacionais devem ficar em `scripts/`. Consulte `scripts/README.md` antes de criar novos scripts.

## Validação obrigatória

Antes de PR, release ou deploy:

```bash
npm run lint
npm test
npm run build
```

Fluxos mínimos de regressão:

- início do teste;
- medição em andamento;
- resultado e diagnóstico;
- histórico;
- instalação e atualização da PWA;
- ausência de erros quando recursos nativos não estiverem disponíveis.

## Deploy

Destino principal: Cloudflare Pages.

```text
Build command: npm run build
Build output directory: dist
```

O workflow `.github/workflows/release.yml` deve permanecer restrito a build, testes e deploy da PWA.

## Documentação

- `docs/architecture`: arquitetura, contratos e capacidades web
- `docs/product`: comportamento funcional, telas e branding
- `docs/qa`: regressão, pendências e evidências
- `docs/release`: CI/CD e fluxo de publicação
- `docs/ai`: regras para agentes e operação assistida
- `docs/archive`: materiais históricos que não são fonte atual da verdade

## Regra de manutenção

Documentação funcional deve refletir o comportamento atual do código. Conteúdo antigo ou divergente deve ser corrigido ou movido para `docs/archive`.

## Status

Aplicação web funcional em manutenção e evolução.
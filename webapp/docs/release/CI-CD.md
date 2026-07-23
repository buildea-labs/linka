# CI/CD

## CI

Workflow: `.github/workflows/ci.yml`.

Executa:

```bash
npm ci
npm run lint --if-present
npm test
npm run build
```

O artefato `dist/` pode ser anexado para inspecao.

## Release

Workflow: `.github/workflows/release.yml`.

Dispara em tags `v*` e executa:

```bash
npm ci
npm run lint --if-present
npm test
npm run build
```

Depois publica `dist/` no Cloudflare Pages.

## Secrets

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_PAGES_PROJECT` (opcional; default do workflow: `linka-speedtest`)

## Fora de Escopo

Este WebApp nao gera artefatos mobile. Qualquer pipeline mobile deve viver em outro repositorio/projeto.

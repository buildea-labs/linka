# CI/CD

> Consolidado em 2026-07-23 dentro do repo `linka-speedtest`. Os workflows deste diretório
> (`webapp/.github/workflows/`) NÃO executam — GitHub só lê `.github/workflows/` da raiz do
> repositório. O CI real vive em `../../.github/workflows/webapp-ci.yml`, disparado só quando
> algo em `webapp/` muda (`paths: ['webapp/**']`).

## CI

Workflow: `.github/workflows/webapp-ci.yml` (raiz do repo).

Executa, com `working-directory: webapp`:

```bash
npm ci
npm run lint --if-present
npm test
npm run build
```

O artefato `dist/` pode ser anexado para inspeção.

## Release

Não existe. O `release.yml` original (removido nesta consolidação) nunca chegou a publicar nada
em produção — tinha um bug de nome de projeto Cloudflare Pages (`linka-speedtest`, o do *outro*
app deste repo) e nunca foi corrigido. Sem deploy automático por ora; se este app for publicado
no futuro, criar um workflow novo na raiz (`paths: ['webapp/**']`, mesmo padrão do
`webapp-ci.yml`) com um projeto Cloudflare Pages próprio — nunca reusar o do speedtest.

## Fora de Escopo

Este WebApp não gera artefatos mobile. Qualquer pipeline mobile deve viver em outro repositório/projeto.

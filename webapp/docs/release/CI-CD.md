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

**Ainda não conectado.** O `release.yml` original tinha um bug: o nome default do projeto
Cloudflare Pages estava configurado como `linka-speedtest` — o projeto do *outro* app deste
repo. Conectar sem corrigir isso sobrescreveria o Pages de produção do speedtest. Precisa do
nome real do projeto Pages do webapp (ou confirmação de que nunca chegou a ser criado) antes de
ligar o deploy automático.

## Secrets (quando o release for conectado)

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_PAGES_PROJECT` (nome do projeto Pages específico do webapp — NÃO reusar o do speedtest)

## Fora de Escopo

Este WebApp não gera artefatos mobile. Qualquer pipeline mobile deve viver em outro repositório/projeto.

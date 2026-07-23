# CLAUDE.md - Linka WebApp

Repositorio standalone do Linka WebApp, um PWA React/TypeScript para speedtest e diagnostico de conexao.

## Contrato Principal

Este projeto e PWA puro. Nao adicionar Android, Capacitor, APK, Gradle, keystore, plugins nativos ou scripts de empacotamento mobile aqui.

Quando uma capacidade depender de API nativa, o WebApp deve:

- detectar a indisponibilidade no navegador;
- mostrar fallback claro;
- nao prometer medicao nativa real;
- manter a experiencia sem erro no console.

## Comandos

```bash
npm run dev
npm run lint
npm test
npm run build
npm run preview
```

## Scripts

Todos os scripts do projeto ficam em `scripts/`.

- `scripts/qa`: validacao, screenshots, evidencias e regressao.
- `scripts/release`: apoio a release/deploy.
- `scripts/tooling`: manutencao local.

Nao criar `.bat`, `.ps1`, `.mjs` ou qualquer automacao operacional na raiz.
Nao manter scripts desatualizados.

## Documentacao

Atualize docs junto com mudancas relevantes:

- `docs/architecture` para estrutura, contratos e decisoes tecnicas.
- `docs/product` para comportamento funcional, telas e copy.
- `docs/qa` para regressao e evidencias.
- `docs/release` para CI/CD e deploy.
- `docs/ai` para orientacao de agentes e skills.

`docs/archive` e historico, nao fonte canonica.

## Qualidade

Antes de encerrar trabalho de codigo:

```bash
npm run lint
npm test
npm run build
```

Reporte qualquer comando nao executado ou falho.

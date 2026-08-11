# Guia de Organizacao de Pastas

## Raiz

```txt
C:\Projetos\Linka WebApp\
  .claude\commands\       comandos auxiliares de IA do WebApp
  .github\workflows\      CI e release PWA
  docs\                   documentacao viva e arquivo historico
  public\                 assets publicos do PWA
  scripts\                unica pasta de automacoes
  src\                    aplicacao React/TypeScript
```

## Codigo

```txt
src/
  components/     componentes reutilizaveis
  core/           regras de dominio puras
  features/       dominios de produto com UI e servicos proprios
  hooks/          hooks React compartilhados
  platform/       capacidades do runtime web
  screens/        telas principais
  types/          tipos globais
  utils/          utilitarios e orquestradores
  __tests__/      testes unitarios e de contrato
```

## Scripts

Todos os scripts ficam em `scripts/`.

```txt
scripts/
  qa/        validacao, regressao visual, screenshots e evidencias
  release/   automacoes auxiliares de release/deploy PWA
  tooling/   manutencao local
```

Nao criar scripts na raiz. Nao adicionar scripts Android, APK, Gradle, keystore ou Capacitor.

## Documentacao

```txt
docs/
  architecture/  contratos tecnicos, estrutura e capacidades web
  product/       telas, UX, branding, componentes e comportamento funcional
  qa/            pendencias, regressao e evidencias PWA
  release/       CI/CD, deploy Cloudflare Pages e fluxo Git
  ai/            regras de agentes e skills
  archive/       historico util, sem valor canonico automatico
```

Arquivos em `docs/archive` nao devem ser usados como regra atual sem validar contra o codigo.

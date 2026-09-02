Implementa o processo de release, de acordo com a Issue #150.

### Estado anterior encontrado
- Versão e build distribuídas de forma ad-hoc ou definidas manualmente em múltiplos blocos dentro do `project.yml`.
- A interface de Ajustes exibia uma formatação hardcoded de release e lendo direto de chaves brutas com fallback ("1.0 (build 1)").
- Sem processo claro documentado de TestFlight vs. App Store nem gestão de releases no GitHub.
- `RELEASE_NOTES.md` sem formato de histórico contínuo (apenas a última versão).

### Fonte canônica de versão
- O arquivo **`project.yml`** (raiz do iOS) torna-se a única fonte canônica para `MARKETING_VERSION` (ex: `1.1.0`) e `CURRENT_PROJECT_VERSION` (ex: `42`).
- A tela de Ajustes lê esses mesmos dados usando `LinkaAppVersion.displayString()`, no formato padronizado "1.1.0 (42)".

### Estratégia de build number
- O número de build (`CURRENT_PROJECT_VERSION`) é um inteiro numérico crescente que deve ser incrementado antes de gerar um novo Archive (ex: 42, 43). Múltiplas builds podem coexistir sob a mesma Marketing Version.

### Alterações em CI
- O workflow antigo (`swift-modules-ci.yml`) evoluiu para `ios-ci.yml`.
- Adicionada validação do formato de `MARKETING_VERSION` (SemVer: `MAJOR.MINOR` ou `MAJOR.MINOR.PATCH`).
- Adicionada validação para garantir que o número de build seja um inteiro (`CURRENT_PROJECT_VERSION`).
- Adicionado job para compilar o app na configuração `Release` sem assinar (Smoke test).
- Adicionada checagem para que, quando uma tag Git for empurrada (`vX.Y.Z`), ela case perfeitamente com a `MARKETING_VERSION` do `project.yml`.

### Changelog / Documentação
- O `RELEASE_NOTES.md` foi renomeado e adaptado para `CHANGELOG.md` em um padrão histórico.
- Criada a documentação operacional em `documentacao/release-process.md`.

### Fluxo de TestFlight
- Exige apenas o incremento de `CURRENT_PROJECT_VERSION` no `project.yml`.
- Pode ser feito N vezes na mesma Marketing Version.

### Fluxo de Release Pública
1. Garantir que a versão correta esteja no `project.yml` e o texto em `CHANGELOG.md`.
2. Após aprovação, gerar a Tag Git (`vMAJOR.MINOR.PATCH`) a partir do commit aprovado.
3. Criar a Release no GitHub usando essa Tag.

### Fluxo de Hotfix
- Similar a um release menor: incrementa o `PATCH` no `project.yml`, incrementa a `build`, faz gate/deploy, cria a Tag `vMAJOR.MINOR.PATCH` final, e atualiza as Release notes (CHANGELOG).

### Testes Executados
- `xcodebuild test` rodando no simulador `iPhone 17`. (Sucesso ✅)
- Testes unitários do SwiftPM, incluindo validação da nova string do `LinkaAppVersion`.

### Resultado da Build Release
- `xcodebuild build` rodou com a configuração Release (sem assinar código, via flag) finalizada com sucesso. (Sucesso ✅)

### Dependências Externas
- Não foram inseridas senhas, certificates ou provisionings. Para automatizar 100% via GitHub Actions futuramente, a equipe precisará apenas expor os certificados / Fastlane apropriados (se desejado). Por ora, foca-se na rastreabilidade, previsibilidade e consistência da fonte canônica.

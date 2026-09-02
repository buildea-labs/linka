# Processo de Release - Linka

Este documento define o processo operacional para gerar novas versões, builds e releases do aplicativo Linka.

## 1. Fonte Canônica de Versão
A versão do aplicativo (Marketing Version e Build Number) está definida no arquivo `ios/aplicativo-ios/project.yml` nas chaves:
- `MARKETING_VERSION`
- `CURRENT_PROJECT_VERSION`

O XcodeGen usa esses valores para gerar os `.xcodeproj` e injetar nos `Info.plist` de todos os targets (App e Widget). O App exibe essa versão na tela de Ajustes no formato: `Versão 1.1.0 (42)`.

## 2. Padrão de Versionamento
Adotamos o formato SemVer simplificado: `MAJOR.MINOR.PATCH` (ex: 1.1.0).
- `MAJOR`: Grandes reformulações ou novas eras do produto.
- `MINOR`: Novas funcionalidades.
- `PATCH`: Correções de bugs ou melhorias contínuas.

O Build Number (`CURRENT_PROJECT_VERSION`) é um número inteiro sempre crescente (ex: 42, 43, 44). Múltiplas builds podem ter a mesma Marketing Version. **TestFlight** recebe builds para testes, que não são necessariamente releases finais.

## 3. Como Escolher a Próxima Versão e Incrementar Build
Antes de qualquer release ou envio ao TestFlight:
1. Abra `ios/aplicativo-ios/project.yml`.
2. Se for uma nova versão pública, atualize `MARKETING_VERSION`.
3. Sempre incremente `CURRENT_PROJECT_VERSION` em +1 para qualquer nova build enviada à Apple.
4. Rode `xcodegen generate` para atualizar o projeto Xcode.

## 4. Como Preparar Notas (CHANGELOG)
1. Antes de criar a release, atualize o `ios/CHANGELOG.md`.
2. Adicione uma seção `## [v1.1.0] - AAAA-MM-DD`.
3. Documente novidades, melhorias e correções (separando notas técnicas de notas para o usuário).
4. As notas da App Store devem usar linguagem acessível, evitando jargões técnicos.

## 5. Como Gerar Build Candidata (TestFlight)
1. Crie uma PR com as atualizações de versão no `project.yml` e no `CHANGELOG.md`.
2. Após o merge, faça o build no Xcode (Archive) ou via CI para enviar para o App Store Connect.
3. TestFlight ≠ Release Pública. Você pode enviar várias builds ao TestFlight incrementando apenas o Build Number e mantendo a Marketing Version.

## 6. Como Promover a Versão e Criar Tag
Quando uma build for aprovada para envio à App Store (gate final):
1. Crie uma tag git no formato `vMAJOR.MINOR.PATCH` apontando EXATAMENTE para o commit usado na build aprovada.
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

## 7. Como Criar GitHub Release
1. Após subir a tag, vá até a aba "Releases" no GitHub.
2. Crie uma nova release selecionando a tag recém-criada (ex: `v1.1.0`).
3. O título deve ser "Linka v1.1.0".
4. Copie as mudanças correspondentes do `CHANGELOG.md`.

## 8. Hotfix
Fluxo para correção urgente em produção (ex: atual é 1.2.0):
1. Incremente o PATCH: `MARKETING_VERSION` vira `1.2.1`.
2. Incremente o Build Number.
3. Crie as release notes explicando o hotfix.
4. Envie a build e aprove internamente (gate mínimo).
5. Após o deploy na App Store, crie a tag `v1.2.1` e a GitHub Release.

# Processo de release do Linka

O build testado, o build enviado e o build que aparece no TestFlight precisam ser o mesmo. Um workflow iniciado, um archive local ou uma tag isolada não contam como entrega.

## Fluxo obrigatório

1. A candidata nasce numa PR. Ela altera `aplicativo-ios/project.yml` e `RELEASE_NOTES.md` juntos.
2. `MARKETING_VERSION` identifica a versão para pessoas. `CURRENT_PROJECT_VERSION` é a identidade única da build e sempre cresce. A CI rejeita uma candidata com build não crescente.
3. A PR só pode ser mesclada depois de todos os checks verdes. A main roda a mesma CI no commit de merge.
4. Depois de validar a build candidata no simulador e, quando disponível, no iPhone, Luiz autoriza explicitamente o TestFlight.
5. Depois da autorização explícita do Luiz nesta conversa, o workflow **Deploy to TestFlight** é disparado manualmente na `main` e recusa qualquer SHA que não seja a ponta atual da main.
6. A própria workflow testa esse SHA no simulador, consulta a Apple para garantir que o par versão/build ainda não existe, cria o archive e faz o upload.
7. A workflow espera a Apple processar a build. Só então registra a tag imutável `testflight/v<versao>-b<build>` no mesmo SHA e anexa uma evidência com versão, build, SHA e hash da IPA.

## O que cada estado significa

| Estado | Significado |
| --- | --- |
| PR verde | Código candidato aprovado, ainda não distribuído. |
| Merge na main | Código integrado, ainda não enviado à Apple. |
| Workflow em execução | Upload pode não ter ocorrido. |
| Evidência anexada e tag `testflight/...` | A Apple processou exatamente a build indicada. |
| Distribuição externa ou App Store | Gates separados e sempre exigem nova autorização do Luiz. |

## Preparar uma candidata

Rode `.agents/scripts/release.sh patch`, `minor`, `major` ou uma versão explícita. Ele prepara os valores localmente e não publica nada. Atualize `RELEASE_NOTES.md`, execute a suíte local, abra a PR e espere a CI.

## Proteção técnica no GitHub

O gate humano é a autorização explícita do Luiz nesta conversa; não existe aprovação paralela em outra interface.

Um ruleset para `testflight/**` bloqueia criação, atualização e exclusão dessas tags para pessoas e libera somente `github-actions[bot]`. Sem essa regra, a tag não é uma prova imutável: alguém com permissão de escrita poderia criá-la antes da Apple ou movê-la depois.

## Verificação antes de autorizar

Use estes comandos no commit candidato:

```bash
cd aplicativo-ios
xcodegen generate
xcodebuild test -project LinkaApp.xcodeproj -scheme LinkaApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipMacroValidation CODE_SIGNING_ALLOWED=NO
xcodebuild build -project LinkaApp.xcodeproj -scheme LinkaApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Release -skipMacroValidation CODE_SIGNING_ALLOWED=NO
```

O iPhone é a confirmação adicional da jornada real. Se ele não estiver conectado, isso precisa ser registrado como ausência de teste físico, nunca apresentado como se tivesse acontecido.

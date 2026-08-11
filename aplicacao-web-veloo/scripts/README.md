# Scripts

Esta e a unica pasta para scripts operacionais do Linka WebApp.

## Organizacao

```txt
scripts/
  qa/        validacao, regressao visual, screenshots e evidencias
  release/   automacoes auxiliares de build, versionamento e deploy
  tooling/   manutencao local, auditorias e utilitarios de desenvolvimento
```

## Regras

- Nao criar scripts na raiz do repositorio.
- Nao manter scripts desatualizados.
- Nao adicionar scripts Android, APK, Gradle, keystore ou Capacitor neste WebApp.
- Todo script novo deve declarar no cabecalho: objetivo, pre-requisitos e comando de execucao.
- Se um script deixar de ser chamado por `package.json`, CI ou documentacao, remova-o ou documente claramente seu uso.

## Scripts Atuais

- `qa/capture-pwa-evidence.mjs`: sobe o app em dev e captura evidencias PWA.
- `qa/capture-pwa-evidence-runner.mjs`: captura evidencias contra preview ja disponivel em `http://127.0.0.1:4173`.
- `tooling/agent-handoff.sh`: fluxo canonico de handoff por evento (board + notificacao).
- `tooling/issue-move.sh`: movimenta issue por labels de status.
- `tooling/notify.sh`: envia notificacoes opcionais para Discord/Slack via webhook.
- `tooling/agent-handoff.ps1`: versao PowerShell do handoff canonico.
- `tooling/issue-move.ps1`: versao PowerShell para mover issue por status.
- `tooling/notify.ps1`: versao PowerShell para notificacoes opcionais.

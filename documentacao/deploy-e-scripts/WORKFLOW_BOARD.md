# Workflow do Board (WebApp)

Fluxo canonico para movimentar issues e notificar squad no Linka WebApp.

## Comando principal

```bash
scripts/tooling/agent-handoff.sh <agente> <evento> <issue#> "<mensagem>" [--para <outroAgente>]
```

No Windows/PowerShell:

```powershell
.\scripts\tooling\agent-handoff.ps1 -Agent <agente> -Event <evento> -Issue <issue#> -Message "<mensagem>" [-TargetAgent <outroAgente>]
```

Eventos aceitos:

- `start`: inicia trabalho (`status:in-progress`)
- `handoff`: passa bastao para outro agente (`status:in-progress`)
- `review`: pronto para revisao (`status:waiting-review`)
- `docs`: aprovado em review, vai para docs/higiene (`status:docs-hygiene`)
- `done`: concluido (`status:done`)
- `block`: bloqueado (`status:blocked`)
- `refine`: voltar para triagem (`status:triage`)
- `ready`: pronto para desenvolvimento (`status:agent-ready`)

## Scripts de apoio

- `scripts/tooling/issue-move.sh`: aplica labels de status e agente por coluna
- `scripts/tooling/notify.sh`: envia webhook para Discord/Slack (se configurado)

## Variaveis opcionais

- `REPO`: padrao `gmmattey/linka-webapp`
- `DISCORD_WEBHOOK_URL`: webhook para Discord
- `SLACK_WEBHOOK_URL`: webhook para Slack

Se os webhooks nao estiverem definidos, o handoff continua funcionando para GitHub.

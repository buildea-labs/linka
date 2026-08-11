# Objetivo: enviar notificacoes do fluxo de handoff para Discord e Slack.
# Pre-requisitos: variaveis DISCORD_WEBHOOK_URL e/ou SLACK_WEBHOOK_URL (opcionais).
# Execucao: .\scripts\tooling\notify.ps1 -Agent <agente> -Message "<mensagem>" [-Type info|success|warning|progress] [-Target <agente>]

param(
  [Parameter(Mandatory = $true)][string]$Agent,
  [Parameter(Mandatory = $true)][string]$Message,
  [ValidateSet("info", "success", "warning", "progress")][string]$Type = "info",
  [string]$Target = ""
)

$title = "Linka WebApp :: $Agent"
if ($Target) { $title = "$title -> $Target" }

if ($env:DISCORD_WEBHOOK_URL) {
  $color = 3066993
  if ($Type -eq "success") { $color = 5763719 }
  elseif ($Type -eq "warning") { $color = 15158332 }
  elseif ($Type -eq "progress") { $color = 3447003 }
  $payload = @{
    embeds = @(@{
      title = $title
      description = $Message
      color = $color
    })
  } | ConvertTo-Json -Depth 5
  try { Invoke-RestMethod -Method Post -Uri $env:DISCORD_WEBHOOK_URL -ContentType "application/json" -Body $payload | Out-Null } catch { Write-Warning "[notify] falha ao enviar Discord: $_" }
}

if ($env:SLACK_WEBHOOK_URL) {
  $payload = @{ text = "*$title*`n$Message" } | ConvertTo-Json
  try { Invoke-RestMethod -Method Post -Uri $env:SLACK_WEBHOOK_URL -ContentType "application/json" -Body $payload | Out-Null } catch { Write-Warning "[notify] falha ao enviar Slack: $_" }
}

Write-Host "[notify] concluido (Discord/Slack opcionais)."

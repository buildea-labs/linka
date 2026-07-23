# Objetivo: fluxo canonico de handoff para board + notificacoes.
# Pre-requisitos: gh autenticado; labels de status/agent; webhooks opcionais.
# Execucao: .\scripts\tooling\agent-handoff.ps1 -Agent <agente> -Event <evento> -Issue <issue#> -Message "<mensagem>" [-TargetAgent <outro>]

param(
  [Parameter(Mandatory = $true)][string]$Agent,
  [Parameter(Mandatory = $true)][ValidateSet("start","handoff","review","docs","done","block","refine","ready")][string]$Event,
  [Parameter(Mandatory = $true)][int]$Issue,
  [Parameter(Mandatory = $true)][string]$Message,
  [string]$TargetAgent = "",
  [string]$Repo = "gmmattey/linka-webapp"
)

$type = "info"
$col = ""
switch ($Event) {
  "start"   { $col = "in-progress"; $type = "progress" }
  "handoff" { $col = "in-progress"; $type = "success" }
  "review"  { $col = "review";      $type = "success" }
  "docs"    { $col = "docs";        $type = "info" }
  "done"    { $col = "done";        $type = "success" }
  "block"   { $col = "block";       $type = "warning" }
  "refine"  { $col = "triagem";     $type = "info" }
  "ready"   { $col = "ready";       $type = "info" }
}

& "$PSScriptRoot/issue-move.ps1" -Issue $Issue -Column $col -Agent $Agent -Repo $Repo

$fullMessage = "#$Issue - $Message`nhttps://github.com/$Repo/issues/$Issue"
gh issue comment $Issue --repo $Repo --body $fullMessage *> $null
& "$PSScriptRoot/notify.ps1" -Agent $Agent -Message $fullMessage -Type $type -Target $TargetAgent

Write-Host "[agent-handoff] evento '$Event' aplicado na issue #$Issue"

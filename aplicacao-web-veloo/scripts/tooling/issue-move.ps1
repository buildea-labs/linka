# Objetivo: mover issue no fluxo do board via labels no GitHub.
# Pre-requisitos: gh autenticado e permissao no repo.
# Execucao: .\scripts\tooling\issue-move.ps1 -Issue <issue#> -Column <coluna> [-Agent <agente>] [-Repo <owner/repo>]

param(
  [Parameter(Mandatory = $true)][int]$Issue,
  [Parameter(Mandatory = $true)][string]$Column,
  [string]$Agent = "",
  [string]$Repo = "gmmattey/linka-webapp"
)

$map = @{
  "ready" = "status:agent-ready"
  "in-progress" = "status:in-progress"
  "wip" = "status:in-progress"
  "doing" = "status:in-progress"
  "review" = "status:waiting-review"
  "docs" = "status:docs-hygiene"
  "done" = "status:done"
  "triagem" = "status:triage"
  "backlog" = "status:backlog"
  "block" = "status:blocked"
  "blocked" = "status:blocked"
}

if (-not $map.ContainsKey($Column)) {
  throw "coluna invalida: $Column"
}

$statusLabel = $map[$Column]
$allStatus = @(
  "status:agent-ready",
  "status:in-progress",
  "status:waiting-review",
  "status:docs-hygiene",
  "status:done",
  "status:triage",
  "status:backlog",
  "status:blocked"
)

foreach ($label in $allStatus) {
  gh issue edit $Issue --repo $Repo --remove-label $label *> $null
}

gh issue edit $Issue --repo $Repo --add-label $statusLabel *> $null
if ($Agent) {
  gh issue edit $Issue --repo $Repo --add-label "agent:$Agent" *> $null
}

Write-Host "[issue-move] #$Issue -> $statusLabel"

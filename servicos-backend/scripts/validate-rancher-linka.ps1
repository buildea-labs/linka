<#
.SYNOPSIS
  Valida prontidão do Rancher + Linka/Langfull.
#>

$ErrorActionPreference = "SilentlyContinue"

function Row($c, $ok, $d) {
    [PSCustomObject]@{
        check = $c
        status = $(if ($ok) { "OK" } else { "FAIL" })
        detail = $d
    }
}

$rows = @()

$wsl = wsl -l -v
$rows += Row "wsl_installed" ($LASTEXITCODE -eq 0) "wsl -l -v executado"

$dockerV = docker version --format "{{.Server.Version}}"
$rows += Row "docker_cli" ($LASTEXITCODE -eq 0) ($dockerV ?? "docker indisponível")

$composeV = docker compose version
$rows += Row "docker_compose" ($LASTEXITCODE -eq 0) (($composeV | Select-Object -First 1) ?? "compose indisponível")

Push-Location "E:\Projetos\Linka"
docker compose up -d
$upOk = $LASTEXITCODE -eq 0
Start-Sleep -Seconds 8
$rows += Row "compose_up_linka" $upOk "docker compose up -d"

try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:3000/api/health" -TimeoutSec 5
    $rows += Row "langfuse_health" ($r.StatusCode -eq 200) "status=$($r.StatusCode)"
} catch {
    $rows += Row "langfuse_health" $false "sem resposta"
}
Pop-Location

$rows | Format-Table -AutoSize
$fails = ($rows | Where-Object status -eq "FAIL").Count
if ($fails -eq 0) {
    Write-Host "`nRANCHER+LINKA READY" -ForegroundColor Green
    exit 0
}

Write-Host "`nRANCHER+LINKA NOT READY ($fails falhas)" -ForegroundColor Red
exit 2


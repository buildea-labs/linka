param(
    [string]$CockpitHealthUrl = "http://localhost:7474/health",
    [string]$LangfuseHealthUrl = "http://localhost:3000/api/health"
)

$ErrorActionPreference = "SilentlyContinue"

function Test-Ok($name, $ok, $detail) {
    $status = if ($ok) { "OK" } else { "FAIL" }
    [PSCustomObject]@{
        check  = $name
        status = $status
        detail = $detail
    }
}

$rows = @()

# 1) Cockpit health
$cockpitOk = $false
$cockpitDetail = "offline"
try {
    $resp = Invoke-WebRequest -Uri $CockpitHealthUrl -UseBasicParsing -TimeoutSec 3
    if ($resp.StatusCode -eq 200 -and $resp.Content -match '"status"\s*:\s*"ok"') {
        $cockpitOk = $true
        $cockpitDetail = "health endpoint respondeu ok"
    }
} catch {}
$rows += Test-Ok "cockpit_health" $cockpitOk $cockpitDetail

# 2) Telegram bot process
$botProc = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "^python.*\.exe$" -and $_.CommandLine -match "telegram-claude-bot\\bot.py"
}
$rows += Test-Ok "telegram_bot" ($botProc.Count -gt 0) ("processos ativos: " + $botProc.Count)

# 3) Session status freshness (<= 15 min)
$sessionPath = ".claude/reports/session-status.json"
$fresh = $false
$freshDetail = "arquivo ausente"
if (Test-Path $sessionPath) {
    $ageMin = ((Get-Date) - (Get-Item $sessionPath).LastWriteTime).TotalMinutes
    $fresh = $ageMin -le 15
    $freshDetail = ("idade: {0:N1} min" -f $ageMin)
}
$rows += Test-Ok "session_status_fresh" $fresh $freshDetail

# 4) Langfuse health (if docker exists)
$dockerCmd = Get-Command docker
if (-not $dockerCmd) {
    $rows += Test-Ok "docker_installed" $false "docker não encontrado"
    $rows += Test-Ok "langfuse_health" $false "não checado (sem docker)"
} else {
    $rows += Test-Ok "docker_installed" $true "docker disponível"
    $lfOk = $false
    $lfDetail = "offline"
    try {
        $lf = Invoke-WebRequest -Uri $LangfuseHealthUrl -UseBasicParsing -TimeoutSec 3
        if ($lf.StatusCode -eq 200) {
            $lfOk = $true
            $lfDetail = "health endpoint respondeu 200"
        }
    } catch {}
    $rows += Test-Ok "langfuse_health" $lfOk $lfDetail
}

# 5) Security check: token exposure in bot.log (novo e legado)
$botLogs = @(
    "E:\Projetos\cockpit\telegram-claude-bot\bot.log",
    "E:\Projetos\Linka\telegram-claude-bot\bot.log"
)
$exposed = $false
$checked = @()
foreach ($botLog in $botLogs) {
    if (Test-Path $botLog) {
        $checked += $botLog
        $sample = Get-Content $botLog -Tail 300
        if ($sample -match "bot\d+:[A-Za-z0-9_-]{20,}") {
            $exposed = $true
        }
    }
}
$detail = if ($exposed) {
    "token encontrado em log"
} elseif ($checked.Count -eq 0) {
    "nenhum bot.log encontrado"
} else {
    "sem token detectado na cauda do log"
}
$rows += Test-Ok "bot_log_secret_leak" (-not $exposed) $detail

$rows | Format-Table -AutoSize

$failCount = ($rows | Where-Object { $_.status -eq "FAIL" }).Count
if ($failCount -eq 0) {
    Write-Host "`nLANGFULL READY" -ForegroundColor Green
    exit 0
}

Write-Host "`nLANGFULL NOT READY ($failCount falhas)" -ForegroundColor Red
exit 2

# Start-Observability.ps1 - Iniciar observabilidade Linka + Langfuse (Windows)

param(
    [string]$WorkspacePath = ".",
    [string]$LangfuseHost = "http://localhost:3000"
)

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "🚀 Iniciando observabilidade Linka" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Workspace: $WorkspacePath"
Write-Host "🎯 Langfuse:  $LangfuseHost"
Write-Host ""

# Verificar Docker
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "❌ Docker não encontrado. Instale Docker Desktop." -ForegroundColor Red
    exit 1
}

# Criar estrutura de pastas
Write-Host "📁 Criando estrutura de observabilidade..." -ForegroundColor Cyan
$folders = @(
    "$WorkspacePath\.claude\events",
    "$WorkspacePath\.claude\observability",
    "$WorkspacePath\.claude\reports"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  ✓ Criado: $folder"
    }
}

# Iniciar Docker Compose
Write-Host ""
Write-Host "🐳 Iniciando containers Docker..." -ForegroundColor Cyan
Push-Location $WorkspacePath

try {
    & docker-compose up -d 2>$null
    if ($LASTEXITCODE -ne 0) {
        & docker compose up -d
    }
    Write-Host "✅ Docker compose iniciado" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao iniciar docker-compose: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

# Aguardar Langfuse
Write-Host ""
Write-Host "⏳ Aguardando Langfuse..." -ForegroundColor Cyan
$maxAttempts = 30
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "$LangfuseHost/api/health" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        # Continua tentando
    }

    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
    $attempt++
}

if (-not $ready) {
    Write-Host ""
    Write-Host "❌ Langfuse não respondeu após 30s" -ForegroundColor Red
    Write-Host "   Verifique: docker ps"
    Write-Host "   Logs: docker-compose logs langfuse"
    exit 1
}

Write-Host ""
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "✨ Observabilidade iniciada!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Dashboard Langfuse:" -ForegroundColor Yellow
Write-Host "   $LangfuseHost"
Write-Host ""
Write-Host "📝 Eventos:" -ForegroundColor Yellow
Write-Host "   $WorkspacePath\.claude\events\agent-events.jsonl"
Write-Host ""
Write-Host "📊 Relatórios:" -ForegroundColor Yellow
Write-Host "   $WorkspacePath\.claude\reports\"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "  1. Abra $LangfuseHost no navegador"
Write-Host "  2. Use o workflow normalmente"
Write-Host "  3. Eventos serão registrados em tempo real"
Write-Host ""
Write-Host "Para parar:" -ForegroundColor Gray
Write-Host "  docker-compose down"
Write-Host ""

<#
.SYNOPSIS
  Migra stack local para Rancher Desktop com foco em storage no drive E:.
  Requer PowerShell como Administrador.
#>

[CmdletBinding()]
param(
    [string]$BaseDir = "E:\Rancher",
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Execute este script em PowerShell como Administrador."
    }
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

Assert-Admin
Write-Host "== Rancher migration (E:) ==" -ForegroundColor Cyan

Ensure-Dir $BaseDir
Ensure-Dir "$BaseDir\wsl"
Ensure-Dir "$BaseDir\cache"

Write-Host "1) Habilitando WSL + VirtualMachinePlatform..." -ForegroundColor Yellow
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Host
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Host

Write-Host "2) Instalando runtime WSL..." -ForegroundColor Yellow
wsl --install --no-distribution | Out-Host
wsl --set-default-version 2 | Out-Host

if (-not $SkipInstall) {
    Write-Host "3) Instalando Rancher Desktop via winget..." -ForegroundColor Yellow
    winget install -e --id SUSE.RancherDesktop --accept-package-agreements --accept-source-agreements | Out-Host
} else {
    Write-Host "3) Skip install habilitado." -ForegroundColor DarkYellow
}

Write-Host "4) Encerrando WSL para preparação..." -ForegroundColor Yellow
wsl --shutdown

Write-Host ""
Write-Host "Próximo passo manual obrigatório:" -ForegroundColor Green
Write-Host "  A) Abra Rancher Desktop e finalize setup inicial (dockerd + Kubernetes OFF)." -ForegroundColor Gray
Write-Host "  B) Feche Rancher Desktop completamente." -ForegroundColor Gray
Write-Host ""
Write-Host "Depois rode este comando (Admin) para mover distros para E::" -ForegroundColor Green
Write-Host ""
Write-Host "  .\scripts\move-rancher-wsl-to-e.ps1 -BaseDir '$BaseDir'" -ForegroundColor White
Write-Host ""


<#
.SYNOPSIS
  Move distros WSL do Rancher Desktop para E:\Rancher\wsl.
  Requer Rancher Desktop já aberto 1x e depois fechado.
  Requer PowerShell como Administrador.
#>

[CmdletBinding()]
param(
    [string]$BaseDir = "E:\Rancher"
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Execute este script em PowerShell como Administrador."
    }
}

function Move-Distro([string]$Name, [string]$TargetDir) {
    if (-not (wsl -l -q | Select-String -SimpleMatch $Name)) {
        Write-Host "Distro '$Name' não encontrada. Pulando." -ForegroundColor DarkYellow
        return
    }
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    $tar = Join-Path $BaseDir "$Name.tar"

    Write-Host "Exportando $Name..." -ForegroundColor Yellow
    wsl --export $Name $tar | Out-Host

    Write-Host "Unregister $Name..." -ForegroundColor Yellow
    wsl --unregister $Name | Out-Host

    Write-Host "Importando $Name para $TargetDir..." -ForegroundColor Yellow
    wsl --import $Name $TargetDir $tar --version 2 | Out-Host

    Remove-Item $tar -Force -ErrorAction SilentlyContinue
}

Assert-Admin
wsl --shutdown

Move-Distro -Name "rancher-desktop" -TargetDir (Join-Path $BaseDir "wsl\rancher-desktop")
Move-Distro -Name "rancher-desktop-data" -TargetDir (Join-Path $BaseDir "wsl\rancher-desktop-data")

Write-Host ""
Write-Host "Concluído. Abra o Rancher Desktop e valide:" -ForegroundColor Green
Write-Host "  wsl -l -v" -ForegroundColor White
Write-Host "  docker info" -ForegroundColor White


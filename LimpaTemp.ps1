# LimpaTemp.ps1
# Limpa arquivos temporarios do Windows, incluindo a pasta Prefetch.
# Recomendo executar como Administrador para limpar C:\Windows\Temp e C:\Windows\Prefetch.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Continue'

if ($WhatIfOnly) {
    $WhatIfPreference = $true
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Clear-FolderContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$Name = $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "[IGNORADO] $Name nao existe: $Path" -ForegroundColor Yellow
        return
    }

    Write-Host "`n[LIMPANDO] $Name" -ForegroundColor Cyan
    Write-Host "Caminho: $Path"

    $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $items) {
        Write-Host "Nada para remover." -ForegroundColor DarkGray
        return
    }

    $removed = 0
    $failed = 0

    foreach ($item in $items) {
        try {
            if ($PSCmdlet.ShouldProcess($item.FullName, 'Remover')) {
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
            }
            $removed++
        }
        catch {
            $failed++
            Write-Host "[EM USO/BLOQUEADO] $($item.FullName)" -ForegroundColor DarkYellow
        }
    }

    Write-Host "Concluido: removidos $removed item(ns), falharam $failed item(ns)." -ForegroundColor Green
}

Write-Host '=== Limpeza de arquivos temporarios do Windows ===' -ForegroundColor Green

$isAdmin = Test-IsAdministrator
if (-not $isAdmin) {
    Write-Host 'Aviso: execute como Administrador para limpar todas as pastas do Windows.' -ForegroundColor Yellow
}

$folders = @(
    [pscustomobject]@{ Name = 'TEMP do usuario'; Path = $env:TEMP; RequiresAdmin = $false },
    [pscustomobject]@{ Name = 'TMP do usuario'; Path = $env:TMP; RequiresAdmin = $false },
    [pscustomobject]@{ Name = 'Temp local do usuario'; Path = Join-Path $env:LOCALAPPDATA 'Temp'; RequiresAdmin = $false },
    [pscustomobject]@{ Name = 'Windows Temp'; Path = Join-Path $env:WINDIR 'Temp'; RequiresAdmin = $true },
    [pscustomobject]@{ Name = 'Windows Prefetch'; Path = Join-Path $env:WINDIR 'Prefetch'; RequiresAdmin = $true }
)

foreach ($folder in $folders) {
    if ($folder.RequiresAdmin -and -not $isAdmin) {
        Write-Host "`n[IGNORADO] $($folder.Name): requer execucao como Administrador." -ForegroundColor Yellow
        continue
    }

    Clear-FolderContent -Path $folder.Path -Name $folder.Name
}

Write-Host "`nLimpeza finalizada." -ForegroundColor Green
Write-Host 'Dica: para simular sem apagar, execute com: .\LimpaTemp.ps1 -WhatIfOnly' -ForegroundColor DarkGray
